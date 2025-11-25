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
