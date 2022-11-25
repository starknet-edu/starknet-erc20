import { randomTickers, randomSupplies } from "../config/randomVals";
import { PR, ADDRESS, PK } from "../config/config";
import { readFileSync, writeFile } from "fs";
import {
  defaultProvider,
  ec,
  Account,
  InvokeTransactionReceiptResponse,
} from "starknet";

import addresses from "../config/addresses.json";

const { getKeyPair } = ec;
async function main() {
  const compiledEvaluator = readFileSync(
    "./erc20/compiledContracts/compiled_Evaluator.json",
    "utf-8"
  );

  const starkPair = getKeyPair(PK);
  const acc = new Account(defaultProvider, ADDRESS, starkPair);

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

  writeFile(
    "./config/addresses.json",
    JSON.stringify(addresses),
    function (err) {
      if (err) throw err;
    }
  );
}
main();
