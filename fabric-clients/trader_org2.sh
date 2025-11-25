#!/usr/bin/env bash
set -euo pipefail

ROUNDS="${ROUNDS:-5}"
WINDOW_SEC="${WINDOW_SEC:-10}"
SLEEP_MS_MAX="${SLEEP_MS_MAX:-50}"
TESTNET_DIR="${TESTNET_DIR:-$HOME/fabric-samples/test-network}"
CHANNEL="${CHANNEL:-mychannel}"
CC="${CC:-secured}"
ORG1_CSV="${ORG1_CSV:-$TESTNET_DIR/assets_created_org1.csv}"
ORG2_CSV="${ORG2_CSV:-$TESTNET_DIR/assets_created_org2.csv}"

cd "$TESTNET_DIR"

# ---- Org2 env
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"
export CORE_PEER_ADDRESS="localhost:9051"
export ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
ORDERER="localhost:7050"
ORDERER_HOST="orderer.example.com"

jq -V >/dev/null 2>&1 || { echo "[Org2] Please install jq"; exit 1; }

b64(){ echo -n "$1" | base64 -w0; }
now_window(){ python3 - <<PY
import time; print(int(time.time())//${WINDOW_SEC})
PY
}
trade_params(){  # arg: asset_id
python3 - "$1" "$(now_window)" <<'PY'
import hashlib, sys
if len(sys.argv) < 3:
    raise SystemExit(1)
asset = sys.argv[1]
window = sys.argv[2]
h = hashlib.sha256((asset + ":" + window).encode()).hexdigest()
price = (int(h[:2],16) % 71) + 80
print(h, price)
PY
}

declare -A COLOR SIZE SALT DESC
while IFS=, read -r org id color size salt desc; do
  [[ "$id" == "asset_id" || -z "$id" ]] && continue
  desc="${desc%\"}"; desc="${desc#\"}"
  COLOR["$id"]="$color"; SIZE["$id"]="$size"; SALT["$id"]="$salt"; DESC["$id"]="$desc"
done < <( (tail -n +2 "$ORG1_CSV"; tail -n +2 "$ORG2_CSV") )

ASSET_IDS=("${!COLOR[@]}")
[[ ${#ASSET_IDS[@]} -gt 0 ]] || { echo "[Org2] No assets in CSVs"; exit 1; }

read_asset(){ peer chaincode query -C "$CHANNEL" -n "$CC" -c "{\"function\":\"ReadAsset\",\"Args\":[\"$1\"]}"; }

seller_flow(){
  local asset="$1"
  local desc="${DESC[$asset]}"
  local tid price
  if ! read -r tid price < <(trade_params "$asset"); then
    echo "[Org2 SELL] retry-later asset=$asset"
    return 9
  fi
  [[ -n "$tid" && -n "$price" ]] || { echo "[Org2 SELL] retry-later asset=$asset"; return 9; }
  local price_b64
  price_b64=$(b64 "{\"asset_id\":\"$asset\",\"trade_id\":\"$tid\",\"price\":$price}")
  local buyer="Org1MSP"

  peer chaincode invoke -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
    --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
    -c "{\"function\":\"AgreeToSell\",\"Args\":[\"$asset\",\"$buyer\"]}" \
    --transient "{\"asset_price\":\"$price_b64\"}" \
    --waitForEvent >/dev/null 2>&1 || return 1

  peer chaincode invoke -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
    --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
    -c "{\"function\":\"TransferAsset\",\"Args\":[\"$asset\",\"$buyer\"]}" \
    --transient "{\"asset_price\":\"$price_b64\"}" \
    --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" \
    --waitForEvent >/dev/null 2>&1 || return 2

  echo "[Org2 SELL] OK  asset=$asset  price=$price  trade_id=$tid  desc=\"$desc\""
  return 0
}

buyer_flow(){
  local asset="$1"
  local color="${COLOR[$asset]}" size="${SIZE[$asset]}" salt="${SALT[$asset]}"
  local desc="${DESC[$asset]}"
  local props_b64
  props_b64=$(b64 "{\"object_type\":\"asset_properties\",\"color\":\"$color\",\"size\":$size,\"salt\":\"$salt\"}")
  local tid price
  if ! read -r tid price < <(trade_params "$asset"); then
    echo "[Org2 BUY ] retry-later asset=$asset"
    return 9
  fi
  [[ -n "$tid" && -n "$price" ]] || { echo "[Org2 BUY ] retry-later asset=$asset"; return 9; }
  local price_b64
  price_b64=$(b64 "{\"asset_id\":\"$asset\",\"trade_id\":\"$tid\",\"price\":$price}")

  vout=$(peer chaincode query -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
          --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
          -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$asset\"]}" \
          --transient "{\"asset_properties\":\"$props_b64\"}" 2>&1) || return 3
  [[ "$vout" == "true" ]] || return 4

  peer chaincode invoke -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
    --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
    -c "{\"function\":\"AgreeToBuy\",\"Args\":[\"$asset\"]}" \
    --transient "{\"asset_price\":\"$price_b64\", \"asset_properties\":\"$props_b64\"}" \
    --waitForEvent >/dev/null 2>&1 || return 5

  echo "[Org2 BUY ] OK  asset=$asset  price=$price  trade_id=$tid  desc=\"$desc\""
  return 0
}

for ((i=1;i<=ROUNDS;i++)); do
  asset="${ASSET_IDS[$((RANDOM % ${#ASSET_IDS[@]}))]}"
  json="$(read_asset "$asset" 2>/dev/null || true)"
  owner="$(echo "$json" | jq -r '.ownerOrg // empty')"
  [[ -z "$owner" ]] && continue

  if [[ "$owner" == "Org2MSP" ]]; then
    seller_flow "$asset" || echo "[Org2 SELL] retry-later asset=$asset"
  else
    buyer_flow "$asset"  || echo "[Org2 BUY ] retry-later asset=$asset"
  fi

  if [[ "$SLEEP_MS_MAX" -gt 0 ]]; then
    python3 - <<PY 2>/dev/null || true
import time,random; time.sleep(random.randint(0,${SLEEP_MS_MAX})/1000)
PY
  fi
done

echo "[Org2] Done rounds=$ROUNDS"
