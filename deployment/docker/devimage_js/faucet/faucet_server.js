const http = require("http");
const querystring = require("querystring");
const exec = require("child_process").exec;

const FAUCET_WALLET_NAME = process.env.FAUCET_WALLET_NAME || "a";
const FAUCET_AMOUNT = process.env.FAUCET_AMOUNT || "1000000000";
const DENOM = process.env.DENOM || "ughm";

let faucet_address;

/**
 * Execute a shell command and return it as a Promise.
 * @param cmd {string}
 * @return {Promise<string>}
 */
function execShellCommand(cmd) {
  return new Promise((resolve, reject) => {
    exec(cmd, (error, stdout, stderr) => {
      if (error) {
        console.error("error in execShellCommand", error);
        reject(error);
      } else if (stderr) {
        console.error("stderr in execShellCommand", stderr);
        reject(stderr);
      } else {
        // resolve(JSON.parse(stdout));
        resolve(stdout);
        // resolve(out);
      }
    });
  });
}

/**
 * Command to send coins.
 * @param src_key_name source account key name, default 'a'
 * @param src_address  source account's ghm address
 * @param dest_address destination address
 * @param amount amount to send
 * @returns result of executing the command.
 */
async function send_command(src_key_name, src_address, dest_address, amount) {
  const send_message = `ghmd tx bank send ${src_address} ${dest_address} ${amount}${DENOM} --from ${src_key_name} --gas-prices 0.25ughm --chain-id ghmdev -y`;
  console.log(`send_message: \n ${send_message}`);

  const result = await execShellCommand(send_message);
  return result
}

/**
 * Returns the address for the requested account key.
 * @param key_name faucet account key to use, default 'a'
 * @returns address
 */
async function get_address(key_name) {
  // Already looked up, won't change while running
  if (faucet_address !== undefined) {
    return faucet_address;
  }

  const list_keys = "ghmd keys list";
  const result = await execShellCommand(list_keys);
  const out = result.substring(37,79)
  faucet_address = out

  // for (index in result) {
  //   const key = result[index];
  //   if (key["name"] == key_name) {
  //     console.log(`Found key with address: ${key["address"]}`);
  //     faucet_address = key["address"];
  //     break;
  //   }
  // }

  return faucet_address;
}

// Start the http server
const server = http.createServer();
server.on("request", async (req, res) => {
  try {
    // for root or status, return the configured faucet address and amount sent
    if (req.url === "/" || req.url === "/status") {
      const faucet_address = await get_address(FAUCET_WALLET_NAME);

      if (faucet_address === undefined) {
        console.error(
          `No key account with required name: ${FAUCET_WALLET_NAME}`
        );

        res.writeHead(500, { "Content-Type": "application/json" });
        res.write(
          JSON.stringify({
            error: `No key account with required name: ${FAUCET_WALLET_NAME}`,
          })
        );
        res.end();
        return;
      } else {
        res.writeHead(200, { "Content-Type": "application/json" });
        res.write(
          JSON.stringify({
            faucet_address: faucet_address,
            amount: FAUCET_AMOUNT,
          })
        );
        res.end();
      }
    } else if (req.url.startsWith("/faucet")) {
      // ensure address is present, not necessarily valid checksum
      if (!req.url.startsWith("/faucet?address=")) {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.write(JSON.stringify({ error: "address is required" }));
        res.end();
        return;
      }

      const address = querystring.parse(req.url)["/faucet?address"];
      const faucet_address = await get_address(FAUCET_WALLET_NAME);

      if (faucet_address === undefined) {
        console.error(
          `No key account with required name: ${FAUCET_WALLET_NAME}`
        );

        res.writeHead(500, { "Content-Type": "application/json" });
        res.write(
          JSON.stringify({
            error: `No key account with required name: ${FAUCET_WALLET_NAME}`,
          })
        );
        res.end();
        return;
      } else {
        const result = await send_command(
          FAUCET_WALLET_NAME,
          faucet_address,
          address,
          FAUCET_AMOUNT
        );
        
        txHash = result.split('txhash: ')[1]
        res.writeHead(200, { "Content-Type": "application/json" });
        res.write(JSON.stringify({ txhash: txHash}));
        res.end();
      }
    } else {
      res.end("Invalid Request!");
    }
  } catch (err) {
    res.writeHead(500, { "Content-Type": "application/json" });
    res.write(JSON.stringify({ error: `${err.message}` }));
    res.end();
  }
});

server.listen(5000);

console.log("Secret Faucet is running on port 5000 ...");
