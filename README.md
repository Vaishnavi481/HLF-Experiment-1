Hyperledger Fabric – Program Order Experiments

This repository contains the complete code and scripts used to study program order, transaction ordering, and client-side concurrency effects in Hyperledger Fabric.
It extends Fabric’s test-network with custom chaincode and automated clients to analyze:

Single-client sequential transaction ordering

Multi-client concurrent transaction ordering

Per-client program order guarantees

Behavior under endorsement delays

Commit order visualization using Fabric Explorer

This project is part of distributed systems research conducted using Hyperledger Fabric 2.x.

Repository Structure
HLF-Experiment-1/
│
├── chaincodes/
│   ├── secured/           # Secured asset-transfer chaincode (Go)
│   └── progorder/         # Custom chaincode for program-order experiments
│
├── scripts/
│   ├── invoke_log.sh      # Core invoke script with (client_id, seq_no)
│   ├── org1_creator.sh    # Asset creation for Org1
│   ├── org2_creator.sh    # Asset creation for Org2
│   ├── run_single_client.sh
│   ├── run_two_clients.sh
│   ├── run_three_clients.sh
│   ├── run_delayed_client.sh
│   └── export_env.sh      # Sets Fabric peer/orderer env variables
│
├── test-network/          # Fabric test network config (no crypto included)
│   ├── network.sh
│   ├── docker-compose-test-net.yaml
│   ├── connection-org1.json
│   └── connection-org2.json
│
├── explorer-config/       # Hyperledger Explorer configuration (sanitized)
│   ├── config.json
│   └── connection-profile/
│       └── test-network.json
│
└── README.md


Note: All MSP material, crypto-config, keystore files, and private keys are intentionally excluded for security.

Experiment Overview

Hyperledger Fabric ensures per-client program order, meaning:

If a client submits transactions T1, T2, T3 in order, the committed ledger order for that client's transactions must preserve T1 → T2 → T3, even under concurrency.

This repository evaluates whether this holds under:

Single-client sequential execution

50 back-to-back invokes → check ledger ordering

Multi-client concurrency

2 or 3 clients each sending 50 concurrent invokes → check interleaving

Artificial endorsement delays

Odd-numbered transactions are delayed to test Fabric’s reordering behavior.

Prerequisites

Install the following:

Docker & Docker Compose

Hyperledger Fabric binaries (v2.x)

Go 1.20+

jq, curl, bash

Git

Clone the repo:

git clone https://github.com/Vaishnavi481/HLF-Experiment-1.git
cd HLF-Experiment-1

Bringing Up the Fabric Test Network

From the test-network/ folder:

cd test-network
./network.sh down
./network.sh up createChannel -c mychannel -ca


This generates local crypto and starts:

1 orderer

2 peer organizations

A channel mychannel

Crypto material is generated locally and not part of this repository.

Deploying Chaincode
Deploy Secured Chaincode
./network.sh deployCC \
  -ccn secured \
  -ccp ../chaincodes/secured \
  -ccl go \
  -ccep "OR('Org1MSP.peer','Org2MSP.peer')"

Deploy Program-Order Chaincode
./network.sh deployCC \
  -ccn progorder \
  -ccp ../chaincodes/progorder \
  -ccl go \
  -ccep "OR('Org1MSP.peer','Org2MSP.peer')"


This chaincode stores:

(client_id, seq_no) → timestamp, txid


allowing verification of commit order.

Running Experiments
Single Client (50 sequential transactions)
cd test-network
../scripts/run_single_client.sh


Outputs:

client1_single.txt

Expectation:

Ledger order must match 1.1 → 1.2 → ... → 1.50.

Two Clients (Concurrent 50 each)
cd test-network
../scripts/run_two_clients.sh


Outputs:

client1_2clients.txt

client2_2clients.txt

Expectation:

Global order interleaves

But each client’s sequence remains ordered (per-client program order)

Three Clients (Concurrent 50 each)
../scripts/run_three_clients.sh

Delay Experiments (Odd-numbered transactions delayed)
../scripts/run_delayed_client.sh


Tests the effect of endorsement delay on commit order.

Using Hyperledger Explorer (Optional)

Explorer configuration is provided in:

explorer-config/


To use:

Run Explorer Docker deployment

Point paths to your locally generated crypto

Log in at http://localhost:8080

View block/transaction ordering visually

Explorer is especially useful for analyzing commit order of:

(client_id, seq_no)

Expected Results
Experiment	Expected Behavior
Single Client	Perfect sequential ordering
Two Clients	Interleaving allowed, but each client preserves its own order
Three Clients	Same as above
Delay Experiments	Per-client order must still be preserved; delayed transactions commit later but never reorder within client

<img width="2560" height="1164" alt="Screenshot (128)" src="https://github.com/user-attachments/assets/b7b86c71-ed89-4621-857e-1c35b220dc6e" />
These results demonstrate Fabric’s per-client program order guarantee even under concurrency and endorsement delays.
