#!/usr/bin/env bash
set -euo pipefail

# Usage: N=11 ./org1_creator.sh

N="${N:-10}"                                 # how many to create (default 10)
TESTNET_DIR="${TESTNET_DIR:-$HOME/fabric-samples/test-network}"
CHANNEL="${CHANNEL:-mychannel}"
CC="${CC:-secured}"
ORDERER="localhost:7050"
ORDERER_HOST="orderer.example.com"
OUT_CSV="${OUT_CSV:-assets_created_org1.csv}"
SLEEP_MAX_MS="${SLEEP_MAX_MS:-500}"          # random jitter between invokes (0..SLEEP_MAX_MS)

COLORS=(blue red green yellow black white orange purple)

log()  { echo -e "\033[1;32m[Org1]\033[0m $*"; }
fail() { echo -e "\033[1;31m[Org1][ERROR]\033[0m $*" >&2; exit 1; }
b64()  { echo -n "$1" | base64 -w0; }

cd "$TESTNET_DIR" || fail "Cannot cd to $TESTNET_DIR"
ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
[[ -f "$ORDERER_CA" ]] || fail "Missing ORDERER_CA"

# Org1 env
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
export CORE_PEER_ADDRESS="localhost:7051"
export ORDERER_CA

[[ -d "$CORE_PEER_MSPCONFIGPATH" ]] || fail "MSP path missing"
[[ -f "$CORE_PEER_TLS_ROOTCERT_FILE" ]] || fail "TLS root cert missing"

echo "org,asset_id,color,size,salt,public_desc" > "$OUT_CSV"

for i in $(seq 1 "$N"); do
  color="${COLORS[$((RANDOM % ${#COLORS[@]}))]}"
  size=$(( (RANDOM % 46) + 5 ))    # 5..50
  salt="$(openssl rand -hex 20 2>/dev/null || echo $RANDOM$RANDOM$RANDOM)"
  public_desc="Auto asset-${asset_id_first12} for Org1MSP"
  props_b64="$(b64 "{\"object_type\":\"asset_properties\",\"color\":\"$color\",\"size\":$size,\"salt\":\"$salt\"}")"

  set +e
  out=$(peer chaincode invoke -o "$ORDERER" --ordererTLSHostnameOverride "$ORDERER_HOST" \
        --tls --cafile "$ORDERER_CA" -C "$CHANNEL" -n "$CC" \
        -c "{\"function\":\"CreateAsset\",\"Args\":[\"$public_desc\"]}" \
        --transient "{\"asset_properties\":\"$props_b64\"}" \
        --waitForEvent 2>&1)
  rc=$?
  set -e
  [[ $rc -eq 0 ]] || { echo "$out"; fail "CreateAsset failed (i=$i)"; }

  asset_id="$(echo "$out" | sed -n 's/.*payload:"\([^"]*\)".*/\1/p' | tail -n1)"
  [[ -n "$asset_id" ]] || { echo "$out"; fail "Could not parse asset_id (i=$i)"; }

  echo "Org1MSP,$asset_id,$color,$size,$salt,\"$public_desc\"" >> "$OUT_CSV"
  # log "created: $asset_id (color=$color size=$size)"
  log "created: \"$public_desc\" (color=$color size=$size)"

  # random jitter (0..SLEEP_MAX_MS)
  if [[ "$SLEEP_MAX_MS" -gt 0 ]]; then
    usleep=$(( (RANDOM % (SLEEP_MAX_MS+1)) * 1000 ))
    perl -e "select(undef, undef, undef, $usleep/1000000)" 2>/dev/null || true
  fi
done

log "Done. CSV: $OUT_CSV"
