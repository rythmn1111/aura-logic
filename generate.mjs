// generate-wallet.mjs
import { writeFileSync } from 'fs';
import Arweave from 'arweave';

const arweave = Arweave.init({
  host: 'arweave.net',
  port: 443,
  protocol: 'https'
});

async function generateWallet() {
  try {
    // Generate a new wallet key
    const key = await arweave.wallets.generate();
    
    // Save the key to file
    writeFileSync('./wallet.json', JSON.stringify(key));
    
    // Get the wallet address
    const address = await arweave.wallets.jwkToAddress(key);
    console.log('Wallet generated successfully!');
    console.log('Wallet address:', address);
    console.log('Wallet saved to wallet.json');
  } catch (error) {
    console.error('Error generating wallet:', error);
  }
}

generateWallet();