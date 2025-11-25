import fs from 'fs/promises';
import path from 'path';
import crypto from 'crypto';
import * as grpc from '@grpc/grpc-js';
import { connect, signers } from '@hyperledger/fabric-gateway';
import dotenv from 'dotenv';
dotenv.config();

const {
  CONNECTION_JSON, MSP_ID, CERT_PATH, KEY_DIR, TLS_CERT,
  PEER_ENDPOINT, PEER_HOST_ALIAS, CHANNEL, CC, ASSET_ID
} = process.env;

async function pickFirstFile(dir) {
  const files = await fs.readdir(dir);
  if (!files || files.length === 0) throw new Error(`No files in ${dir}`);
  return path.join(dir, files[0]);
}

async function newGrpcClient() {
  const tlsRootCert = await fs.readFile(TLS_CERT);
  const creds = grpc.credentials.createSsl(tlsRootCert);
  // Ensure the host override matches the peer's TLS cert CN
  const options = {
    'grpc.ssl_target_name_override': PEER_HOST_ALIAS,
    'grpc.default_authority': PEER_HOST_ALIAS
  };
  return new grpc.Client(PEER_ENDPOINT, creds, options);
}

async function newIdentity() {
  const certPem = await fs.readFile(CERT_PATH);
  return { mspId: MSP_ID, credentials: certPem };
}

async function newSigner() {
  const keyPath = await pickFirstFile(KEY_DIR);
  const pkcs8 = await fs.readFile(keyPath);
  const privateKey = crypto.createPrivateKey(pkcs8);
  return signers.newPrivateKeySigner(privateKey);
}

async function main() {
  // --- Connect gateway ---
  const client = await newGrpcClient();
  const identity = await newIdentity();
  const signer = await newSigner();
  const gateway = connect({ client, identity, signer });

  const network = gateway.getNetwork(CHANNEL);
  const contract = network.getContract(CC);

  // Fixed props to match what you used from the CLI
  const props = {
    object_type: 'asset_properties',
    color: 'blue',
    size: 35,
    salt: 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3'
  };

  let assetId = ASSET_ID;

  // 1) Create a new asset if ASSET_ID is empty
  if (!assetId) {
    const publicDesc = 'A new asset for Org1MSP';
    const transientData = { asset_properties: Buffer.from(JSON.stringify(props)) };

    const result = await contract.submit('CreateAsset', {
      arguments: [publicDesc],
      transientData
    });

    assetId = Buffer.isBuffer(result) ? result.toString() : String(result);
    console.log(`[Org1] Created asset: ${assetId}`);
  } else {
    console.log(`[Org1] Using existing asset: ${assetId}`);
  }

  // 2) Read asset
  const asset = await contract.evaluate('ReadAsset', { arguments: [assetId] });
  console.log('[Org1] ReadAsset:', asset.toString());

  // 3) Update public description (owner-only)
  await contract.submit('ChangePublicDescription', {
    arguments: [assetId, 'This asset is for sale']
  });
  console.log('[Org1] Description set to: "This asset is for sale"');

  // 4) Seller agrees to sell (transient price)
  const tradeId = '109f4b3c50d7b0df729d299bc6f8e9ef9066971f';
  const price = 100; // keep 100 to match buyer; change to 110 to force transfer failure
  const sellTransient = {
    asset_price: Buffer.from(JSON.stringify({ asset_id: assetId, trade_id: tradeId, price }))
  };

  await contract.submit('AgreeToSell', {
    arguments: [assetId, 'Org2MSP'],
    transientData: sellTransient
  });
  console.log('[Org1] Agreed to sell at price:', price);

  // 5) Optional: show seller-side price record
  const sales = await contract.evaluate('GetAssetSalesPrice', { arguments: [assetId] });
  console.log('[Org1] Sales price record:', sales.toString());

  // 6) Transfer (will only succeed if buyer agreed to same tradeId+price and verified props)
  await contract.submit('TransferAsset', {
    arguments: [assetId, 'Org2MSP'],
    transientData: sellTransient
  });
  console.log('[Org1] Transfer submitted');

  // 7) Verify new owner
  const after = await contract.evaluate('ReadAsset', { arguments: [assetId] });
  console.log('[Org1] After transfer:', after.toString());

  gateway.close();
  client.close();
}

main().catch((e) => {
  console.error('Org1 error:', e);
  process.exit(1);
});
