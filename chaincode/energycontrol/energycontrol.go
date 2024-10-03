package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/v2/contractapi"
)

// SmartContract provides functions for controlling the energy transactions
type SmartContract struct {
	contractapi.Contract
}

// EnergyTransaction describes the details of an energy transaction
type EnergyTransaction struct {
	Sender     string `json:"sender"`
	Receiver   string `json:"receiver"`
	EnergyType string `json:"energyType"`
	Tokens     int    `json:"tokens"`
}

// UserBalance keeps track of the token balance for each user
type UserBalance struct {
	Balance int `json:"balance"`
}

// SetTransaction creates a new energy transaction
func (s *SmartContract) SetTransaction(ctx contractapi.TransactionContextInterface, sender string, receiver string, energyType string, kwh int) error {
	// Calculating the cost in tokens
	tokens := kwh * 2

	// Fetch the balance of the sender
	senderBalanceBytes, err := ctx.GetStub().GetState(sender)
	if err != nil {
		return fmt.Errorf("failed to get sender balance: %s", err.Error())
	}
	if senderBalanceBytes == nil {
		return fmt.Errorf("sender %s does not exist", sender)
	}

	// Unmarshal the balance
	var senderBalance UserBalance
	err = json.Unmarshal(senderBalanceBytes, &senderBalance)
	if err != nil {
		return fmt.Errorf("failed to unmarshal sender balance: %s", err.Error())
	}

	// Check if sender has enough tokens
	if senderBalance.Balance < tokens {
		return fmt.Errorf("sender %s does not have enough tokens", sender)
	}

	// Fetch the balance of the receiver
	receiverBalanceBytes, err := ctx.GetStub().GetState(receiver)
	if err != nil {
		return fmt.Errorf("failed to get receiver balance: %s", err.Error())
	}
	var receiverBalance UserBalance
	if receiverBalanceBytes == nil {
		receiverBalance = UserBalance{Balance: 0}
	} else {
		// Unmarshal the balance
		err = json.Unmarshal(receiverBalanceBytes, &receiverBalance)
		if err != nil {
			return fmt.Errorf("failed to unmarshal receiver balance: %s", err.Error())
		}
	}

	// Update balances
	senderBalance.Balance -= tokens
	receiverBalance.Balance += tokens

	// Marshal and put state for sender
	senderBalanceBytes, err = json.Marshal(senderBalance)
	if err != nil {
		return fmt.Errorf("failed to marshal sender balance: %s", err.Error())
	}
	err = ctx.GetStub().PutState(sender, senderBalanceBytes)
	if err != nil {
		return fmt.Errorf("failed to put state for sender: %s", err.Error())
	}

	// Marshal and put state for receiver
	receiverBalanceBytes, err = json.Marshal(receiverBalance)
	if err != nil {
		return fmt.Errorf("failed to marshal receiver balance: %s", err.Error())
	}
	err = ctx.GetStub().PutState(receiver, receiverBalanceBytes)
	if err != nil {
		return fmt.Errorf("failed to put state for receiver: %s", err.Error())
	}

	// Create the energy transaction
	energyTransaction := EnergyTransaction{
		Sender:     sender,
		Receiver:   receiver,
		EnergyType: energyType,
		Tokens:     tokens,
	}

	energyTransactionBytes, err := json.Marshal(energyTransaction)
	if err != nil {
		return fmt.Errorf("failed to marshal energy transaction: %s", err.Error())
	}

	transactionID := ctx.GetStub().GetTxID()
	err = ctx.GetStub().PutState(transactionID, energyTransactionBytes)
	if err != nil {
		return fmt.Errorf("failed to put state for energy transaction: %s", err.Error())
	}

	return nil
}

// QueryTransaction returns the energy transaction details
func (s *SmartContract) QueryTransaction(ctx contractapi.TransactionContextInterface, transactionID string) (*EnergyTransaction, error) {
	transactionBytes, err := ctx.GetStub().GetState(transactionID)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state. %s", err.Error())
	}
	if transactionBytes == nil {
		return nil, fmt.Errorf("transaction %s does not exist", transactionID)
	}

	var energyTransaction EnergyTransaction
	err = json.Unmarshal(transactionBytes, &energyTransaction)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal transaction. %s", err.Error())
	}

	return &energyTransaction, nil
}

// InitUser initializes a user's balance
func (s *SmartContract) InitUser(ctx contractapi.TransactionContextInterface, userID string, balance int) error {
	userBalance := UserBalance{
		Balance: balance,
	}

	userBalanceBytes, err := json.Marshal(userBalance)
	if err != nil {
		return fmt.Errorf("failed to marshal user balance: %s", err.Error())
	}

	err = ctx.GetStub().PutState(userID, userBalanceBytes)
	if err != nil {
		return fmt.Errorf("failed to put state for user: %s", err.Error())
	}

	return nil
}

// QueryUserBalance returns the balance of a user
func (s *SmartContract) QueryUserBalance(ctx contractapi.TransactionContextInterface, userID string) (*UserBalance, error) {
	userBalanceBytes, err := ctx.GetStub().GetState(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state. %s", err.Error())
	}
	if userBalanceBytes == nil {
		return nil, fmt.Errorf("user %s does not exist", userID)
	}

	var userBalance UserBalance
	err = json.Unmarshal(userBalanceBytes, &userBalance)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal user balance. %s", err.Error())
	}

	return &userBalance, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(new(SmartContract))
	if err != nil {
		fmt.Printf("error creating energy token chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("error starting energy token chaincode: %s", err.Error())
	}
}
