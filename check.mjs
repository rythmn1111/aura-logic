// check-wallet.mjs
import { readFileSync } from 'fs';

try {
  const wallet = JSON.parse(readFileSync('./wallet.json').toString());
  
  console.log("Wallet structure check:");
  console.log("- Has 'kty' property:", 'kty' in wallet);
  console.log("- Has 'n' property:", 'n' in wallet);
  console.log("- Has 'e' property:", 'e' in wallet);
  console.log("- Has 'd' property:", 'd' in wallet);
  console.log("- Has 'p' property:", 'p' in wallet);
  console.log("- Has 'q' property:", 'q' in wallet);
  console.log("- Has 'dp' property:", 'dp' in wallet);
  console.log("- Has 'dq' property:", 'dq' in wallet);
  console.log("- Has 'qi' property:", 'qi' in wallet);
  
  if (
    wallet.kty && wallet.n && wallet.e && wallet.d && 
    wallet.p && wallet.q && wallet.dp && wallet.dq && wallet.qi
  ) {
    console.log("✅ Wallet structure looks valid!");
  } else {
    console.log("❌ Wallet is missing some required properties!");
  }
} catch (error) {
  console.error("Error reading or parsing wallet:", error);
}