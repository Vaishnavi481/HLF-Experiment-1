#!/usr/bin/env bash
set -euo pipefail

# Concurrent trader for Org1MSP.
# It alternates between acting as BUYER (for Org2-owned assets) and SELLER (for Org1-owned assets).
# Matching with the other client is achieved by deriving trade_id and price deterministically
# from asset_id + current time window.

ROUNDS="${ROUNDS:-5}"                         # iterations
WINDOW_SEC="${WINDOW_SEC:-10}"                 # time bucket for coordination (both sides must use same)
SLEEP_MS_MAX="${SLEEP_MS_MAX:-50}"           # jitter between ops to simulate concurrency
TESTNET_DIR="${TESTNET_DIR:-$HOME/fabric-samples/test-network}"
CHANNEL="${CHANNEL:-mychannel}"
CC="${CC:-secured}"
ORG1_CSV="${ORG1_CSV:-$TESTNET_DIR/assets_created_org1.csv}"
ORG2_CSV="${ORG2_CSV:-$TESTNET_DIR/assets_created_org2.csv}"

cd "$TESTNET_DIR"

# ---- Org1 env
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
export CORE_PEER_ADDRESS="localhost:7051"
export ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
ORDERER="localhost:7050"
ORDERER_HOST="orderer.example.com"

jq -V >/dev/null 2>&1 || { echo "[Org1] Please install jq"; exit 1; }

b64(){ echo -n "$1" | base64 -w0; }
now_window(){ python3 - <<PY
import time; print(int(time.time())//${WINDOW_SEC})
PY
}
# Deterministic trade_id & price for given asset + window
trade_params(){  # arg: asset_id
python3 - "$1" "$(now_window)" <<'PY'
import hashlib, sys
if len(sys.argv) < 3:
    raise SystemExit(1)
asset = sys.argv[1]
window = sys.argv[2]
h = hashlib.sha256((asset + ":" + window).encode()).hexdigest()
price = (int(h[:2],16) % 71) + 80  # 80..150
print(h, price)
PY
}

# Load props map from CSVs: id->(color,size,salt,desc)
declare -A COLOR SIZE SALT DESC
while IFS=, read -r org id color size salt desc; do
  [[ "$id" == "asset_id" || -z "$id" ]] && continue
  desc="${desc%\"}"; desc="${desc#\"}"
  COLOR["$id"]="$color"; SIZE["$id"]="$size"; SALT["$id"]="$salt"; DESC["$id"]="$desc"
done < <( (tail -n +2 "$ORG1_CSV"; tail -n +2 "$ORG2_CSV") )

ASSET_IDS=("${!COLOR[@]}")
[[ ${#ASSET_IDS[@]} -gt 0 ]] || { echo "[Org1] No assets in CSVs"; exit 1; }

read_asset(){ peer chaincode query -C "$CHANNEL" -n "$CC" -c "{\"function\":\"ReadAsset\",\"Args\":[\"$1\"]}"; }

# SELLER side actions (Org1 == owner)
seller_flow(){
  local asset="$1"
  local desc="${DESC[$asset]}"
  local tid price
  if ! read -r tid price < <(trade_params "$asset"); then
    echo "[Org1 SELL] retry-later asset=$asset"
    return 9
  fi
  [[ -n "$tid" && -n "$price" ]] || { echo "[Org1 SELL] retry-later asset=$asset"; return 9; }
  local price_b64
  price_b64=$(b64 "{\"asset_id\":\"$asset\",\"trade_id\":\"$tid\",\"price\":$price}")
  local buyer="Org2MSP"

  # AgreeToSell
  peer chaincode invoke -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
    --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
    -c "{\"function\":\"AgreeToSell\",\"Args\":[\"$asset\",\"$buyer\"]}" \
    --transient "{\"asset_price\":\"$price_b64\"}" \
    --waitForEvent >/dev/null 2>&1 || return 1

  # TransferAsset with both peers’ endorsements
  peer chaincode invoke -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
    --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
    -c "{\"function\":\"TransferAsset\",\"Args\":[\"$asset\",\"$buyer\"]}" \
    --transient "{\"asset_price\":\"$price_b64\"}" \
    --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" \
    --waitForEvent >/dev/null 2>&1 || return 2

  echo "[Org1 SELL] OK  asset=$asset  price=$price  trade_id=$tid  desc=\"$desc\""
  return 0
}

# BUYER side actions (Org1 buys from Org2)
buyer_flow(){
  local asset="$1"
  local color="${COLOR[$asset]}" size="${SIZE[$asset]}" salt="${SALT[$asset]}"
  local desc="${DESC[$asset]}"
  local props_b64
  props_b64=$(b64 "{\"object_type\":\"asset_properties\",\"color\":\"$color\",\"size\":$size,\"salt\":\"$salt\"}")
  local tid price
  if ! read -r tid price < <(trade_params "$asset"); then
    echo "[Org1 BUY ] retry-later asset=$asset"
    return 9
  fi
  [[ -n "$tid" && -n "$price" ]] || { echo "[Org1 BUY ] retry-later asset=$asset"; return 9; }
  local price_b64
  price_b64=$(b64 "{\"asset_id\":\"$asset\",\"trade_id\":\"$tid\",\"price\":$price}")

  # Verify
  vout=$(peer chaincode query -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
          --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
          -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$asset\"]}" \
          --transient "{\"asset_properties\":\"$props_b64\"}" 2>&1) || return 3
  [[ "$vout" == "true" ]] || return 4

  # AgreeToBuy
  peer chaincode invoke -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
    --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
    -c "{\"function\":\"AgreeToBuy\",\"Args\":[\"$asset\"]}" \
    --transient "{\"asset_price\":\"$price_b64\", \"asset_properties\":\"$props_b64\"}" \
    --waitForEvent >/dev/null 2>&1 || return 5

  echo "[Org1 BUY ] OK  asset=$asset  price=$price  trade_id=$tid  desc=\"$desc\""
  return 0
}

for ((i=1;i<=ROUNDS;i++)); do
  asset="${ASSET_IDS[$((RANDOM % ${#ASSET_IDS[@]}))]}"
  json="$(read_asset "$asset" 2>/dev/null || true)"
  owner="$(echo "$json" | jq -r '.ownerOrg // empty')"
  [[ -z "$owner" ]] && continue

  if [[ "$owner" == "Org1MSP" ]]; then
    seller_flow "$asset" || echo "[Org1 SELL] retry-later asset=$asset"
  else
    buyer_flow "$asset"  || echo "[Org1 BUY ] retry-later asset=$asset"
  fi

  # jitter
  if [[ "$SLEEP_MS_MAX" -gt 0 ]]; then
    python3 - <<PY 2>/dev/null || true
import time,random; time.sleep(random.randint(0,${SLEEP_MS_MAX})/1000)
PY
  fi
done

echo "[Org1] Done rounds=$ROUNDS"
