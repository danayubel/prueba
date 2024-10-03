const { Wallets, X509Identity } = require('fabric-network');
const fs = require('fs');
const path = require('path');

async function importIdentity() {
    const walletPath = path.join(process.cwd(), 'wallet');
    const wallet = await Wallets.newFileSystemWallet(walletPath);

    const adminIdentity = await wallet.get('admin');
    if (adminIdentity) {
        console.log('An identity for the admin user "admin" already exists in the wallet');
        return;
    }

    const certPath = path.join(__dirname, '..', '..', 'etsi-network', 'crypto-config', 'peerOrganizations', 'buyer.etsi.com', 'tlsca', 'tlsca.buyer.etsi.com-cert.pem');
    const keyPath = path.join(__dirname, '..', '..', 'etsi-network', 'crypto-config', 'peerOrganizations', 'buyer.etsi.com', 'users', 'Admin@buyer.etsi.com', 'msp', 'keystore', 'priv_sk');
    const cert = fs.readFileSync(certPath).toString();
    const key = fs.readFileSync(keyPath).toString();

    const identity = {
        credentials: {
            certificate: cert,
            privateKey: key,
        },
        mspId: 'BuyerMSP',
        type: 'X.509',
    };

    await wallet.put('admin', identity);
    console.log('Successfully imported "admin" identity into the wallet');
}

importIdentity();
