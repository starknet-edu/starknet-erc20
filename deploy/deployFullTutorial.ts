import { randomTickers, randomSupplies } from "../config/randomVals";
import { PR, ADDRESS, PK } from "./../config/config";
import { readFileSync, writeFile } from "fs";
import {
  ec,
  Account,
  Provider,
  InvokeTransactionReceiptResponse,
} from "starknet";
const { getKeyPair } = ec;

async function main() {
  // Load contracts
  const compiledTutoken = readFileSync("./build/TUTOERC20.json", "utf-8");
  const compiledDTK = readFileSync("./build/DTKERC20.json", "utf-8");
  const compiledEvaluator = readFileSync("./build/Evaluator.json", "utf-8");

  const provider = new Provider({
    sequencer: { baseUrl: "https://alpha4-2.starknet.io" },
  });
  // Get key pair and load account
  const starkPair = getKeyPair(PK);
  // To deploy on other network change the provider
  const acc = new Account(provider, ADDRESS, starkPair);

  // Deploy tutorial token
  const declareTutoken = await acc.declare({
    classHash:
      "0x1b2779de83e0fc7271929d19b1d09fbf23c2da0d10fa058d5ab8a8e1667d11c",
    contract: compiledTutoken,
  });
  await acc.waitForTransaction(declareTutoken.transaction_hash);

  const deployTutoken = await acc.deploy({
    classHash: declareTutoken.class_hash,
    salt: declareTutoken.transaction_hash,
    unique: false,
    constructorCalldata: [
      "1278752977803006783537",
      "1278752977803006783537",
      "0",
      "0",
      ADDRESS,
      ADDRESS,
    ],
  });

  await acc.waitForTransaction(deployTutoken.transaction_hash);
  let tutokenReceipt = (await acc.getTransactionReceipt(
    deployTutoken.transaction_hash
  )) as InvokeTransactionReceiptResponse;
  tutokenReceipt.events = tutokenReceipt.events ?? [];

  const addresses: any = { tutoken: tutokenReceipt.events[1].data[0] };
  // Deploy dummy token

  const declareDtk = await acc.declare({
    classHash:
      "0x2c2f4dd613f6171cef8aaca72903df92702781bbeaebbdba1edcca0e46b0f89",
    contract: compiledDTK,
  });
  await acc.waitForTransaction(declareDtk.transaction_hash);

  const deployDtk = await acc.deploy({
    classHash: declareDtk.class_hash,
    salt: declareDtk.transaction_hash,
    unique: false,
    constructorCalldata: [
      "90997221901889128397906381721202537008",
      "293471990320",
      "100000000000000000000",
      "0",
      ADDRESS,
    ],
  });

  await acc.waitForTransaction(deployDtk.transaction_hash);
  let dtkReceipt = (await acc.getTransactionReceipt(
    deployDtk.transaction_hash
  )) as InvokeTransactionReceiptResponse;
  dtkReceipt.events = dtkReceipt.events ?? [];

  addresses.dtk = dtkReceipt.events[1].data[0];

  // Deploy evaluator
  const declareEva = await acc.declare({
    classHash:
      "0x4b1099247483144d7ff8349a9abba1cb4fdc897adf0568da670bb00a2539276",
    contract: compiledEvaluator,
  });
  await acc.waitForTransaction(declareEva.transaction_hash);

  const deployEvaluator = await acc.deploy({
    classHash: declareEva.class_hash,
    salt: declareEva.transaction_hash,
    unique: false,
    constructorCalldata: [PR, addresses.tutoken, addresses.dtk, "2", ADDRESS],
  });
  await acc.waitForTransaction(deployEvaluator.transaction_hash);

  let evaReceipt = (await acc.getTransactionReceipt(
    deployEvaluator.transaction_hash
  )) as InvokeTransactionReceiptResponse;
  evaReceipt.events = evaReceipt.events ?? [];

  addresses.eva = evaReceipt.events[0].data[0];
  console.log(addresses);
  // Save addresses
  writeFile(
    "./config/addresses.json",
    JSON.stringify(addresses),
    function (err) {
      if (err) throw err;
    }
  );

  await acc.execute([
    {
      contractAddress: addresses.eva,
      entrypoint: "set_random_values",
      calldata: [randomTickers.length, ...randomTickers, "0"],
    },
    {
      contractAddress: addresses.eva,
      entrypoint: "set_random_values",
      calldata: [String(randomSupplies.length), ...randomSupplies, "1"],
    },
    {
      contractAddress: addresses.tutoken,
      entrypoint: "set_teachers",
      calldata: [2, ADDRESS, addresses.eva],
    },
    {
      contractAddress: PR,
      entrypoint: "set_exercise_or_admin",
      calldata: [addresses.eva, 1],
    },
  ]);
}
main();
