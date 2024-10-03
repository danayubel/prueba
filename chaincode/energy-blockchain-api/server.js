const express = require('express');
const bodyParser = require('body-parser');
const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(bodyParser.json());

// Configuración de Hyperledger Fabric
const ccpPath = path.resolve(__dirname, '../energy-blockchain-api', 'network', 'connection-org1.json');
const walletPath = path.join(process.cwd(), 'wallet');

async function getGateway(user) {
    const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));
    const wallet = await Wallets.newFileSystemWallet(walletPath);

    const gateway = new Gateway();
    await gateway.connect(ccp, { wallet, identity: user, discovery: { enabled: true, asLocalhost: false } });

    return gateway;
}

// Endpoint para inicializar un usuario
app.post('/initUser', async (req, res) => {
    const { userID, balance } = req.body;

    try {
        const gateway = await getGateway('admin');
        const network = await gateway.getNetwork('marketplace');
        const contract = network.getContract('energycontrol');

        await contract.submitTransaction('InitUser', userID, balance.toString());
        await gateway.disconnect();

        res.status(200).send(`User ${userID} initialized with balance ${balance}`);
    } catch (error) {
        console.error(`Failed to initialize user: ${error}`);
        res.status(500).send('Failed to initialize user');
    }
});

// Endpoint para consultar el balance de un usuario
app.get('/balance/:userID', async (req, res) => {
    const { userID } = req.params;

    try {
        const gateway = await getGateway('admin');
        const network = await gateway.getNetwork('marketplace');
        const contract = network.getContract('energycontrol');

        const result = await contract.evaluateTransaction('QueryUserBalance', userID);
        await gateway.disconnect();

        res.status(200).json(JSON.parse(result.toString()));
    } catch (error) {
        console.error(`Failed to query balance: ${error}`);
        res.status(500).send('Failed to query balance');
    }
});

// Endpoint para realizar una transacción de energía
app.post('/transaction', async (req, res) => {
    const { sender, receiver, energyType, kwh } = req.body;

    try {
        const gateway = await getGateway('admin');
        const network = await gateway.getNetwork('marketplace');
        const contract = network.getContract('energycontrol');

        await contract.submitTransaction('SetTransaction', sender, receiver, energyType, kwh.toString());
        await gateway.disconnect();

        res.status(200).send('Transaction successful');
    } catch (error) {
        console.error(`Failed to execute transaction: ${error}`);
        res.status(500).send('Failed to execute transaction');
    }
});

// Inicia el servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
