#!/usr/bin/env bash
set -euo pipefail

# =========================================
# trade_rounds.sh
# =========================================

ROUNDS="${ROUNDS:-10}" # how many trades
TESTNET_DIR="${TESTNET_DIR:-$HOME/fabric-samples/test-network}"
CHANNEL="${CHANNEL:-mychannel}"
CC="${CC:-secured}"
ORDERER="localhost:7050"
ORDERER_HOST="orderer.example.com"


ORG1_CSV="${ORG1_CSV:-$TESTNET_DIR/assets_created_org1.csv}"
ORG2_CSV="${ORG2_CSV:-$TESTNET_DIR/assets_created_org2.csv}"

OUT_LOG="${OUT_LOG:-trades_rounds.log}"
OUT_CSV="${OUT_CSV:-trades_rounds.csv}"               

COLORS=(blue red green yellow black white orange purple) 

b64()  { echo -n "$1" | base64 -w0; }
log()  { echo -e "\033[1;36m[trade]\033[0m $*"; }
fail() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

jq_bin="$(command -v jq || true)"
[[ -n "$jq_bin" ]] || fail "jq is required (sudo apt-get install jq)"

cd "$TESTNET_DIR" || fail "Cannot cd to $TESTNET_DIR"

ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
[[ -f "$ORDERER_CA" ]] || fail "Missing ORDERER_CA"

# ---- Org env helpers ----
set_org1() {
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
  export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
  export CORE_PEER_ADDRESS="localhost:7051"
  export ORDERER_CA
}
set_org2() {
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
  export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"
  export CORE_PEER_ADDRESS="localhost:9051"
  export ORDERER_CA
}

# ---- Read asset helper (returns JSON) ----
read_asset() {
  local id="$1"
  peer chaincode query -C "$CHANNEL" -n "$CC" -c "{\"function\":\"ReadAsset\",\"Args\":[\"$id\"]}"
}

# Build ID -> props map from CSVs (color,size,salt,desc)
# CSV columns: org,asset_id,color,size,salt,public_desc
declare -A PROPS_COLOR PROPS_SIZE PROPS_SALT DESC_BY_ID
while IFS=, read -r org id color size salt desc; do
  [[ "$id" == "asset_id" || -z "$id" ]] && continue
  # strip quotes around desc if present
  desc="${desc%\"}"; desc="${desc#\"}"
  PROPS_COLOR["$id"]="$color"
  PROPS_SIZE["$id"]="$size"
  PROPS_SALT["$id"]="$salt"
  DESC_BY_ID["$id"]="$desc"
done < <( (tail -n +2 "$ORG1_CSV"; tail -n +2 "$ORG2_CSV") )

# All candidate asset IDs
ALL_IDS=()
while IFS=, read -r org id _; do
  [[ "$id" == "asset_id" || -z "$id" ]] && continue
  ALL_IDS+=("$id")
done < <( (tail -n +2 "$ORG1_CSV"; tail -n +2 "$ORG2_CSV") )

[[ ${#ALL_IDS[@]} -gt 0 ]] || fail "No asset IDs found in CSVs."

# Output headers
echo "round,asset_id,desc,buyerOrg,sellerOrg,price,trade_id,result" > "$OUT_CSV"
: > "$OUT_LOG"

log "Starting $ROUNDS random trades…"
for ((r=1; r<=ROUNDS; r++)); do
  # Pick a random asset
  asset_id="${ALL_IDS[$((RANDOM % ${#ALL_IDS[@]}))]}"

  # Read current owner & desc
  set_org1
  resp="$(read_asset "$asset_id")" || { echo "$resp" >>"$OUT_LOG"; fail "ReadAsset failed"; }
  owner="$(echo "$resp" | jq -r '.ownerOrg')"
  desc="$(echo  "$resp" | jq -r '.publicDescription')"

  [[ -n "$owner" && "$owner" != "null" ]] || { echo "$resp" >>"$OUT_LOG"; fail "Could not parse owner"; }

  # Decide who sells:
  # 50/50 chance to keep current owner as seller; otherwise flip (but only seller can transfer, so we’ll ensure seller==owner)
  if (( RANDOM % 2 )); then
    seller="$owner"
  else
    # flip would break transfer rule; keep owner as seller to satisfy "only owner can transfer"
    seller="$owner"
  fi
  buyer=$([[ "$seller" == "Org1MSP" ]] && echo "Org2MSP" || echo "Org1MSP")

  # Random price (90..150) and random trade_id
  price=$(( (RANDOM % 61) + 90 ))
  trade_id="$(openssl rand -hex 20 2>/dev/null || echo $RANDOM$RANDOM$RANDOM)"

  # Prepare properties (must match original)
  color="${PROPS_COLOR[$asset_id]}"
  size="${PROPS_SIZE[$asset_id]}"
  salt="${PROPS_SALT[$asset_id]}"
  [[ -n "${color:-}" && -n "${size:-}" && -n "${salt:-}" ]] || {
    echo "[warn] Missing props for $asset_id in CSV; skipping round $r" | tee -a "$OUT_LOG"
    echo "$r,$asset_id,\"$desc\",$buyer,$seller,$price,$trade_id,skip_no_props" >> "$OUT_CSV"
    continue
  }
  props_b64="$(b64 "{\"object_type\":\"asset_properties\",\"color\":\"$color\",\"size\":$size,\"salt\":\"$salt\"}")"
  price_b64="$(b64 "{\"asset_id\":\"$asset_id\",\"trade_id\":\"$trade_id\",\"price\":$price}")"

  echo "---- Round $r ----"           | tee -a "$OUT_LOG"
  echo "Asset: $asset_id"             | tee -a "$OUT_LOG"
  echo "Desc : $desc"                 | tee -a "$OUT_LOG"
  echo "Seller=$seller  Buyer=$buyer  Price=$price  TradeID=$trade_id" | tee -a "$OUT_LOG"

  # BUYER: Verify props + AgreeToBuy
  if [[ "$buyer" == "Org1MSP" ]]; then set_org1; else set_org2; fi

  set +e
  vout=$(peer chaincode query -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
          --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
          -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$asset_id\"]}" \
          --transient "{\"asset_properties\":\"$props_b64\"}" 2>&1)
  vrc=$?
  set -e
  echo "[buyer:$buyer] Verify -> $vout" | tee -a "$OUT_LOG"
  [[ $vrc -eq 0 && "$vout" == "true" ]] || {
    echo "$r,$asset_id,\"$desc\",$buyer,$seller,$price,$trade_id,verify_failed" >> "$OUT_CSV"
    echo "[round $r] verify failed; skipping" | tee -a "$OUT_LOG"
    continue
  }

  set +e
  bout=$(peer chaincode invoke -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
          --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
          -c "{\"function\":\"AgreeToBuy\",\"Args\":[\"$asset_id\"]}" \
          --transient "{\"asset_price\":\"$price_b64\", \"asset_properties\":\"$props_b64\"}" \
          --waitForEvent 2>&1)
  brc=$?
  set -e
  echo "[buyer:$buyer] AgreeToBuy -> rc=$brc" | tee -a "$OUT_LOG"
  [[ $brc -eq 0 ]] || {
    echo "$r,$asset_id,\"$desc\",$buyer,$seller,$price,$trade_id,agree_to_buy_failed" >> "$OUT_CSV"
    echo "$bout" >> "$OUT_LOG"
    continue
  }

  # SELLER: AgreeToSell (with buyer org) + TransferAsset
  if [[ "$seller" == "Org1MSP" ]]; then set_org1; else set_org2; fi

  set +e
  sout=$(peer chaincode invoke -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
          --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
          -c "{\"function\":\"AgreeToSell\",\"Args\":[\"$asset_id\",\"$buyer\"]}" \
          --transient "{\"asset_price\":\"$price_b64\"}" \
          --waitForEvent 2>&1)
  src=$?
  set -e
  echo "[seller:$seller] AgreeToSell -> rc=$src" | tee -a "$OUT_LOG"
  [[ $src -eq 0 ]] || {
    echo "$r,$asset_id,\"$desc\",$buyer,$seller,$price,$trade_id,agree_to_sell_failed" >> "$OUT_CSV"
    echo "$sout" >> "$OUT_LOG"
    continue
  }

  # Transfer (include both peers so both endorse; mirror your earlier successful call)
  peer1_cert="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
  peer2_cert="${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

  set +e
  tout=$(peer chaincode invoke -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
          --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
          -c "{\"function\":\"TransferAsset\",\"Args\":[\"$asset_id\",\"$buyer\"]}" \
          --transient "{\"asset_price\":\"$price_b64\"}" \
          --peerAddresses localhost:7051 --tlsRootCertFiles "$peer1_cert" \
          --peerAddresses localhost:9051 --tlsRootCertFiles "$peer2_cert" \
          --waitForEvent 2>&1)
  trc=$?
  set -e
  echo "[seller:$seller] TransferAsset -> rc=$trc" | tee -a "$OUT_LOG"
  if [[ $trc -eq 0 ]]; then
    echo "$r,$asset_id,\"$desc\",$buyer,$seller,$price,$trade_id,transferred" >> "$OUT_CSV"
  else
    echo "$r,$asset_id,\"$desc\",$buyer,$seller,$price,$trade_id,transfer_failed" >> "$OUT_CSV"
    echo "$tout" >> "$OUT_LOG"
  fi
done

log "Rounds complete."
log "Structured CSV: $OUT_CSV"
log "Details log   : $OUT_LOG"
