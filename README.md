# ERC20 on StarkNet

Welcome! This is an automated workshop that will explain how to deploy an ERC20 token on StarkNet and customize it to perform specific functions. The ERC20 standard is described [here](https://docs.openzeppelin.com/contracts/3.x/api/token/erc20)
It is aimed at developers that:

- Understand Cairo syntax
- Understand the ERC20 token standard

This tutorial was written by Florian Charlier ([@trevis_dev](https://twitter.com/trevis_dev)) in collaboration with Henri Lieutaud and Lucas Levy, based on Henri's original [ERC20 101](https://github.com/l-henri/erc20-101) and [ERC20 102](https://github.com/l-henri/erc20-102) tutorials for Solidity.

​
​

## Introduction

### Disclaimer

Don't expect any kind of benefit from using this, other than learning a bunch of cool stuff about StarkNet, the first general purpose validity rollup on the Ethereum Mainnnet.
​
StarkNet is still in Alpha. This means that development is ongoing, and the paint is not dry everywhere. Things will get better, and in the meanwhile, we make things work with a bit of duct tape here and there!
​

### How it works

The goal of this tutorial is for you to customize and deploy an ERC20 contract on StarkNet. Your progress will be check by an [evaluator contract](contracts/Evaluator.cairo), deployed on StarkNet, which will grant you points in the form of [ERC20 tokens](contracts/token/ERC20/TUTOERC20.cairo).

Each exercise will require you to add functionality to your ERC20 token.

For each exercise, you will have to write a new version on your contract, deploy it, and submit it to the evaluator for correction.

### Where am I?

This workshop is the third in a series aimed at teaching how to build on StarkNet. Checkout out the following:

| Topic                                              | GitHub repo                                                                            |
| -------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Learn how to read Cairo code                       | [Cairo 101](https://github.com/starknet-edu/starknet-cairo-101)                        |
| Deploy and customize an ERC721 NFT                 | [StarkNet ERC721](https://github.com/starknet-edu/starknet-erc721)                     |
| Deploy and customize an ERC20 token (you are here) | [StarkNet ERC20](https://github.com/starknet-edu/starknet-erc20)                       |
| Build a cross layer application                    | [StarkNet messaging bridge](https://github.com/starknet-edu/starknet-messaging-bridge) |
| Debug your Cairo contracts easily                  | [StarkNet debug](https://github.com/starknet-edu/starknet-debug)                       |
| Design your own account contract                   | [StarkNet account abstraction](https://github.com/starknet-edu/starknet-accounts)      |

### Providing feedback & getting help

Once you are done working on this tutorial, your feedback would be greatly appreciated!

**Please fill out [this form](https://forms.reform.app/starkware/untitled-form-4/kaes2e) to let us know what we can do to make it better.**

​
And if you struggle to move forward, do let us know! This workshop is meant to be as accessible as possible; we want to know if it's not the case.

​
Do you have a question? Join our [Discord server](https://starknet.io/discord), register, and join channel #tutorials-support
​
Are you interested in following online workshops about learning how to dev on StarkNet? [Subscribe here](http://eepurl.com/hFnpQ5)

### Contributing

This project can be made better and will evolve as StarkNet matures. Your contributions are welcome! Here are things that you can do to help:

- Create a branch with a translation to your language
- Correct bugs if you find some
- Add an explanation in the comments of the exercise if you feel it needs more explanation
- Add exercises showcasing your favorite Cairo feature

​

## Getting ready to work

### Step 1 - Clone the repo

```bash
git clone https://github.com/starknet-edu/starknet-erc20
cd starknet-erc20
```

### Step 2 - Set up your environment

There are two ways to set up your environment on StarkNet: a local installation, or using a docker container

- For Mac and Linux users, we recommend either
- For windows users we recommand docker

For a production setup instructions we wrote [this article](https://medium.com/starknet-edu/the-ultimate-starknet-dev-environment-716724aef4a7).

#### Option A - Set up a local python environment

- Set up the environment following [these instructions](https://starknet.io/docs/quickstart.html#quickstart)
- Install [OpenZeppelin's cairo contracts](https://github.com/OpenZeppelin/cairo-contracts).

```bash
pip install openzeppelin-cairo-contracts
```

#### Option B - Use a dockerized environment

- Linux and macos

for mac m1:

```bash
alias cairo='docker run --rm -v "$PWD":"$PWD" -w "$PWD" shardlabs/cairo-cli:latest-arm'
```

for amd processors

```bash
alias cairo='docker run --rm -v "$PWD":"$PWD" -w "$PWD" shardlabs/cairo-cli:latest'
```

- Windows

```bash
docker run --rm -it -v ${pwd}:/work --workdir /work shardlabs/cairo-cli:latest
```

### Step 3 -Test that you are able to compile the project

```bash
starknet-compile contracts/Evaluator.cairo
```

​
​

## Working on the tutorial

### Workflow

To do this tutorial you will have to interact with the [`Evaluator.cairo`](contracts/Evaluator.cairo) contract. To validate an exercise you will have to

- Read the evaluator code to figure out what is expected of your contract
- Customize your contract's code
- Deploy it to StarkNet's testnet. This is done using the CLI.
- Register your exercise for correction, using the `submit_exercise` function on the evaluator. This is done using Voyager.
- Call the relevant function on the evaluator contract to get your exercise corrected and receive your points. This is done using Voyager.

For example to solve the first exercise the workflow would be the following:

`deploy a smart contract that answers ex1` &rarr; `call submit_exercise on the evaluator providing your smart contract address` &rarr; `call ex2_test_erc20 on the evaluator contract`

***Your objective is to gather as many ERC20-101 points as possible.*** Please note :

- The 'transfer' function of ERC20-101 has been disabled to encourage you to finish the tutorial with only one address
- In order to receive points, you will have to reach the calls to the  `validate_and_distribute_points_once` function.
- This repo contains two interfaces ([`IERC20Solution.cairo`](contracts/IERC20Solution.cairo) and [`IExerciseSolution.cairo`](contracts/IERC20Solution.cairo)). For example, for the first part, your ERC20 contract will have to conform to the first interface in order to validate the exercises; that is, your contract needs to implement all the functions described in `IERC20Solution.cairo`.
- **We really recommend that your read the [`Evaluator.cairo`](contracts/Evaluator.cairo) contract in order to fully understand what's expected for each exercise**. A high level description of what is expected for each exercise is provided in this readme.
- The Evaluator contract sometimes needs to make payments to buy your tokens. Make sure he has enough dummy tokens to do so! If not, you should get dummy tokens from the dummy tokens contract and send them to the evaluator.

### Contracts code and addresses

| Contract code                                                     | Contract on voyager                                                                                                                                                           |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Points counter ERC20](contracts/token/ERC20/TUTOERC20.cairo)     | [0x228c0e6db14052a66901df14a9e8493c0711fa571860d9c62b6952997aae58b](https://goerli.voyager.online/contract/0x228c0e6db14052a66901df14a9e8493c0711fa571860d9c62b6952997aae58b) |
| [Evaluator](contracts/Evaluator.cairo)                            | [0x14ece8a1dcdcc5a56f01a987046f2bd8ddfb56bc358da050864ae6da5f71394](https://goerli.voyager.online/contract/0x14ece8a1dcdcc5a56f01a987046f2bd8ddfb56bc358da050864ae6da5f71394) |
| [Dummy ERC20 token (DTK20)](contracts/token/ERC20/DTKERC20.cairo) | [0x66aa72ce2916bbfc654fd18f9c9aaed29a4a678274639a010468a948a5e2a96](https://goerli.voyager.online/contract/0x66aa72ce2916bbfc654fd18f9c9aaed29a4a678274639a010468a948a5e2a96) |

​
​

## Tasks list

Today you will deploy your own ERC20 token on StarkNet!

The tutorial is structured in two parts

- In the first part (exercises 1 to 9), you will have to deploy an ERC-20 contract.
- In the second part (exercises 10 to 18), you will deploy another contract that will itself have to interact with ERC20 tokens.

### Exercise 1 - Deploy an ERC20

- Call [`ex1_assign_rank()`](contracts/Evaluator.cairo#L134) in the evaluator contract to receive a random ticker for your ERC20 token, as well as an initial token supply (1 pt). You can read your assigned ticker and supply through the [evaluator page in voyager](https://goerli.voyager.online/contract/0x14ece8a1dcdcc5a56f01a987046f2bd8ddfb56bc358da050864ae6da5f71394) by calling getters [`read_ticker()`]((contracts/Evaluator.cairo#L93)) and [`read_supply()`](contracts/Evaluator.cairo#L102)
- Create an ERC20 token contract with the proper ticker and supply. You can use [this implementation](https://github.com/OpenZeppelin/cairo-contracts/blob/main/src/openzeppelin/token/erc20/ERC20.cairo) as a base (2 pts)
- Deploy it to the testnet (check the constructor for the needed arguments. Also note that the arguments should be decimals.) (1pt)

```bash
starknet-compile contracts/token/ERC20/ERC20.cairo --output artifacts/ERC20.json
starknet deploy --contract ERC20 --inputs arg1 arg2 arg3 --network alpha-goerli 
```

- Call [`submit_erc20_solution()`](contracts/Evaluator.cairo#L733) in the Evaluator to set the contract you want evaluated (2pts) (Previous 3 points for the ERC20 and the deployment are also attributed at that step)

### Exercise 2 - Verifying your ERC20

- Call [`ex2_test_erc20()`](contracts/Evaluator.cairo#L150) in the evaluator for it to check ticker and supply and attribute your points (2 pts)

### Exercise 3 - Creating a faucet

- Create a `get_tokens()` function in your contract. It should mint some of your token for the caller. It should return the exact amount it mints so that the Evaluator can check that the increase of balance and the amount sent corresponds.
- Deploy your contract and call [`submit_erc20_solution()`](contracts/Evaluator.cairo#L733) in the Evaluator to register it
- Call the [`ex3_test_get_token()`](contracts/Evaluator.cairo#L209)  function that distributes tokens to the caller (2 pts).

### Exercises 4, 5 and 6 - Creating an allow list

- Create a customer allow listing function. Only allow listed users should be able to call `get_tokens()`.
- Create a function `request_allowlist()` that the evaluator will call during the exercise check to be allowed to get tokens.
- Create a function `allowlist_level()` that can be called by anyone to know whether an account is allowed to get tokens.
- Deploy your contract and call [`submit_erc20_solution()`](contracts/Evaluator.cairo#L733) in the Evaluator to register it
- Call [`ex4_5_6_test_fencing()`](contracts/Evaluator.cairo#L231) in the evaluator to show
  - It can't get tokens using `get_tokens()` (1 pt)
  - It can call `request_allowlist()` and have confirmation that it went through (1 pt)
  - It can then get tokens using the same `get_tokens()` (2 pt)

### Exercises 7, 8 and 9 - Creating a multi tier allow list

- Create a customer multi tier listing function. Only allow listed users should be able to call `get_token()`; and customers should receive a different amount of tokens based on their level
- Create a function `request_allowlist_level()` that the evaluator will call during the exercise check to be allowed to get tokens at a certain tier level
- Modify the function `allowlist_level()` so that it returns the allowed level of accounts.
- Deploy your contract and call [`submit_erc20_solution()`](contracts/Evaluator.cairo#L733) in the Evaluator to register it
- Call [`ex7_8_9_test_fencing_levels()`](contracts/Evaluator.cairo#L291) in the evaluator to show
  - It can't get tokens using `get_tokens()` (1 pt)
  - It can call `request_allowlist_level(1)` , then call `get_tokens()` and get N tokens (2 pt)
  - It can call `request_allowlist_level(2)` , then call `get_tokens()` and get > N tokens (2 pt)

### Exercise 10 - Claiming dummy tokens

- Manually claim tokens on the predeployed claimable [ERC20](https://goerli.voyager.online/contract/0x66aa72ce2916bbfc654fd18f9c9aaed29a4a678274639a010468a948a5e2a96) ([DTK tokens](contracts/token/ERC20/DTKERC20.cairo)) (1 pts)
- Claim your points by calling [`ex10_claimed_tokens()`](contracts/Evaluator.cairo#L364) in the evaluator (1 pts)

### Exercise 11 - Calling the faucet from your contract

- Create a contract `ExerciseSolution` that:
  - Can claim and hold DTK tokens on behalf of the calling address
  - Keeps track of addresses who claimed tokens, and how much
  - Implements a `tokens_in_custody` function to show these claimed amounts
- Deploy your contract and call [`submit_exercise_solution()`](contracts/Evaluator.cairo#L754) in the Evaluator to register it
- Call [`ex11_claimed_from_contract()`](contracts/Evaluator.cairo#L383) in the evaluator to prove your code works (3 pts)

### Exercise 12 - Using transferFrom on an ERC20

- Create a function `withdraw_all_tokens()` in `ExerciseSolution` to withdraw the claimed tokens from the `ExerciseSolution` to the address that initially claimed them
- Deploy your contract and call [`submit_exercise_solution()`](contracts/Evaluator.cairo#L754) in the Evaluator to register it
- Call [`ex12_withdraw_from_contract()`](contracts/Evaluator.cairo#L431) in the evaluator to prove your code works (2 pts)

### Exercise 13 - Approve

- Mint some DTK tokens and use voyager to authorize the evaluator to manipulate them
- Call [`ex13_approved_exercise_solution()`](contracts/Evaluator.cairo#L491)  to claim points (1 pts)

### Exercise 14 - Revoking approval

- Use voyager to revoke the previous authorization.
- Call [`ex14_revoked_exercise_solution()`](contracts/Evaluator.cairo#L512)  to claim points (1 pts)

### Exercise 15 - Using transferFrom

- Create a function `deposit_tokens()` in your contract through which a user can deposit DTKs in `ExerciseSolution`, by using the `transferFrom` of DTK
- Deploy your contract and call [`submit_exercise_solution()`](contracts/Evaluator.cairo#L754) in the Evaluator to register it
- Call [`ex15_deposit_tokens`](contracts/Evaluator.cairo#L533) in the evaluator to prove your code works (2 pts)

### Exercise 16 and 17 - Tracking deposits with a wrapping ERC20

- Create and deploy a new ERC20 `ExerciseSolutionToken` to track user deposit. This ERC20 should be mintable and mint authorization given to `ExerciseSolution`
- Deploy `ExerciseSolutionToken` and make sure that `ExerciseSolution` knows its address
- Update the deposit function on `ExerciseSolution` so that user balances are tokenized: when a deposit is made in `ExerciseSolution`, tokens are minted in `ExerciseSolutionToken` and transferred to the address depositing
- Deploy your contract and call [`submit_exercise_solution()`](contracts/Evaluator.cairo#L754) in the Evaluator to register it
- Call [`ex16_17_deposit_and_mint`](contracts/Evaluator.cairo#L591) in the evaluator to prove your code works (4 pts)

### Exercise 18 - Withdrawing tokens and burning wrapped tokens

- Update the `ExerciseSolution` withdraw function so that it uses `transferFrom()` in `ExerciseSolutionToken`, burns these tokens, and returns the DTKs
- Deploy your contract and call [`submit_exercise_solution()`](contracts/Evaluator.cairo#L754) in the Evaluator to register it
- Call [`ex18_withdraw_and_burn`](contracts/Evaluator.cairo#L659) in the evaluator to prove your code works (2 pts)

​
​

## Annex - Useful tools

### Converting data to and from decimal

To convert data to felt use the [`utils.py`](utils.py) script
To open Python in interactive mode after running script

  ```bash
  python -i utils.py
  ```

  ```python
  >>> str_to_felt('ERC20-101')
  1278752977803006783537
  ```

### Checking your progress & counting your points

​
Your points will get credited in your wallet; though this may take some time. If you want to monitor your points count in real time, you can also see your balance in voyager!
​

- Go to the  [ERC20 counter](https://goerli.voyager.online/contract/0x228c0e6db14052a66901df14a9e8493c0711fa571860d9c62b6952997aae58b#readContract)  in voyager, in the "read contract" tab
- Enter your address in decimal in the "balanceOf" function

You can also check your overall progress [here](https://starknet-tutorials.vercel.app)
​

### Transaction status

​
You sent a transaction, and it is shown as "undetected" in voyager? This can mean two things:
​

- Your transaction is pending, and will be included in a block shortly. It will then be visible in voyager.
- Your transaction was invalid, and will NOT be included in a block (there is no such thing as a failed transaction in StarkNet).
​
You can (and should) check the status of your transaction with the following URL  [https://alpha4.starknet.io/feeder_gateway/get_transaction_receipt?transactionHash=](https://alpha4.starknet.io/feeder_gateway/get_transaction_receipt?transactionHash=)  , where you can append your transaction hash.
​

​
