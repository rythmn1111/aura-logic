// esp-blink-spawn.mjs
import { readFileSync } from "fs";
import { connect, createDataItemSigner } from "@permaweb/aoconnect";

async function main() {
  try {
    // Load wallet from JSON
    const wallet = JSON.parse(readFileSync("./wallet.json", "utf-8"));
    const signer = createDataItemSigner(wallet);

    // Connect to AO testnet
    const { spawn } = connect({
      MU_URL: "https://mu.ao-testnet.xyz",
      CU_URL: "https://cu.ao-testnet.xyz",
      GATEWAY_URL: "https://arweave.net"
    });

    // Lua code for AO Process
    const luaCode = `
      Handlers.add("onMessage", { Action = "Ping" }, function(msg)
        -- Ignore messages sent by this handler
        if msg.Tags["Source"] == "esp-blink-handler" then
          return
        end

        print("ESP said: " .. tostring(msg.Data))
        msg:reply({
          Tags = {
            ["Action"] = "Blink",
            ["Target-MQTT-Channel"] = "esp/response",
            ["Source"] = "esp-blink-handler" -- Add a unique identifier
          },
          Data = "blink"
        })
      end)

      return {
        Output = { data = "done" }
      }
    `;

    // Spawn the process
    const processId = await spawn({
      module: "JArYBF-D8q2OmZ4Mok00sD2Y_6SYEQ7Hjx-6VZ_jl3g",
      scheduler: "_GQ33BkPtZrqxA84vM8Zk-N2aO0toNNu_C-l-rawrBA",
      signer,
      tags: [
        { name: "App-Name", value: "esp-blink-test" }
      ],
      data: luaCode
    });

    console.log("✅ Process spawned successfully!");
    console.log("🆔 Process ID:", processId);

  } catch (err) {
    console.error("❌ Failed to spawn process:", err.message);
    console.error(err.stack);
  }
}

main();
