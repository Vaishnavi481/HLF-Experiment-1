ls
# Sanity: Docker CLI exposed by Docker Desktop?
ls -l /mnt/wsl/docker-desktop/cli-tools/usr/bin/docker
# If that path exists, make sure it's on PATH:
which docker || echo "docker not in PATH"
# If docker isn’t on PATH, add a symlink once:
sudo ln -s /mnt/wsl/docker-desktop/cli-tools/usr/bin/docker /usr/bin/docker 2>/dev/null || true
# Test:
docker version
docker compose version
docker run --rm hello-world
sudo apt update && sudo apt install -y git curl jq
cd ~
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/bootstrap.sh | bash -s
export PATH=$HOME/fabric-samples/bin:$PATH
peer version && configtxgen -version
cd ~/fabric-samples/test-network
./network.sh down
./network.sh up createChannel -c mychannel
./network.sh deployCC -ccn secured -ccp ../asset-transfer-secured-agreement/chaincode-go/ -ccl go -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
# 1) Get the latest Go (Linux x86-64)
cd /tmp
curl -LO https://go.dev/dl/go1.25.3.linux-amd64.tar.gz
# 2) Verify checksum (must match exactly)
echo "0335f314b6e7bfe08c3d0cfaa7c19db961b7b99fb20be62b0a826c992ad14e0f  go1.25.3.linux-amd64.tar.gz" | sha256sum -c -
# 3) Remove any old install and extract to /usr/local
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.25.3.linux-amd64.tar.gz
# 4) Add Go to PATH for current shell
export PATH=$PATH:/usr/local/go/bin
# (optional) Make it permanent for future shells
grep -q '/usr/local/go/bin' ~/.profile || echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
# 5) Test
go version
go env GOPATH GOMODCACHE GOROOT
cd~
cd ~
./network.sh deployCC -ccn secured -ccp ../asset-transfer-secured-agreement/chaincode-go/ -ccl go -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
cd fabric-samples/
cd test-network
./network.sh deployCC -ccn secured -ccp ../asset-transfer-secured-agreement/chaincode-go/ -ccl go -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051
export ASSET_PROPERTIES=$(echo -n "{\"object_type\":\"asset_properties\",\"asset_id\":\"asset1\",\"color\":\"blue\",\"size\":35,\"salt\":\"a94a8fe5ccb19ba61c4c0873d391e987982fbbd3\"}" | base64 | tr -d \\n)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c '{"function":"CreateAsset","Args":["asset1", "A new asset for Org1MSP"]}' --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c '{"function":"GetAssetPrivateProperties","Args":["asset1"]}'
echo "MSP:" $CORE_PEER_LOCALMSPID
cd ~/fabric-samples/test-network
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
peer chaincode query -C mychannel -n secured -c '{"function":"ReadAsset","Args":["asset1"]}'
# make sure Org1 env is loaded (see step 2)
peer chaincode query   -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA"   -C mychannel -n secured   -c '{"function":"GetAssetPrivateProperties","Args":["asset1"]}'
# Org1 example — create asset1 with private properties
cd ~/fabric-samples/test-network
export ASSET_PROPERTIES=$(echo -n \
'{"object_type":"asset_properties","asset_id":"asset1","color":"blue","size":35,"salt":"a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"}' \
| base64 | tr -d \\n)
peer chaincode invoke   -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA"   -C mychannel -n secured   -c '{"function":"CreateAsset","Args":["asset1","A new asset for Org1MSP"]}'   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
# Wait a couple seconds for commit, then query private props from Org1:
peer chaincode query   -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA"   -C mychannel -n secured   -c '{"function":"GetAssetPrivateProperties","Args":["asset1"]}'
peer lifecycle chaincode querycommitted -C mychannel --name secured
peer lifecycle chaincode querycommitted -C mychannel --name secured --output json | jq .
peer chaincode query -C mychannel -n secured   -c '{"function":"ReadAsset","Args":["asset1"]}'
cd ~/fabric-samples/test-network
# (Optional) clean any pending runs
./network.sh down
./network.sh up createChannel -c mychannel -ca
# Deploy the PRIVATE DATA chaincode ("secured") with a collections config
# Go version (most common):
./network.sh deployCC   -c mychannel   -ccn secured   -ccp ../asset-transfer-private-data/chaincode-go   -ccl go   -ccv 1.1 \                       # bump version to force a new sequence
./network.sh deployCC -ccn secured -ccp ../asset-transfer-secured-agreement/chaincode-go/ -ccl go -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
peer channel fetch newest -c mychannel mychannel.block
for i in $(seq 0 5); do         peer channel fetch $i -c mychannel mychannel_$i.block;     done
cd ~
# Docker Engine + Compose v2
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
# (install Docker per docs), then:
docker --version       # aim for 24+ (works with 20+ too)
docker compose version # Compose v2
# Common tools
sudo apt-get install -y git jq make
# Languages/runtimes you plan to use
# Go (for Go chaincode or some samples)
sudo apt-get install -y golang
# Node.js LTS (for JS chaincode or client apps)
# (use nvm or NodeSource to get 18/20 LTS)
# Java 11/17 (for Java chaincode or Java clients)
sudo apt-get install -y openjdk-17-jdk
git config --global core.autocrlf false
git config --global core.longpaths true
# Show WSL kernel & default version
wsl --version
wsl -l -v     # your Linux distro (e.g., Ubuntu) should show VERSION = 2
# Quick Docker Desktop sanity
docker version
docker compose version
#!/usr/bin/env bash
set -euo pipefail
ok() { printf "\033[32mOK\033[0m  %s\n" "$*"; }
warn() { printf "\033[33mWARN\033[0m %s\n" "$*"; }
err() { printf "\033[31mFAIL\033[0m %s\n" "$*"; }
echo "=== Hyperledger Fabric 2.4 / Go chaincode prereq check (WSL) ==="
# 0) Running inside WSL2?
if grep -qi microsoft /proc/version && [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then   ok "Inside WSL"; else   err "Not inside WSL; open Ubuntu (WSL) and rerun."; fi
# 1) Docker CLI reachable (from WSL) and talking to Docker Desktop?
if docker version >/dev/null 2>&1; then   ok "Docker CLI reachable"; else   err "Docker not reachable from WSL. Enable Docker Desktop → Settings → Resources → WSL Integration for this distro."; fi
# Compose v2 present?
if docker compose version >/dev/null 2>&1; then   ok "Docker Compose v2 present"; else   err "Docker Compose v2 missing"; fi
# 2) Core tools
for bin in git curl jq make gcc; do   if command -v "$bin" >/dev/null 2>&1; then     ok "$bin found";   else     warn "$bin missing (sudo apt-get install -y $bin)";   fi; done
# 3) Go toolchain (for Go chaincode)
if command -v go >/dev/null 2>&1; then   GOVERSION=$(go version | awk '{print $3}');   ok "Go found: $GOVERSION (recommend 1.20+)"; else   err "Go not found. Install Go (1.20+)."; fi
# 4) fabric-samples + Fabric CLI
SAMPLES_DIR="${SAMPLES_DIR:-$HOME/fabric-samples}"
if [ -d "$SAMPLES_DIR" ]; then   ok "fabric-samples present at $SAMPLES_DIR"; else   warn "fabric-samples not found at $SAMPLES_DIR (git clone https://github.com/hyperledger/fabric-samples.git)"; fi
# Try to find Fabric binaries (peer, orderer, configtxgen) on PATH or in samples/bin
found_peer=""
for p in peer; do   if command -v "$p" >/dev/null 2>&1; then     found_peer=$(command -v "$p"); break;   elif [ -x "$SAMPLES_DIR/bin/$p" ]; then     found_peer="$SAMPLES_DIR/bin/$p"; break;   fi; done
if [ -n "$found_peer" ]; then   PEER_VER=$("$found_peer" version 2>/dev/null | head -n1 || true);   ok "Fabric peer CLI found: $found_peer ($PEER_VER)"; else   warn "Fabric CLI not on PATH. After running install script, add: export PATH=\$PATH:$SAMPLES_DIR/bin"; fi
# 5) Go chaincode SDK dependency sanity (fabric-chaincode-go)
GO_MOD=$(pwd)/go.mod
if [ -f "$GO_MOD" ]; then   if grep -q "github.com/hyperledger/fabric-chaincode-go" "$GO_MOD"; then     ok "fabric-chaincode-go referenced in current module";   else     warn "Current directory has go.mod but no fabric-chaincode-go require; add it for chaincode modules.";   fi; else   warn "No go.mod in current dir. (Expected inside your chaincode project.)"; fi
echo "=== Done ==="
cd ~/fabric-samples/asset-transfer-basic/chaincode-go
# or wherever YOUR chaincode lives
bash ~/fabric_prereq_check.sh
# Install nvm (if you don't have it)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
# Install and use Node 20 LTS
nvm install 20
nvm use 20
node -v    # should show v20.x
npm -v
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
nvm install 20
nvm use 20
nvm alias default 20
node -v
npm -v
which node
npm install --global windows-build-tools
v
sudo apt install build-essential
cd fabric-samples/test-network
./network.sh down
./network.sh up createChannel -c mychannel
./network.sh deployCC -ccn secured -ccp ../asset-transfer-secured-agreement/chaincode-go/ -ccl go -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
cd fabric-samples/test-network
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:9051
export ASSET_PROPERTIES=$(echo -n "{\"object_type\":\"asset_properties\",\"asset_id\":\"asset1\",\"color\":\"blue\",\"size\":35,\"salt\":\"a94a8fe5ccb19ba61c4c0873d391e987982fbbd3\"}" | base64 | tr -d \\n)
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:9051
clear
# (B) In your main terminal (Org1 env set):
ASSET_ID="asset$(date +%s)"
SALT=$(openssl rand -hex 20)
export ASSET_PROPERTIES=$(echo -n \
  "{\"object_type\":\"asset_properties\",\"asset_id\":\"$ASSET_ID\",\"color\":\"blue\",\"size\":35,\"salt\":\"$SALT\"}" \
  | base64 | tr -d \\n)
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com --tls   --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"   -C mychannel -n secured   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
# (C) Immediately read public state:
peer chaincode query -C mychannel -n secured \
clear
./monitordocker.sh fabric_test
./monitordocker.sh fabric_test | grep -E 'peer0\.org1|orderer|dev-peer0'
cd ~
cd fabric-clients/
ls
./org1_creator.sh
cd ~/fabric-clients
# 1) Make it executable
chmod +x org1_creator.sh org2_creator.sh trader_org1.sh trader_org2.sh trade_rounds.sh
# 2) Remove Windows CRLF line endings (if any)
# (install dos2unix once: sudo apt-get update && sudo apt-get install -y dos2unix)
dos2unix org1_creator.sh org2_creator.sh trader_org1.sh trader_org2.sh trade_rounds.sh
# 3) Ensure a bash shebang exists (adds one only if missing)
grep -q '^#!' org1_creator.sh || sed -i '1i #!/usr/bin/env bash' org1_creator.sh
# 4) Delete the Windows ADS “Zone.Identifier” sidecar files (harmless to remove)
rm -f *.Zone.Identifier
# 5) If you still get "Permission denied", you’re probably on a no-exec mount.
#    Move the folder into your Linux home (it already is), or copy fresh:
# mv /mnt/c/Users/<you>/Downloads/fabric-clients ~/
# cd ~/fabric-clients
# 6) Try running with bash explicitly (bypasses exec bit issues)
bash ./org1_creator.sh
# 1) (Optional) install dos2unix if you haven't yet
# sudo apt update && sudo apt install -y dos2unix
# 2) Make a backup
cp org1_creator.sh org1_creator.sh.bak
# 3) Insert definitions so the variable exists before it's used
#   - Right after the line that starts the for-loop, add ASSET_ID + asset_id_first12
#   - This keeps everything else in your script intact
awk '
  BEGIN{patched=0}
  {
    print
    if (!patched && $0 ~ /^for[ \t]+\(/) {
      print "  # --- ensure per-asset ID & 12-char prefix for description ---"       print "  ASSET_ID=\"${ASSET_ID:-$(openssl rand -hex 32 2>/dev/null || cat /proc/sys/kernel/random/uuid | tr -d -)}\""       print "  asset_id_first12=\"$(printf %s \"$ASSET_ID\" | cut -c1-12)\""       patched=1     }   } ' org1_creator.sh > org1_creator.sh.patched && mv org1_creator.sh.patched org1_creator.sh
# 4) Ensure executable + unix endings
chmod +x org1_creator.sh
# dos2unix org1_creator.sh 2>/dev/null || true
# 5) Run it
bash ./org1_creator.sh
cd ~/fabric-samples/test-network
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
PRICE=110
ASSET_PROPERTIES=$(echo -n "{\"object_type\":\"asset_properties\",\"color\":\"$COLOR\",\"size\":$SIZE,\"salt\":\"$SALT\"}"   | base64 -w0)
ASSET_PRICE=$(echo -n "{\"asset_id\":\"$ASSET_ID\",\"trade_id\":\"$(openssl rand -hex 20)\",\"price\":$PRICE}" \
  | base64 -w0)
# VerifyAssetProperties (buyer)
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$ASSET_ID\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
# AgreeToBuy (buyer)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA" -C mychannel -n secured   -c "{\"function\":\"AgreeToBuy\",\"Args\":[\"$ASSET_ID\"]}"   --transient "{\"asset_price\":\"$ASSET_PRICE\", \"asset_properties\":\"$ASSET_PROPERTIES\"}"   --waitForEvent
PEER1_CERT="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
PEER2_CERT="${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA" -C mychannel -n secured   -c "{\"function\":\"TransferAsset\",\"Args\":[\"$ASSET_ID\",\"Org2MSP\"]}"   --transient "{\"asset_price\":\"$ASSET_PRICE\"}"   --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER1_CERT"   --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER2_CERT"   --waitForEvent
# New shell
cd ~/fabric-samples/test-network
# Org2 context
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
# Paste the exact values from Org1:
ASSET_ID=<paste from Org1 echo>
COLOR=<same as Org1>
SIZE=<same as Org1>
SALT=<same as Org1>
ASSET_PROPERTIES=$(echo -n "{\"object_type\":\"asset_properties\",\"color\":\"$COLOR\",\"size\":$SIZE,\"salt\":\"$SALT\"}" | base64 -w0)
PRICE=110
TRADE_ID=$(openssl rand -hex 20)
ASSET_PRICE=$(echo -n "{\"asset_id\":\"$ASSET_ID\",\"trade_id\":\"$TRADE_ID\",\"price\":$PRICE}" | base64 -w0)
# 1) Verify
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$ASSET_ID\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
# 2) AgreeToBuy (NOTE: pass BOTH price and properties)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA" -C mychannel -n secured   -c "{\"function\":\"AgreeToBuy\",\"Args\":[\"$ASSET_ID\"]}"   --transient "{\"asset_price\":\"$ASSET_PRICE\", \"asset_properties\":\"$ASSET_PROPERTIES\"}"   --waitForEvent
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
# ownerOrg should be Org2MSP
cd ~/fabric-samples/test-network
# --- Org2 env ---
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org2MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051
export ORDERER_CA=$PWD/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
# --- Asset from your last create ---
ASSET_ID=4e80c9228f79abe47a4716771bb507bd1af49641ea13b598599eb21a4e6b257e
# You already verified properties (got "true"). Reuse the SAME ASSET_PROPERTIES variable.
# If it's still in this shell, we can proceed directly:
# Choose price and generate a trade id; persist a shared base64 blob to /tmp so Org1 can read it.
PRICE=110
TRADE_ID=$(openssl rand -hex 20)
ASSET_PRICE=$(echo -n "{\"asset_id\":\"$ASSET_ID\",\"trade_id\":\"$TRADE_ID\",\"price\":$PRICE}" | base64 -w0)
echo -n "$ASSET_PRICE" > /tmp/asset_price.b64
# (Optional) sanity: show both values you just set
echo "PRICE=$PRICE"
echo "TRADE_ID=$TRADE_ID"
# Verify again (should output: true)
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$ASSET_ID\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
# AgreeToBuy (store bid in Org2's private collection)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA" -C mychannel -n secured   -c "{\"function\":\"AgreeToBuy\",\"Args\":[\"$ASSET_ID\"]}"   --transient "{\"asset_price\":\"$ASSET_PRICE\",\"asset_properties\":\"$ASSET_PROPERTIES\"}"   --waitForEvent
cd ~/fabric-samples/test-network
ALL_IDS=$( (tail -n +2 assets_created_org1.csv; tail -n +2 assets_created_org2.csv) | cut -d',' -f2 )
for id in $ALL_IDS; do   peer chaincode query -C mychannel -n secured     -c "{\"function\":\"ReadAsset\",\"Args\":[\"$id\"]}"; done | jq -r '"\(.ownerOrg), \(.assetID), \(.publicDescription)"' | sort
ls
cd fabric-samples/
cd test-network
ls
cd ..
cd asset-sec
ls
cd asset-transfer-secured-agreement/
cd chaincode-go/
GO_MOD=$(pwd)/go.mod
if [ -f "$GO_MOD" ]; then   if grep -qE "github.com/hyperledger/(fabric-contract-api-go|fabric-chaincode-go)" "$GO_MOD"; then     ok "Fabric Go chaincode deps present in go.mod";   else     warn "go.mod found but missing Fabric Go deps; add fabric-contract-api-go and/or fabric-chaincode-go.";   fi; else   warn "No go.mod in current dir. (Run this from your chaincode directory or init a module.)"; fi
[ -f go.mod ] && grep -qE "github.com/hyperledger/(fabric-contract-api-go|fabric-chaincode-go)" go.mod   && echo "OK: Fabric Go deps present in go.mod"   || echo "WARN: Missing go.mod or Fabric Go deps"
cd ~
go get github.com/hyperledger/fabric-sdk-go
# make a client workspace
mkdir -p ~/fabric-clients/go-gateway
cd ~/fabric-clients/go-gateway
# init a Go module (any module path is fine)
go mod init example.com/fabric-client
# add dependencies
go get github.com/hyperledger/fabric-gateway@latest
go get google.golang.org/grpc@latest
go get github.com/hyperledger/fabric-protos-go-apiv2@v0.1.0
go mod tidy
go run .
# remove old Go
sudo apt remove -y golang-go || true
sudo rm -rf /usr/local/go
# install Go 1.22.x
GO_VER=1.22.6
ARCH=linux-amd64
cd ~
wget https://go.dev/dl/go${GO_VER}.${ARCH}.tar.gz
sudo tar -C /usr/local -xzf go${GO_VER}.${ARCH}.tar.gz
# ensure on PATH
grep -q '/usr/local/go/bin' ~/.bashrc || echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
go version   # should show go1.22.x
cd ~/fabric-clients/go-gateway
# add/adjust deps
go get github.com/hyperledger/fabric-gateway@v1.9.0
go get google.golang.org/grpc@latest
go get github.com/hyperledger/fabric-protos-go-apiv2@v0.3.7
go mod tidy
go get github.com/hyperledger/fabric-sdk-go
cd ~ fabric-samples/test-network
cd ~
cd ~ fabric-samples/test-network
cd fabric-samples/test-network
./network.sh down
./network.sh up
./network.sh down
./network.sh up
docker ps -a
./network.sh createChannel
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c '{"function":"InitLedger","Args":[]}'
peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}'
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c '{"function":"TransferAsset","Args":["asset6","Christopher"]}'
./network.sh down
./network.sh up -ca
asset-transfer-basic/application-gateway-typescript
cd ~
sudo apt install build-essential
cd fabric-samples/test-network
./network.sh down
./network.sh up createChannel -c mychannel -ca
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-typescript/ -ccl typescript
cd asset-transfer-basic/application-gateway-typescript
cd ..
cd asset-transfer-basic/application-gateway-typescript
npm install
sudo apt install npm
ls
npm start
cd ~
sudo apt install npm
cd /fabric-samples/asset-transfer-basic/application-gateway-typescript
cd asset-transfer-basic/application-gateway-typescript
cd fabric-samples/test-network
cd ..
cd asset-transfer-basic/application-gateway-typescript
npm install           # install deps
npm run build         # compile TS → dist/
npm start             # runs: node dist/app.js
node -v               # prefer Node 18 or 20
ls dist               # should now show app.js and friends
cat package.json      # should have "buil
rm -rf node_modules package-lock.json
# install
npm install     # now allowed because Node >= 20
# build TypeScript -> dist/
npm run build
# run
npm start       # runs node dis
ls src
cat tsconfig.json
rm -rf node_modules package-lock.json
npm install          # succeeds now that Node >= 20
npm run build        # creates dist/
npm start            # runs node dist/app.js
ls dist             # should list app.js and maps
ls
rm -rf node_modules package-lock.json
# install deps (works now that Node >= 20)
npm install
# compile TS -> dist/
npm run build
# confirm dist exists
ls dist
# run the app
npm start
echo "20" > ~/fabric-samples/asset-transfer-basic/application-gateway-typescript/.nvmrc
# next time in this dir, just run:
nvm use
cd ~/fabric-samples/test-network
./network.sh up createChannel -ca
# build & run the TS app
cd ~/fabric-samples/asset-transfer-basic/application-gateway-typescript
rm -rf node_modules package-lock.json
npm install
npm run build
ls dist              # should show app.js, *.map
npm start     
cd ~/fabric-samples/test-network
./network.sh down
# (optional) clear leftover volumes)
docker volume prune -f
# bring everything back up and (re)create channel
./network.sh up createChannel -ca
# Remove system node/npm so they can't shadow nvm
sudo apt-get remove -y nodejs npm || true
hash -r  # clear any command path caching in this shell
# Re-load nvm for THIS shell
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
nvm use 20
# Verify both node and npm point to nvm
which node
which npm
node -v
npm -v
# Expect paths under ~/.nvm/... and Node v20.x, npm v10.x
cd ~/fabric-samples/asset-transfer-basic/application-gateway-typescript
rm -rf node_modules package-lock.json   # clean any partial install from Node 12
npm install
npm run build
ls dist          # should now show app.js and .map files
npm start        # runs node dist/app.js
# 1) Ensure Fabric CLIs are on PATH
export PATH=$PATH:$HOME/fabric-samples/bin
# 2) From test-network folder
cd ~/fabric-samples/test-network
# If the network is already up, you can deploy directly:
./network.sh deployCC -ccn basic -ccl go -ccp ../asset-transfer-basic/chaincode-go
# 3) Verify it's committed
peer lifecycle chaincode querycommitted -C mychannel --name basic --output json | jq .
# Expect approvals for both orgs, version 1.0, sequence 1
cd ~/fabric-samples/asset-transfer-basic/application-gateway-typescript
npm start
peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}' | jq .
docker ps
thesis@Raftale:~/fabric-samples/test-network$ cd ~/fabric-samples/test-network
clear
cd ~/fabric-samples/test-network
nano org2Trader.sh
N=9  ./org2CreateAsset.sh
cd ~/fabric-samples/test-network
export PATH="$PWD/../bin:$PATH"
export FABRIC_CFG_PATH="$PWD/../config"
# sanity check
peer version
N=9 ./org2CreateAsset.sh
cd ~/fabric-samples/test-network
export PATH="$(cd .. && pwd)/bin:$PATH"; export FABRIC_CFG_PATH="$(cd .. && pwd)/config"
ROUNDS=5 WINDOW_SEC=10 ./org2Trader.sh
ROUNDS=2 WINDOW_SEC=10 ./org2Trader.sh
ROUNDS=10 WINDOW_SEC=10 ./org2Trader.sh
ROUNDS=1 WINDOW_SEC=10 ./org1Trader.sh
cd fabric-samples/test-network
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051
./network.sh down
./network.sh up createChannel -c mychannel
./network.sh deployCC -ccn secured -ccp ../asset-transfer-secured-agreement/chaincode-go/ -ccl go -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051
export ASSET_PROPERTIES=$(echo -n "{\"object_type\":\"asset_properties\",\"asset_id\":\"asset1\",\"color\":\"blue\",\"size\":35,\"salt\":\"a94a8fe5ccb19ba61c4c0873d391e987982fbbd3\"}" | base64 | tr -d \\n)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c '{"function":"CreateAsset","Args":["asset1", "A new asset for Org1MSP"]}' --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c '{"function":"GetAssetPrivateProperties","Args":["asset1"]}'
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
# Re-run the query WITHOUT any -o / orderer flags:
peer chaincode query   -C mychannel -n secured   -c '{"function":"GetAssetPrivateProperties","Args":["asset1"]}'
peer chaincode query   -C mychannel -n secured   -c '{"function":"ReadAsset","Args":["asset1"]}'
ASSET_ID="asset$(date +%s)"
SALT=$(openssl rand -hex 20)
export ASSET_PROPERTIES=$(echo -n \
  "{\"object_type\":\"asset_properties\",\"asset_id\":\"$ASSET_ID\",\"color\":\"blue\",\"size\":35,\"salt\":\"$SALT\"}" \
  | base64 | tr -d \\n)
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"   -C mychannel -n secured   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
peer chaincode query   -C mychannel -n secured   -c "{\"function\":\"GetAssetPrivateProperties\",\"Args\":[\"$ASSET_ID\"]}"
echo "$CORE_PEER_LOCALMSPID"
echo "$CORE_PEER_ADDRESS"
docker ps --format '{{.Names}}' | grep dev-peer0.org1.*secured
docker logs -f <that-container-name>
docker ps --format '{{.Names}}' | grep dev-peer0.org1.*secured
docker logs -f <that-container-name>
clear
docker logs -f dev-peer0.org1.example.com-secured_1.0-9a601e043d3c74df8248eb43502964a7ea521ffe3ab61110a82e5b1994e0833e
peer lifecycle chaincode querycommitted -C mychannel --name secured --output json | jq .
# Replace with the latest ASSET_ID you just created
echo "$ASSET_ID"
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"GetAssetPrivatePropertiesHash\",\"Args\":[\"$ASSET_ID\"]}"
echo $CORE_PEER_LOCALMSPID   # expect Org1MSP
echo $CORE_PEER_ADDRESS      # expect localhost:7051
# Now query private props
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"GetAssetPrivateProperties\",\"Args\":[\"$ASSET_ID\"]}"
# (A) Tail chaincode logs in another terminal
docker logs -f dev-peer0.org1.example.com-secured_1.0-9a601e043d3c74df8248eb43502964a7ea521ffe3ab61110a82e5b1994e0833e
# (B) In your main terminal (Org1 env set):
ASSET_ID="asset$(date +%s)"
SALT=$(openssl rand -hex 20)
export ASSET_PROPERTIES=$(echo -n \
  "{\"object_type\":\"asset_properties\",\"asset_id\":\"$ASSET_ID\",\"color\":\"blue\",\"size\":35,\"salt\":\"$SALT\"}" \
  | base64 | tr -d \\n)
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com --tls   --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"   -C mychannel -n secured   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
# (C) Immediately read public state:
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
# (D) Read the private hash:
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"GetAssetPrivatePropertiesHash\",\"Args\":[\"$ASSET_ID\"]}"
# (E) Read the private properties (still Org1):
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"GetAssetPrivateProperties\",\"Args\":[\"$ASSET_ID\"]}"
docker logs -f dev-peer0.org1.example.com-secured_1.0-9a601e043d3c74df8248eb43502964a7ea521ffe3ab61110a82e5b1994e0833e
# --- Ensure Org1 env (you already had these) ---
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051
# --- New unique asset id + random salt ---
ASSET_ID="asset$(date +%s)"
SALT=$(openssl rand -hex 20)
# --- IMPORTANT: include appraisedValue and use the expected field names ---
export ASSET_PROPERTIES=$(echo -n \
  "{\"object_type\":\"asset_properties\", \
    \"asset_id\":\"$ASSET_ID\", \
    \"color\":\"blue\", \
    \"size\":35, \
    \"appraisedValue\":1300, \
    \"salt\":\"$SALT\"}" \
  | base64 | tr -d \\n)
# --- Create the asset (invoke goes to orderer; that’s fine) ---
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"   -C mychannel -n secured   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
# Public record should exist
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
# Private properties (Org1 implicit collection)
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"GetAssetPrivateProperties\",\"Args\":[\"$ASSET_ID\"]}"
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$ASSET_ID\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
ASSET_ID="asset$(date +%s)"
SALT=$(openssl rand -hex 20)
export ASSET_PROPERTIES=$(
  echo -n \
'{
  "object_type":"asset_properties",
  "asset_id":"'"$ASSET_ID"'",
  "color":"blue",
  "size":35,
  "appraisedValue":1300,
  "salt":"'"$SALT"'"
}' | base64 | tr -d '\n'
)
# sanity-print
echo "ASSET_ID=$ASSET_ID"
echo "$ASSET_PROPERTIES" | base64 -d
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"   -C mychannel -n secured   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"GetAssetPrivateProperties\",\"Args\":[\"$ASSET_ID\"]}"
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$ASSET_ID\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
ASSET_ID="asset$(date +%s)"
SALT=$(openssl rand -hex 20)
export ASSET_PROPERTIES=$(
  echo -n '{
    "object_type":"asset_properties",
    "asset_id":"'"$ASSET_ID"'",
    "color":"blue",
    "size":35,
    "appraisedValue":1300,
    "salt":"'"$SALT"'"
  }' | base64 | tr -d '\n'
)
ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
ORG1_TLS="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
ORG2_TLS="${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA"   -C mychannel -n secured   --peerAddresses localhost:7051 --tlsRootCertFiles "$ORG1_TLS"   --peerAddresses localhost:9051 --tlsRootCertFiles "$ORG2_TLS"   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"   --waitForEvent --waitForEventTimeout 30s
# Public state
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
# Private properties (Org1 implicit collection)
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"GetAssetPrivateProperties\",\"Args\":[\"$ASSET_ID\"]}"
docker logs peer0.org1.example.com 2>&1 | grep -i invalid | tail -n 5
peer channel getinfo -c mychannel
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA"   -C mychannel -n secured   --peerAddresses localhost:7051 --tlsRootCertFiles "$ORG1_TLS"   --peerAddresses localhost:9051 --tlsRootCertFiles "$ORG2_TLS"   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"   --waitForEvent --waitForEventTimeout 30s
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA"   -C mychannel -n secured   --peerAddresses localhost:7051 --tlsRootCertFiles "$ORG1_TLS"   --peerAddresses localhost:9051 --tlsRootCertFiles "$ORG2_TLS"   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"   --waitForEvent --waitForEventTimeout 30s
export ASSET_PROPERTIES=$(echo -n "{\"object_type\":\"asset_properties\",\"asset_id\":\"asset1\",\"color\":\"blue\",\"size\":35,\"salt\":\"a94a8fe5ccb19ba61c4c0873d391e987982fbbd3\"}" | base64 | tr -d \\n)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c '{"function":"CreateAsset","Args":["asset1", "A new asset for Org1MSP"]}' --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
peer channel getinfo -c mychannel
# still in fabric-samples/test-network with Org1 env exported
ASSET_ID="asset$(date +%s)"
SALT=$(openssl rand -hex 20)
export ASSET_PROPERTIES=$(
  echo -n '{
    "object_type":"asset_properties",
    "asset_id":"'"$ASSET_ID"'",
    "color":"blue",
    "size":35,
    "appraisedValue":1300,
    "salt":"'"$SALT"'"
  }' | base64 | tr -d '\n'
)
ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
ORG1_TLS="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA"   -C mychannel -n secured   --peerAddresses localhost:7051 --tlsRootCertFiles "$ORG1_TLS"   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"   --waitForEvent --waitForEventTimeout 30s
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
TXID=914c220a  # or the full ID if you have it
# Peer endorse/commit logs
docker logs peer0.org1.example.com 2>&1 | grep -i "$TXID"
# Orderer receipt of the tx (look for your channel/tx)
docker logs orderer.example.com 2>&1 | grep -i "$TXID"
# Org2 peer (if relevant)
docker logs peer0.org2.example.com 2>&1 | grep -i "$TXID"
# Example: make chaincode & ledger debug on Org1 peer
curl -s -X PUT http://localhost:9444/logspec -d 'chaincode=debug:ledger=debug:info'
# Check current spec
curl -s http://localhost:9444/logspec
docker logs -f peer0.org1.example.com 2>&1 | grep -E 'endorser|chaincode|txID|Committed'
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051
ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
ORG1_TLS="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
ASSET_ID="asset$(date +%s)"
SALT=$(openssl rand -hex 20)
export ASSET_PROPERTIES=$(
  echo -n '{
    "object_type":"asset_properties",
    "asset_id":"'"$ASSET_ID"'",
    "color":"blue",
    "size":35,
    "appraisedValue":1300,
    "salt":"'"$SALT"'"
  }' | base64 | tr -d '\n'
)
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA"   -C mychannel -n secured   --peerAddresses localhost:7051 --tlsRootCertFiles "$ORG1_TLS"   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"   --waitForEvent --waitForEventTimeout 30s
# --- Org1 peer CLI env ---
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051
ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
ORG1_TLS="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
# --- Fresh IDs ---
ASSET_ID="asset$(date +%s)"
SALT=$(openssl rand -hex 20)
# --- Build the transient JSON (includes appraisedValue) ---
export ASSET_PROPERTIES=$(
  echo -n '{
    "object_type":"asset_properties",
    "asset_id":"'"$ASSET_ID"'",
    "color":"blue",
    "size":35,
    "appraisedValue":1300,
    "salt":"'"$SALT"'"
  }' | base64 | tr -d '\n'
)
echo "ASSET_ID=$ASSET_ID"
# --- CREATE: endorse on Org1 ONLY, and WAIT for commit ---
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA"   -C mychannel -n secured   --peerAddresses localhost:7051 --tlsRootCertFiles "$ORG1_TLS"   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"   --waitForEvent --waitForEventTimeout 30s
# --- READ public (no orderer flags) ---
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
# --- READ Org1 private props ---
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"GetAssetPrivateProperties\",\"Args\":[\"$ASSET_ID\"]}"
# --- (Optional) verify props by hash compare ---
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$ASSET_ID\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
peer channel getinfo -c mychannel
# then show the last block's txids (qscc)
peer chaincode query -C mychannel -n qscc -c '{"Args":["GetChainInfo","mychannel"]}'
# or use Explorer, or `docker logs peer0.org1 | grep "Committed block \[" -n`
# Org1 env
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051
ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
ORG1_TLS="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
# Fresh IDs (echo so you can copy-paste later)
ASSET_ID="asset$(date +%s)"
SALT=$(openssl rand -hex 20)
echo "ASSET_ID=$ASSET_ID"
export ASSET_PROPERTIES=$(
  echo -n '{
    "object_type":"asset_properties",
    "asset_id":"'"$ASSET_ID"'",
    "color":"blue",
    "size":35,
    "appraisedValue":1300,
    "salt":"'"$SALT"'"
  }' | base64 | tr -d '\n'
)
# CREATE (endorse on Org1 only) and WAIT for commit
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA"   -C mychannel -n secured   --peerAddresses localhost:7051 --tlsRootCertFiles "$ORG1_TLS"   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"   --waitForEvent --waitForEventTimeout 30s
# READ public
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
# READ Org1 private props
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"GetAssetPrivateProperties\",\"Args\":[\"$ASSET_ID\"]}"
# (Optional) verify properties via hash
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$ASSET_ID\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
docker rm -f $(docker ps -q --filter "ancestor=gliderlabs/logspout") 2>/dev/null || true
docker restart peer0.org1.example.com
# Org1 env
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051
ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
ORG1_TLS="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
# Fresh IDs (echo so you can copy-paste later)
ASSET_ID="asset$(date +%s)"
SALT=$(openssl rand -hex 20)
echo "ASSET_ID=$ASSET_ID"
export ASSET_PROPERTIES=$(
  echo -n '{
    "object_type":"asset_properties",
    "asset_id":"'"$ASSET_ID"'",
    "color":"blue",
    "size":35,
    "appraisedValue":1300,
    "salt":"'"$SALT"'"
  }' | base64 | tr -d '\n'
)
# CREATE (endorse on Org1 only) and WAIT for commit
peer chaincode invoke -o localhost:7050   --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA"   -C mychannel -n secured   --peerAddresses localhost:7051 --tlsRootCertFiles "$ORG1_TLS"   -c "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"Created by Org1MSP\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"   --waitForEvent --waitForEventTimeout 30s
# READ public
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
# READ Org1 private props
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"GetAssetPrivateProperties\",\"Args\":[\"$ASSET_ID\"]}"
# (Optional) verify properties via hash
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$ASSET_ID\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
docker ps
environment:
cd ~/fabric-samples/test-network
nano docker/docker-compose-test-net.yaml
cd ~/fabric-samples/test-network
./network.sh down
./network.sh up createChannel -c mychannel -ca
./network.sh deployCC -ccn secured -ccp ../asset-transfer-secured-agreement/chaincode-go/ -ccl go -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051
export ASSET_PROPERTIES=$(echo -n "{\"object_type\":\"asset_properties\",\"asset_id\":\"asset1\",\"color\":\"blue\",\"size\":35,\"salt\":\"a94a8fe5ccb19ba61c4c0873d391e987982fbbd3\"}" | base64 | tr -d \\n)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c '{"function":"CreateAsset","Args":["asset1", "A new asset for Org1MSP"]}' --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c '{"function":"GetAssetPrivateProperties","Args":["asset1"]}'
# ---- ORG1 (peer0.org1) ----
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
ASSET_ID=asset1
ASSET_PROPS=$(echo -n '{"objectType":"asset_properties","assetID":"'"$ASSET_ID"'","color":"blue","size":5,"appraisedValue":100,"ownerOrg":"Org1MSP"}' | base64 -w0)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile $ORDERER_CA -C mychannel -n secured   --transient "{\"asset_properties\":\"$ASSET_PROPS\"}"   -c '{"Args":["CreateAsset"]}' --waitForEvent
ASSET_ID=asset1
ASSET_PROPS=$(echo -n '{"objectType":"asset_properties","assetID":"'"$ASSET_ID"'","color":"blue","size":5,"appraisedValue":100,"ownerOrg":"Org1MSP"}' | base64 -w0)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile $ORDERER_CA -C mychannel -n secured   --transient "{\"asset_properties\":\"$ASSET_PROPS\"}"   -c '{"Args":["CreateAsset","'"$ASSET_ID"'"]}'   --waitForEvent
peer chaincode query -C mychannel -n secured -c '{"Args":["ReadAsset","asset1"]}'
# All assets (range scan)
peer chaincode query -C mychannel -n secured   -c '{"Args":["GetAssetByRange","","~"]}' | jq .
export ASSET_PROPERTIES=$(echo -n "{\"object_type\":\"asset_properties\",\"color\":\"blue\",\"size\":35,\"salt\":\"a94a8fe5ccb19ba61c4c0873d391e987982fbbd3\"}" | base64 | tr -d \\n)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c '{"function":"CreateAsset","Args":["A new asset for Org1MSP"]}' --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
export ASSET_ID=d9923f21b770adbc79cbcc47a3aeecc81dc7f030bd129155301ce3932be7fbcc
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c "{\"function\":\"GetAssetPrivateProperties\",\"Args\":[\"$ASSET_ID\"]}"
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c "{\"function\":\"ChangePublicDescription\",\"Args\":[\"$ASSET_ID\",\"This asset is for sale\"]}"
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
export ASSET_PRICE=$(echo -n "{\"asset_id\":\"$ASSET_ID\",\"trade_id\":\"109f4b3c50d7b0df729d299bc6f8e9ef9066971f\",\"price\":110}" | base64 | tr -d \\n)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c "{\"function\":\"AgreeToSell\",\"Args\":[\"$ASSET_ID\"]}" --transient "{\"asset_price\":\"$ASSET_PRICE\"}"
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c "{\"function\":\"GetAssetSalesPrice\",\"Args\":[\"$ASSET_ID\"]}"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c "{\"function\":\"TransferAsset\",\"Args\":[\"$ASSET_ID\",\"Org2MSP\"]}" --transient "{\"asset_price\":\"$ASSET_PRICE\"}" --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
export ASSET_PRICE=$(echo -n "{\"asset_id\":\"$ASSET_ID\",\"trade_id\":\"109f4b3c50d7b0df729d299bc6f8e9ef9066971f\",\"price\":100}" | base64 | tr -d \\n)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c "{\"function\":\"AgreeToSell\",\"Args\":[\"$ASSET_ID\",\"Org2MSP\"]}" --transient "{\"asset_price\":\"$ASSET_PRICE\"}"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c "{\"function\":\"TransferAsset\",\"Args\":[\"$ASSET_ID\",\"Org2MSP\"]}" --transient "{\"asset_price\":\"$ASSET_PRICE\"}" --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n secured -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
# In test-network directory
cd ~/fabric-samples/test-network
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
COLOR=blue
SIZE=35
SALT=$(openssl rand -hex 20)
PUBLIC_DESC="asset-$(date +%H%M%S)"
ASSET_PROPERTIES=$(echo -n "{\"object_type\":\"asset_properties\",\"color\":\"$COLOR\",\"size\":$SIZE,\"salt\":\"$SALT\"}" \
  | base64 -w0)
out=$(peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "$ORDERER_CA" -C mychannel -n secured \
  -c "{\"function\":\"CreateAsset\",\"Args\":[\"$PUBLIC_DESC\"]}" \
  --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}" \
  --waitForEvent 2>&1)
echo "$out"
ASSET_ID=$(echo "$out" | sed -n 's/.*payload:"\([^"]*\)".*/\1/p' | tail -n1)
echo "ASSET_ID=$ASSET_ID"
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"GetAssetPrivateProperties\",\"Args\":[\"$ASSET_ID\"]}"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA" -C mychannel -n secured   -c "{\"function\":\"ChangePublicDescription\",\"Args\":[\"$ASSET_ID\",\"for sale\"]}"   --waitForEvent
# AgreeToSell (seller = current owner)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA" -C mychannel -n secured   -c "{\"function\":\"AgreeToSell\",\"Args\":[\"$ASSET_ID\",\"Org2MSP\"]}"   --transient "{\"asset_price\":\"$ASSET_PRICE\"}"   --waitForEvent
PEER1_CERT="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
PEER2_CERT="${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA" -C mychannel -n secured   -c "{\"function\":\"TransferAsset\",\"Args\":[\"$ASSET_ID\",\"Org2MSP\"]}"   --transient "{\"asset_price\":\"$ASSET_PRICE\"}"   --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER1_CERT"   --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER2_CERT"   --waitForEvent
# Show what you currently have
echo "$ASSET_ID"
# See if the asset exists at all:
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
cd ~/fabric-samples/test-network
# Org1 context
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
# Pick properties (KEEP these to share with Org2)
COLOR=blue
SIZE=35
SALT=$(openssl rand -hex 20)
PUBLIC_DESC="for sale $(date +%H%M%S)"
ASSET_PROPERTIES=$(echo -n "{\"object_type\":\"asset_properties\",\"color\":\"$COLOR\",\"size\":$SIZE,\"salt\":\"$SALT\"}" | base64 -w0)
out=$(peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "$ORDERER_CA" -C mychannel -n secured \
  -c "{\"function\":\"CreateAsset\",\"Args\":[\"$PUBLIC_DESC\"]}" \
  --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}" \
  --waitForEvent 2>&1)
echo "$out"
ASSET_ID=$(echo "$out" | sed -n 's/.*payload:"\([^"]*\)".*/\1/p' | tail -n1)
echo "ASSET_ID=$ASSET_ID"
# Quick sanity: this should return "true"
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$ASSET_ID\"]}"   --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA" -C mychannel -n secured   -c "{\"function\":\"AgreeToSell\",\"Args\":[\"$ASSET_ID\",\"Org2MSP\"]}"   --transient "{\"asset_price\":\"$ASSET_PRICE\"}"   --waitForEvent
PEER1_CERT="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
PEER2_CERT="${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA" -C mychannel -n secured   -c "{\"function\":\"TransferAsset\",\"Args\":[\"$ASSET_ID\",\"Org2MSP\"]}"   --transient "{\"asset_price\":\"$ASSET_PRICE\"}"   --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER1_CERT"   --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER2_CERT"   --waitForEvent
cd ~/fabric-samples/test-network
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
export ORDERER_CA=$PWD/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
COLOR=blue; SIZE=35; SALT=$(openssl rand -hex 20)
PUBLIC_DESC="for sale $(date +%H%M%S)"
ASSET_PROPERTIES=$(echo -n "{\"object_type\":\"asset_properties\",\"color\":\"$COLOR\",\"size\":$SIZE,\"salt\":\"$SALT\"}" | base64 -w0)
out=$(peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C mychannel -n secured -c "{\"function\":\"CreateAsset\",\"Args\":[\"$PUBLIC_DESC\"]}" --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}" --waitForEvent 2>&1); echo "$out"
ASSET_ID=$(echo "$out" | sed -n 's/.*payload:"\([^"]*\)".*/\1/p' | tail -n1); echo "ASSET_ID=$ASSET_ID"
# Quick verify (must print true)
peer chaincode query -C mychannel -n secured -c "{\"function\":\"VerifyAssetProperties\",\"Args\":[\"$ASSET_ID\"]}" --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
cd ~/fabric-samples/test-network
# --- Org1 env ---
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
export ORDERER_CA=$PWD/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
ASSET_ID=4e80c9228f79abe47a4716771bb507bd1af49641ea13b598599eb21a4e6b257e
ASSET_PRICE=$(cat /tmp/asset_price.b64)
# Agree to sell to Org2 using the EXACT same asset_price blob
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA" -C mychannel -n secured   -c "{\"function\":\"AgreeToSell\",\"Args\":[\"$ASSET_ID\",\"Org2MSP\"]}"   --transient "{\"asset_price\":\"$ASSET_PRICE\"}"   --waitForEvent
# Transfer (endorse with both peers)
PEER1_CERT=$PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
PEER2_CERT=$PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com   --tls --cafile "$ORDERER_CA" -C mychannel -n secured   -c "{\"function\":\"TransferAsset\",\"Args\":[\"$ASSET_ID\",\"Org2MSP\"]}"   --transient "{\"asset_price\":\"$ASSET_PRICE\"}"   --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER1_CERT"   --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER2_CERT"   --waitForEvent
# Confirm ownership moved to Org2
peer chaincode query -C mychannel -n secured   -c "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}"
nano test.sh
chmod +x ./test.sh
./test.sh 4e80c9228f79abe47a4716771bb507bd1af49641ea13b598599eb21a4e6b257e 110
nano org1CreateAsset.sh
nano org2CreateAsset.sh
cd ~/fabric-samples/test-network
chmod +x ../org1CreateAsset.sh ../org2CreateAsset.sh 
# from: ~/fabric-samples/test-network
ls -l org*CreateAsset.sh
# make them executable (note the ./)
chmod +x ./org1CreateAsset.sh ./org2CreateAsset.sh
for id in $(cut -d, -f2 assets_created_org1.csv assets_created_org2.csv | tail -n +2); do   peer chaincode query -C mychannel -n secured -c "{\"function\":\"ReadAsset\",\"Args\":[\"$id\"]}"; done | jq -r '.ownerOrg' | sort | uniq -c
nano org1Trader.sh
cd ~/fabric-samples/test-network
# Make executable
chmod +x ./org1Trader.sh ./org2Trader.sh
N=11 ./org1CreateAsset.sh
export PATH="$(cd .. && pwd)/bin:$PATH"; export FABRIC_CFG_PATH="$(cd .. && pwd)/config"
ROUNDS=5 WINDOW_SEC=10 ./org1Trader.sh
ROUNDS=2 WINDOW_SEC=10 ./org1Trader.sh
peer chaincode query -C mychannel -n secured -c '{"function":"GetAllAssets","Args":[]}' | jq '[.[] | select(.owner | test("Org1MSP"; "i"))]'
peer chaincode query -C mychannel -n secured -c '{"function":"GetAssetsByOwner","Args":["Org1MSP"]}
ROUNDS=5 WINDOW_SEC=10 ./org1Trader.sh
ROUNDS=1 WINDOW_SEC=10 ./org1Trader.sh
cd ~
git clone https://github.com/hyperledger-labs/blockchain-explorer.git
cd blockchain-explorer
docker network ls | grep -i fabric
# or
docker network ls | grep -i test
# Org1 admin key:
ls ~/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore
# copy the filename into __PRIVKEY_ORG1__
# Org2 admin key:
ls ~/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore
# copy the filename into __PRIVKEY_ORG2__
docker compose up -d explorerdb
docker compose up -d explorer
docker compose ps
docker compose up
export EXPLORER_CONFIG_FILE_PATH=$PWD/examples/net1/config.json
export EXPLORER_PROFILE_DIR_PATH=$PWD/examples/net1/connection-profile
export FABRIC_CRYPTO_PATH=$PWD/examples/net1/crypto
export PORT=8080
docker compose down
docker compose up
docker compose down
docker compose up
docker compose down
docker compose up
# List what Explorer sees inside the container
docker exec -it explorer.mynetwork.com bash -lc "ls -l /tmp/crypto/org1/admin/signcerts && ls -l /tmp/crypto/org1/admin/keystore"
# Create the expected tree
mkdir -p examples/net1/crypto/org1/admin/{signcerts,keystore}
mkdir -p examples/net1/crypto/org2/admin/{signcerts,keystore}
mkdir -p examples/net1/crypto/peers/peer0.org1.example.com/tls
mkdir -p examples/net1/crypto/peers/peer0.org2.example.com/tls
mkdir -p examples/net1/crypto/orderer
# === ORG1 admin cert & key ===
# cert.pem exists in the Admin signcerts dir in Fabric crypto
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/cert.pem    examples/net1/crypto/org1/admin/signcerts/cert.pem
# Use your actual *_sk filename (you shared it earlier)
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/a83050adda9ea4320b5e550e392f9cb472134c2d9bc06836aa228d919dea4720_sk    examples/net1/crypto/org1/admin/keystore/priv_sk
# === ORG2 admin cert & key (keep for later multi-org views) ===
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/signcerts/cert.pem    examples/net1/crypto/org2/admin/signcerts/cert.pem
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore/98cc06d888edc052190b55d5b62fe935c6a1a2e597cbc327a0f7e73a70e3c06a_sk    examples/net1/crypto/org2/admin/keystore/priv_sk
# === TLS CA certs for peers & orderer ===
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt    examples/net1/crypto/peers/peer0.org1.example.com/tls/ca.crt
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt    examples/net1/crypto/peers/peer0.org2.example.com/tls/ca.crt
cp ~/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem    examples/net1/crypto/orderer/tlsca.example.com-cert.pem
ls -l examples/net1/crypto/org1/admin/signcerts/cert.pem
ls -l examples/net1/crypto/org1/admin/keystore/priv_sk
ls -l examples/net1/crypto/org2/admin/signcerts/cert.pem
ls -l examples/net1/crypto/org2/admin/keystore/priv_sk
ls -l examples/net1/crypto/peers/peer0.org1.example.com/tls/ca.crt

ls -l examples/net1/crypto/orderer/tlsca.example.com-cert.pem
export PORT=8080
export EXPLORER_CONFIG_FILE_PATH=$PWD/examples/net1/config.json
export EXPLORER_PROFILE_DIR_PATH=$PWD/examples/net1/connection-profile
export FABRIC_CRYPTO_PATH=$PWD/examples/net1/crypto
docker compose down --remove-orphans
docker compose up -d

docker exec -it explorer.mynetwork.com bash -lc   "ls -l /tmp/crypto/org1/admin/signcerts && \
   ls -l /tmp/crypto/org1/admin/keystore && \
   ls -l /opt/explorer/app/platform/fabric/connection-profile && \
   cat /opt/explorer/app/platform/fabric/config.json"
# 1) Inspect files *inside* the running container
docker exec -it explorer.mynetwork.com sh -lc   "ls -l /tmp/crypto/org1/admin/signcerts && \
   ls -l /tmp/crypto/org1/admin/keystore && \
   ls -l /tmp/crypto/org2/admin/signcerts && \
   ls -l /tmp/crypto/org2/admin/keystore && \
   ls -l /tmp/crypto/peers/peer0.org1.example.com/tls && \
   ls -l /tmp/crypto/peers/peer0.org2.example.com/tls && \
   ls -l /tmp/crypto/orderer && \
   ls -l /opt/explorer/app/platform/fabric/connection-profile && \
   cat /opt/explorer/app/platform/fabric/config.json"
docker logs -f --tail=200 explorer.mynetwork.com
docker compose down
docker compose up
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
cd ~/blockchain-explorer
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
export PORT=8080
export EXPLORER_CONFIG_FILE_PATH=$PWD/examples/net1/config.json
export EXPLORER_PROFILE_DIR_PATH=$PWD/examples/net1/connection-profile
export FABRIC_CRYPTO_PATH=$PWD/examples/net1/crypto
docker restart orderer.example.com peer0.org1.example.com peer0.org2.example.com ca_org1 ca_org2 ca_orderer
cd ~/blockchain-explorer
docker compose up -d
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
docker logs --tail=120 explorer.mynetwork.com
docker compose down
mkdir -p $HOME/chaincode/progorder
cd $HOME/chaincode/progorder
cat > chaincode.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ProgOrderCC struct{ contractapi.Contract }

type Stamp struct {
	ClientID string `json:"client_id"`
	Seq      int    `json:"seq_no"`
	TxID     string `json:"tx_id"`
	TS       int64  `json:"ts_unix"`
	DelayOdd bool   `json:"delay_odd"`
}

func (p *ProgOrderCC) TagTx(ctx contractapi.TransactionContextInterface, clientID, seqStr, delayOddStr string) error {
	seq, err := strconv.Atoi(seqStr)
	if err != nil {
		return fmt.Errorf("bad seq: %v", err)
	}
	delayOdd := delayOddStr == "true"

	// Artificial endorsement delay for odd sequence numbers
	if delayOdd && (seq%2 == 1) {
		time.Sleep(3 * time.Second)
	}

	txid := ctx.GetStub().GetTxID()
	key := fmt.Sprintf("c:%s#%06d#%s", clientID, seq, txid)

	st := Stamp{ClientID: clientID, Seq: seq, TxID: txid, TS: time.Now().Unix(), DelayOdd: delayOdd}
	b, _ := json.Marshal(st)
	return ctx.GetStub().PutState(key, b)
}

func main() {
	cc, err := contractapi.NewChaincode(new(ProgOrderCC))
	if err != nil {
		panic(err)
	}
	if err := cc.Start(); err != nil {
		panic(err)
	}
}
EOF

cat > go.mod <<'EOF'
module progorder

go 1.20

require github.com/hyperledger/fabric-contract-api-go v1.2.3
EOF

cd $HOME/fabric-samples/test-network
./network.sh down
./network.sh up createChannel -c mychannel -ca
cd addOrg3
./addOrg3.sh up -c mychannel
cd $HOME/fabric-samples/test-network
CC_NAME=progorder
CC_LANG=golang
CC_PATH=$HOME/chaincode/progorder
CC_VERSION=1
CC_SEQUENCE=1
./network.sh deployCC   -c mychannel   -ccn $CC_NAME   -ccl $CC_LANG   -ccp "$CC_PATH"   -ccv $CC_VERSION   -ccs $CC_SEQUENCE
cd /home/thesis/chaincode/progorder
# You should see chaincode.go and go.mod here:
ls
# (optional but recommended) fetch dependencies and create go.sum
go mod tidy
cd ~/fabric-samples/test-network
CC_NAME=progorder
CC_LANG=go                          # <-- this is the key fix
CC_PATH=/home/thesis/chaincode/progorder
CC_VERSION=1
CC_SEQUENCE=1
./network.sh deployCC   -c mychannel   -ccn $CC_NAME   -ccl $CC_LANG   -ccp "$CC_PATH"   -ccv $CC_VERSION   -ccs $CC_SEQUENCE
./network.sh down
cd ~/fabric-samples/test-network
CC_NAME=progorder
CC_LANG=go                          # <-- this is the key fix
CC_PATH=/home/thesis/chaincode/progorder
CC_VERSION=1
CC_SEQUENCE=1
./network.sh deployCC   -c mychannel   -ccn $CC_NAME   -ccl $CC_LANG   -ccp "$CC_PATH"   -ccv $CC_VERSION   -ccs $CC_SEQUENCE
cd ~/fabric-samples/test-network
./network.sh deployCC   -ccn progorder   -ccp /home/thesis/chaincode/progorder   -ccl go   -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
# 0) From anywhere: show what’s running (optional)
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
# 1) Stop & start Explorer cleanly (does NOT touch Fabric)
cd ~/blockchain-explorer
docker compose down --remove-orphans
# (optional) ensure env vars are set if you use them instead of .env
export PORT=8080
export EXPLORER_CONFIG_FILE_PATH=$PWD/examples/net1/config.json
export EXPLORER_PROFILE_DIR_PATH=$PWD/examples/net1/connection-profile
export FABRIC_CRYPTO_PATH=$PWD/examples/net1/crypto
# 2) Restart Fabric containers (non-destructive)
docker restart orderer.example.com peer0.org1.example.com peer0.org2.example.com ca_org1 ca_org2 ca_orderer
# 3) Bring Explorer back
cd ~/blockchain-explorer
docker compose up -d
# 4) Sanity checks
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
docker logs --tail=120 explorer.mynetwork.com
cd ..
cd blockchain-explorer/
# 0) From anywhere: show what’s running (optional)
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
# 1) Stop & start Explorer cleanly (does NOT touch Fabric)
cd ~/blockchain-explorer
docker compose down --remove-orphans
# (optional) ensure env vars are set if you use them instead of .env
export PORT=8080
export EXPLORER_CONFIG_FILE_PATH=$PWD/examples/net1/config.json
export EXPLORER_PROFILE_DIR_PATH=$PWD/examples/net1/connection-profile
export FABRIC_CRYPTO_PATH=$PWD/examples/net1/crypto
# 2) Restart Fabric containers (non-destructive)
docker restart orderer.example.com peer0.org1.example.com peer0.org2.example.com ca_org1 ca_org2 ca_orderer
# 3) Bring Explorer back
cd ~/blockchain-explorer
docker compose up -d
# 4) Sanity checks
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
docker logs --tail=120 explorer.mynetwork.com
clr
clear
sudo tar -xvf ls 
ls
go version
echo GOROOT
echo $GOROOT
ls
cd go
clear
cd ..
ls
echo $GOROOT
touch hello.go
ls
nano hello.go
go build hello.go
nano hello.go
go run .
go help
go build
go build hello.go
go run hello.go
python version
git --version
curl --version
node --version
python --version
sudo apt-get installl python
sudo apt install python3
python --version
python3 --version
sudo apt install libltdl-de
docker --version
docker-compose --version
curl --version
cd fabric-samples/
ls
cd fabric-samples/test-network
./network.sh down
./network.sh up createChannel -c channel1
cd addOrg3
./addOrg3.sh up -c channel1
cd ..
./network.sh down
./network.sh up createChannel -c channel1
cd addOrg3
../../bin/cryptogen generate --config=org3-crypto.yaml --output="../organizations"
export FABRIC_CFG_PATH=$PWD
../../bin/configtxgen -printOrg Org3MSP > ../organizations/peerOrganizations/org3.example.com/org3.json
docker-compose -f compose/compose-org3.yaml -f compose/docker/docker-compose-org3.yaml up -d
cd ..
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer channel fetch config channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c channel1 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
cd channel-artifacts
configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq ".data.data[0].payload.data.config" config_block.json > config.json
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org3MSP":.[1]}}}}}' config.json ../organizations/peerOrganizations/org3.example.com/org3.json > modified_config.json
configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator compute_update --channel_id channel1 --original config.pb --updated modified_config.pb --output org3_update.pb
configtxlator proto_decode --input org3_update.pb --type common.ConfigUpdate --output org3_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'channel1'", "type":2}},"data":{"config_update":'$(cat org3_update.json)'}}}' | jq . > org3_update_in_envelope.json
configtxlator proto_encode --input org3_update_in_envelope.json --type common.Envelope --output org3_update_in_envelope.pb
cd ..
peer channel signconfigtx -f channel-artifacts/org3_update_in_envelope.pb
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051
peer channel update -f channel-artifacts/org3_update_in_envelope.pb -c channel1 -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
docker logs -f peer0.org1.example.com
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org3MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
export CORE_PEER_ADDRESS=localhost:11051
peer channel fetch 0 channel-artifacts/channel1.block -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c channel1 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
peer channel join -b channel-artifacts/channel1.block
./network.sh down
./network.sh up createChannel -c channel1
cd addOrg3
./addOrg3.sh up -c channel1
cd ~/fabric-samples/test-network
# Bring everything down (orderer, peers, cas, chaincode containers)
./network.sh down
# Bring it back up with CAs and mychannel
./network.sh up createChannel -c mychannel -ca
cd ~/fabric-samples/test-network
./network.sh deployCC   -ccn secured   -ccp ../asset-transfer-secured-agreement/chaincode-go/   -ccl go   -ccep "OR('Org1MSP.peer','Org2MSP.peer')"   -c mychannel
cd /home/thesis/chaincode/progorder
ls
# if you haven't yet:
go mod tidy
cd ~/fabric-samples/test-network
./network.sh deployCC   -ccn progorder   -ccp /home/thesis/chaincode/progorder   -ccl go   -ccep "OR('Org1MSP.peer','Org2MSP.peer')"   -c mychannel
./network.sh down
./network.sh deployCC -ccn secured -ccp ../asset-transfer-secured-agreement/chaincode-go/ -ccl go -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
./network.sh down
./network.sh up createChannel -c mychannel
./network.sh deployCC -ccn secured -ccp ../asset-transfer-secured-agreement/chaincode-go/ -ccl go -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
cd ~/blockchain-explorer
docker compose down --remove-orphans
export PORT=8080
export EXPLORER_CONFIG_FILE_PATH=$PWD/examples/net1/config.json
export EXPLORER_PROFILE_DIR_PATH=$PWD/examples/net1/connection-profile
export FABRIC_CRYPTO_PATH=$PWD/examples/net1/crypto
docker restart orderer.example.com peer0.org1.example.com peer0.org2.example.com ca_org1 ca_org2 ca_orderer
cd ~/blockchain-explorer
docker compose up -d
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
docker logs --tail=120 explorer.mynetwork.com
# 1) Bring Explorer down
cd ~/blockchain-explorer
docker compose down --remove-orphans
# 2) Tear down Fabric (this wipes containers, channel, and crypto!)
cd ~/fabric-samples/test-network
./network.sh down
# 3) Bring Fabric up, create mychannel, use CAs (so new keys are minted)
./network.sh up createChannel -c mychannel -ca
# 4) Deploy your chaincode (secured)
#   Adjust cc path/lang if yours differs (Go example shown)
./network.sh deployCC   -c mychannel   -ccn secured   -ccp ../asset-transfer-secured-agreement/chaincode-go   -ccl go   -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
# 5) Re-stage fresh crypto for Explorer
cd ~/blockchain-explorer
# ensure folders exist
mkdir -p examples/net1/crypto/org1/admin/{signcerts,keystore}
mkdir -p examples/net1/crypto/org2/admin/{signcerts,keystore}
mkdir -p examples/net1/crypto/peers/peer0.org1.example.com/tls
mkdir -p examples/net1/crypto/peers/peer0.org2.example.com/tls
mkdir -p examples/net1/crypto/orderer
# Org1 admin
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/cert.pem    examples/net1/crypto/org1/admin/signcerts/cert.pem
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/*_sk    examples/net1/crypto/org1/admin/keystore/priv_sk
# Org2 admin
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/signcerts/cert.pem    examples/net1/crypto/org2/admin/signcerts/cert.pem
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore/*_sk    examples/net1/crypto/org2/admin/keystore/priv_sk
# TLS CAs
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt    examples/net1/crypto/peers/peer0.org1.example.com/tls/ca.crt
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt    examples/net1/crypto/peers/peer0.org2.example.com/tls/ca.crt
cp ~/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem    examples/net1/crypto/orderer/tlsca.example.com-cert.pem
# (dev-only) make sure Explorer can read the files
chmod 644 examples/net1/crypto/**/*.pem examples/net1/crypto/**/priv_sk || true
# 6) Start Explorer fresh
export PORT=8080
export EXPLORER_CONFIG_FILE_PATH=$PWD/examples/net1/config.json
export EXPLORER_PROFILE_DIR_PATH=$PWD/examples/net1/connection-profile
export FABRIC_CRYPTO_PATH=$PWD/examples/net1/crypto
docker compose up -d
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
docker logs --tail=120 explorer.mynetwork.com
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
docker logs --tail=120 explorerdb.mynetwork.com
docker logs --tail=120 explorer.mynetwork.com
curl -s http://localhost:8080/api/status | jq .
docker exec -it explorer.mynetwork.com sh -lc   "ls -l /opt/explorer/app/platform/fabric/connection-profile && \
   cat /opt/explorer/app/platform/fabric/config.json && \
   ls -l /tmp/crypto/org1/admin/{signcerts,keystore} && \
   ls -l /tmp/crypto/org2/admin/{signcerts,keystore}"
ls: /tmp/crypto/org1/admin/{signcerts,keystore}: No such file or directory
# 1) Ensure the crypto exists on the HOST (you already have this, just re-check)
ls -l examples/net1/crypto/org1/admin/{signcerts,keystore}       examples/net1/crypto/org2/admin/{signcerts,keystore}       examples/net1/crypto/peers/peer0.org1.example.com/tls/ca.crt       examples/net1/crypto/peers/peer0.org2.example.com/tls/ca.crt       examples/net1/crypto/orderer/ca.crt
# 2) Export the env vars for THIS shell (Compose only sees what's in this shell or in .env)
export PORT=8080
export EXPLORER_CONFIG_FILE_PATH=$PWD/examples/net1/config.json
export EXPLORER_PROFILE_DIR_PATH=$PWD/examples/net1/connection-profile
export FABRIC_CRYPTO_PATH=$PWD/examples/net1/crypto     # <-- critical
# 3) Bring Explorer down and nuke the cached wallet (forces re-import of the NEW admin certs)
docker compose down --remove-orphans
docker volume rm blockchain-explorer_walletstore || true
# 4) Start it again (now the /tmp/crypto mount will be present)
docker compose up -d
# 5) Verify INSIDE the container that the mount exists
docker exec -it explorer.mynetwork.com sh -lc   "ls -l /tmp/crypto/org1/admin/{signcerts,keystore} && \
   ls -l /tmp/crypto/org2/admin/{signcerts,keystore} && \
   ls -l /tmp/crypto/peers/peer0.org1.example.com/tls && \
   ls -l /tmp/crypto/peers/peer0.org2.example.com/tls && \
   ls -l /tmp/crypto/orderer"
# 1) Bring Explorer down
cd ~/blockchain-explorer
docker compose down --remove-orphans
# 2) Tear down Fabric (this wipes containers, channel, and crypto!)
cd ~/fabric-samples/test-network
./network.sh down
# 3) Bring Fabric up, create mychannel, use CAs (so new keys are minted)
./network.sh up createChannel -c mychannel -ca
# 4) Deploy your chaincode (secured)
#   Adjust cc path/lang if yours differs (Go example shown)
./network.sh deployCC   -c mychannel   -ccn secured   -ccp ../asset-transfer-secured-agreement/chaincode-go   -ccl go   -ccep "OR('Org1MSP.peer','Org2MSP.peer')"
# 5) Re-stage fresh crypto for Explorer
cd ~/blockchain-explorer
# ensure folders exist
mkdir -p examples/net1/crypto/org1/admin/{signcerts,keystore}
mkdir -p examples/net1/crypto/org2/admin/{signcerts,keystore}
mkdir -p examples/net1/crypto/peers/peer0.org1.example.com/tls
mkdir -p examples/net1/crypto/peers/peer0.org2.example.com/tls
mkdir -p examples/net1/crypto/orderer
# Org1 admin
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/cert.pem    examples/net1/crypto/org1/admin/signcerts/cert.pem
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/*_sk    examples/net1/crypto/org1/admin/keystore/priv_sk
# Org2 admin
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/signcerts/cert.pem    examples/net1/crypto/org2/admin/signcerts/cert.pem
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore/*_sk    examples/net1/crypto/org2/admin/keystore/priv_sk
# TLS CAs
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt    examples/net1/crypto/peers/peer0.org1.example.com/tls/ca.crt
cp ~/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt    examples/net1/crypto/peers/peer0.org2.example.com/tls/ca.crt
cp ~/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem    examples/net1/crypto/orderer/tlsca.example.com-cert.pem
# (dev-only) make sure Explorer can read the files
chmod 644 examples/net1/crypto/**/*.pem examples/net1/crypto/**/priv_sk || true
# 6) Start Explorer fresh
export PORT=8080
export EXPLORER_CONFIG_FILE_PATH=$PWD/examples/net1/config.json
export EXPLORER_PROFILE_DIR_PATH=$PWD/examples/net1/connection-profile
export FABRIC_CRYPTO_PATH=$PWD/examples/net1/crypto
docker compose up -d
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
docker logs --tail=120 explorer.mynetwork.com
cd fabric-samples/test-network
cd ..
cd fabric-samples/test-network
cd addOrg3
./addOrg3.sh up -c mychannel
