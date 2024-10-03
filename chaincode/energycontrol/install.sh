export CHANNEL_NAME=marketplace
export CHAINCODE_NAME=energycontrol
export CHAINCODE_VERSION=1
export CC_RUNTIME_LANGUAGE=golang
export CC_SRC_PATH="../../../chaincode/$CHAINCODE_NAME/"
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/etsi.com/orderers/orderer.etsi.com/msp/tlscacerts/tlsca.etsi.com-cert.pem


#Descarga dependencias
#export FABRIC_CFG_PATH=$PWD/configtx
#pushd ../chaincode/$CHAINCODE_NAME
#GO111MODULE=on go mod vendor
#popd



#Empaqueta el chaincode
peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION} >&log.txt

#peer lifecycle chaincode install example
#first peer peer0.buyer.etsi.com
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz 

#Actualizar este  valor con el que obtengan al empaquetar el chaincode: energycontrol_1:a1c05f648dd24bd94128913d73486644ad6c351f19c429c4c661444039688299
export CC_PACKAGEID=367a1c05f648dd24bd94128913d73486644ad6c351f19c429c4c661444039688299

# peer0.seller
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/seller.etsi.com/users/Admin@seller.etsi.com/msp CORE_PEER_ADDRESS=peer0.seller.etsi.com:7051 CORE_PEER_LOCALMSPID="SellerMSP" CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/seller.etsi.com/peers/peer0.seller.etsi.com/tls/ca.crt peer lifecycle chaincode install  ${CHAINCODE_NAME}.tar.gz

# peer0.client
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/client.etsi.com/users/Admin@client.etsi.com/msp CORE_PEER_ADDRESS=peer0.client.etsi.com:7051 CORE_PEER_LOCALMSPID="ClientMSP" CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/client.etsi.com/peers/peer0.client.etsi.com/tls/ca.crt peer lifecycle chaincode install  ${CHAINCODE_NAME}.tar.gz



#Endorsement policy for lifecycle chaincode 

peer lifecycle chaincode approveformyorg --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence 1 --waitForEvent --signature-policy "OR ('BuyerMSP.peer','ClientMSP.peer')" --package-id energycontrol_1:$CC_PACKAGEID

#Commit  the chaincode  for Buyer
 peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence 1 --signature-policy "OR ('BuyerMSP.peer','ClientMSP.peer')" --output json
 
 
 #commit chaincode FAILURE
peer lifecycle chaincode commit -o orderer.etsi.com:7050 --tls --cafile $ORDERER_CA  --peerAddresses peer0.buyer.etsi.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/buyer.etsi.com/peers/peer0.buyer.etsi.com/tls/ca.crt --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence 1 --signature-policy "OR ('BuyerMSP.peer','ClientMSP.peer')"

#2020-09-03 17:39:05.756 UTC [chaincodeCmd] ClientWait -> INFO 046 txid [453ed408b77c198d7159904c94b8d44b4d7633273f200bafc87c5419901883c2] committed with status (ENDORSEMENT_POLICY_FAILURE) at peer0.buyer.etsi.com:7051
#Error: transaction invalidated with status (ENDORSEMENT_POLICY_FAILURE)



#Let Client approve the chaincode package.
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/client.etsi.com/users/Admin@client.etsi.com/msp  CORE_PEER_ADDRESS=peer0.client.etsi.com:7051  CORE_PEER_LOCALMSPID="ClientMSP"  CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/client.etsi.com/peers/peer0.client.etsi.com/tls/ca.crt  peer lifecycle chaincode approveformyorg --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/etsi.com/orderers/orderer.etsi.com/msp/tlscacerts/tlsca.etsi.com-cert.pem --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence 1 --waitForEvent --signature-policy "OR ('BuyerMSP.peer','ClientMSP.peer')" --package-id energycontrol_1:$CC_PACKAGEID


#check the chaincode commit 
 peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence 1 --signature-policy "OR ('BuyerMSP.peer','ClientMSP.peer')" --output json
 
 #commit chaincode SUCCESS
 #Now commit chaincode. Note that we need to specify peerAddresses of both Buyer and Client (and their CA as TLS is enabled).
peer lifecycle chaincode commit -o orderer.etsi.com:7050 --tls --cafile $ORDERER_CA --peerAddresses peer0.buyer.etsi.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/buyer.etsi.com/peers/peer0.buyer.etsi.com/tls/ca.crt --peerAddresses peer0.client.etsi.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/client.etsi.com/peers/peer0.client.etsi.com/tls/ca.crt --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence 1 --signature-policy "OR ('BuyerMSP.peer','ClientMSP.peer')"

#check the status of chaincode commit
peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --output json



############################################################################
#chaincode is committed and useable in the fabric network
#INIT LEDGER
#peer chaincode invoke -o orderer.etsi.com:7050 --tls --cafile $ORDERER_CA -C  $CHANNEL_NAME  -n $CHAINCODE_NAME -c '{"Args":["InitLedger"]}'
#Buyer invokes set() with key “car01” and value “........”.
peer chaincode invoke -o orderer.etsi.com:7050 --tls --cafile $ORDERER_CA -C  $CHANNEL_NAME  -n $CHAINCODE_NAME -c '{"Args":["Set","did:3","ricardo","banana"]}'

#check the value of key “car01”
peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"Args":["Query","did:3"]}'



#ERROR CASE Seller invoke CreateCar().
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/seller.etsi.com/users/Admin@seller.etsi.com/msp  CORE_PEER_ADDRESS=peer0.seller.etsi.com:7051 CORE_PEER_LOCALMSPID="SellerMSP" CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/seller.etsi.com/peers/peer0.seller.etsi.com/tls/ca.crt  peer chaincode invoke -o orderer.etsi.com:7050 --tls --cafile $ORDERER_CA -C  $CHANNEL_NAME  -n $CHAINCODE_NAME -c '{"Args":["Set","did:4","marianela","avacado"]}'