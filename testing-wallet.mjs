// minimal-spawn.mjs
import { readFileSync } from "fs";
import { connect, createDataItemSigner } from "@permaweb/aoconnect";

async function main() {
  try {
    // Load wallet
    console.log("Loading wallet...");
    const wallet = JSON.parse(readFileSync("./wallet.json").toString());
    console.log("Wallet loaded successfully");

    // Create signer
    const signer = createDataItemSigner(wallet);

    // Connect with explicit endpoints
    console.log("Connecting to AO testnet...");
    const { spawn } = connect({
      MU_URL: "https://mu.ao-testnet.xyz",
      CU_URL: "https://cu.ao-testnet.xyz",
      GATEWAY_URL: "https://arweave.net"
    });

    // Minimal Lua code
    const minimalCode = `
      return {
        Output = {
          data = "Hello World"
        }
      }
    `;

    // Spawn with minimal tags
    console.log("Attempting to spawn a minimal process...");
    const processId = await spawn({
      module: "JArYBF-D8q2OmZ4Mok00sD2Y_6SYEQ7Hjx-6VZ_jl3g",
      scheduler: "_GQ33BkPtZrqxA84vM8Zk-N2aO0toNNu_C-l-rawrBA",
      signer: signer,
      tags: [
        { name: "Authority", value: "fcoN_xJeisVsPXA-trzVAuIiqO3ydLQxM-L4XbrQKzY" }
      ],
      data: minimalCode });

    console.log("✅ Process created successfully!");
    console.log("Process ID:", processId);
  } catch (error) {
    console.error("❌ Error creating process:", error);
    
    // Log the full error details
    if (error.response) {
      console.error("Response status:", error.response.status);
      console.error("Response data:", error.response.data);
      console.error("Response headers:", error.response.headers);
    } else if (error.request) {
      console.error("Request was made but no response received");
      console.error(error.request);
    } else {
      console.error("Error details:", error.message);
    }
    
    console.error("Error stack:", error.stack);
  }
}

main();