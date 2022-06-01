# ERC20 on StarkNet

## Introduction

Welcome! This is an automated workshop that will explain how to deploy an ERC20 token on StarkNet and customize it to perform specific functions. The ERC20 standard is described [here](https://docs.openzeppelin.com/contracts/3.x/api/token/erc20)
It is aimed at developers that:

- Understand Cairo syntax
- Understand the ERC20 token standard

This workshop is the third in a series that will cover broad smart contract concepts (writing and deploying ERC20/ERC721, bridging assets, L1 <-> L2 messaging...).  
You can find the previous tutorials here:

- [Introduction to cairo](https://github.com/l-henri/starknet-cairo-101)
- [ERC721](https://github.com/l-henri/starknet-erc721)

This tutorial was written by Florian Charlier ([@trevis_dev](https://twitter.com/trevis_dev)) in collaboration with Henri Lieutaud and Lucas Levy, based on Henri's original [ERC20 101](https://github.com/l-henri/erc20-101) and [ERC20 102](https://github.com/l-henri/erc20-102) tutorials for Solidity. 

Interested in helping writing those? [Reach out](https://twitter.com/HenriLieutaud)!

### Disclaimer

Don't expect any kind of benefit from using this, other than learning a bunch of cool stuff about StarkNet, the first general purpose validity rollup on the Ethereum Mainnet.

StarkNet is still in Alpha. This means that development is ongoing, and the paint is not dry everywhere. Things will get better, and in the meanwhile, we make things work with a bit of duct tape here and there!

### Providing feedback

Once you are done working on this tutorial, your feedback would be greatly appreciated!
**Please fill [this form](https://forms.reform.app/starkware/untitled-form-4/kaes2e) to let us know what we can do to make it better.** And if you struggle to move forward, do let us know! This workshop is meant to be as accessible as possible; we want to know if it's not the case.

Do you have a question? Join our [Discord server](https://discord.gg/YHz7drT3), register and join channel `#tutorials-support`

## Table of contents

- [ERC20 on StarkNet](#erc20-on-starknet)
  - [Introduction](#introduction)
    - [Disclaimer](#disclaimer)
    - [Providing feedback](#providing-feedback)
  - [Table of contents](#table-of-contents)
  - [How to work on this tutorial](#how-to-work-on-this-tutorial)
    - [Before you start](#before-you-start)
    - [Workflow](#workflow)
    - [Checking your progress](#checking-your-progress)
      - [Counting your points](#counting-your-points)
      - [Transaction status](#transaction-status)
      - [Install nile](#install-nile)
        - [With pip](#with-pip)
        - [With docker](#with-docker)
    - [Getting to work](#getting-to-work)
  - [Contract addresses](#contract-addresses)
  - [Points list](#points-list)
    - [Setting up](#setting-up)
  - [Part 1](#part-1)
    - [ERC20 basics](#erc20-basics)
      - [Exercise 1](#exercise-1)
      - [Exercise 2](#exercise-2)
    - [Distributing tokens](#distributing-tokens)
      - [Exercise 3](#exercise-3)
    - [Creating an ICO allow list](#creating-an-ico-allow-list)
      - [Exercises 4, 5 and 6](#exercises-4-5-and-6)
    - [Creating multi tier allow list](#creating-multi-tier-allow-list)
      - [Exercises 7, 8 and 9](#exercises-7-8-and-9)
  - [Part 2](#part-2)
    - [Submissions](#submissions)
    - [Manipulating ERC20 tokens from other contracts](#manipulating-erc20-tokens-from-other-contracts)
      - [Exercise 10](#exercise-10)
    - [Calling another contract from your contract](#calling-another-contract-from-your-contract)
      - [Exercise 11](#exercise-11)
      - [Exercise 12](#exercise-12)
    - [Approve and transferFrom](#approve-and-transferfrom)
      - [Exercise 13](#exercise-13)
      - [Exercise 14](#exercise-14)
      - [Exercise 15](#exercise-15)
    - [Tracking user deposits with a deposit wrapper ERC20](#tracking-user-deposits-with-a-deposit-wrapper-erc20)
      - [Exercise 16 and 17](#exercise-16-and-17)
      - [Exercise 18](#exercise-18)

## How to work on this tutorial

### Before you start

The tutorial has three components:

- An [ERC20 token](contracts/token/ERC20/TUTOERC20.cairo), ticker `ERC20-101`, that is used to keep track of points
- An [evaluator contract](contracts/Evaluator.cairo), that is able to mint and distribute `ERC20-101` points
- A second [ERC20 token](contracts/token/ERC20/DTKERC20.cairo), "Dummy Token", ticker `DTK20`, that is used to make fake payments

It is structured in two parts:

- In the first part (`ERC20`), you will have to deploy an ERC-20 contract.
- In the second part (`Exercise`), you will deploy another contract that will itself have to interact with ERC20 tokens.

### Workflow

To do this tutorial you will have to interact with the `Evaluator.cairo` contract.  
The most convenient way to do this is through Voyager. Please do not forget to connect to your wallet when interacting with the evaluator (see below).
To do an exercise you will have to use the evaluator's contract `submit_[erc20|exercise]_solution` functions to provide the address of the contract to verify for your exercise solution. Once it's done you can call the appropriate function on the evaluator to verify the desired exercise(s).
For example, to solve the first exercise the workflow would be the following:

1. Deploy a smart contract that answers ex2
2. Call `submit_erc20_solution` on the evaluator providing your smart contract address
3. Call `ex2_test_erc20` on the evaluator contract

Your objective is to gather as many ERC20-101 points as possible. Please note :

- The 'transfer' function of ERC20-101 has been disabled to encourage you to finish the tutorial with only one address
- In order to receive points, you will have to reach the calls to the  `validate_and_distribute_points_once` function.
- This repo contains two interfaces ([`IERC20Solution.cairo`](contracts/IERC20Solution.cairo) and [`IExerciceSolution.cairo`](contracts/IERC20Solution.cairo)). For example, for the first part, your ERC20 contract will have to conform to the first interface in order to validate the exercises; that is, your contract needs to implement all the functions described in `IERC20Solution.cairo`.
- **We really recommend that your read the [`Evaluator.cairo`](contracts/Evaluator.cairo) contract in order to fully understand what's expected for each exercise**. A high level description of what is expected for each exercise is provided in this readme.
- The Evaluator contract sometimes needs to make payments to buy your tokens. Make sure he has enough dummy tokens to do so! If not, you should get dummy tokens from the dummy tokens contract and send them to the evaluator.

### Checking your progress

#### Counting your points

Your points will get credited in your wallet; though this may take some time. If you want to monitor your points count in real time, you can also see your balance in voyager!

- Go to the  [ERC20 counter](https://goerli.voyager.online/contract/0x037b0ca3995eb2d79626b6a0eac40fe4ba19ddf73d81423626b44755614b9cee) in voyager, in the "read contract" tab
- Enter your address in decimal in the "balanceOf" function

You can also check your overall progress [here](https://starknet-tutorials.vercel.app)


#### Transaction status

You sent a transaction, and it is shown as "undetected" in voyager? This can mean two things:

- Your transaction is pending, and will be included in a block shortly. It will then be visible in voyager.
- Your transaction was invalid, and will NOT be included in a block (there is no such thing as a failed transaction in StarkNet).

You can (and should) check the status of your transaction with the following URL  [https://alpha4.starknet.io/feeder_gateway/get_transaction_receipt?transactionHash=](https://alpha4.starknet.io/feeder_gateway/get_transaction_receipt?transactionHash=) , where you can append your transaction hash.

#### Install nile

##### With pip

- Set up the environment following [these instructions](https://starknet.io/docs/quickstart.html#quickstart)
- Install [Nile](https://github.com/OpenZeppelin/nile).

##### With docker

- Linux and macos

for mac m1:

```bash
alias nile='docker run --rm -v "$PWD":"$PWD" -w "$PWD" lucaslvy/nile:0.8.0-arm'
```

for amd processors

```bash
alias nile='docker run --rm -v "$PWD":"$PWD" -w "$PWD" lucaslvy/nile:0.8.0-x86'
```

- Windows

```bash
docker run --rm -it -v ${pwd}:/work --workdir /work lucaslvy/0.8.0-x86
```

### Getting to work

- Clone the repo on your machine
- Test that you are able to compile the project

```bash
nile compile
```

- To convert data to felt use the [`utils.py`](utils.py) script

Open Python in interactive mode after running script
  ```bash
  python -i utils.py
  ```
  ```python
  >>> str_to_felt('ERC20-101')
  1278752977803006783537
  ```

## Contract addresses

| Contract code                                                     | Contract on voyager                         |
|-------------------------------------------------------------------| ------------------------------------------- |
| [Points counter ERC20](contracts/token/ERC20/TUTOERC20.cairo)     | [0x037b0ca3995eb2d79626b6a0eac40fe4ba19ddf73d81423626b44755614b9cee](https://goerli.voyager.online/contract/0x037b0ca3995eb2d79626b6a0eac40fe4ba19ddf73d81423626b44755614b9cee) |
| [Evaluator](contracts/Evaluator.cairo)                            | [0x05bf05eece944b360ff0098eb9288e49bd0007e5a9ed80aefcb740e680e67ea4](https://goerli.voyager.online/contract/0x05bf05eece944b360ff0098eb9288e49bd0007e5a9ed80aefcb740e680e67ea4) |
| [Dummy ERC20 token (DTK20)](contracts/token/ERC20/DTKERC20.cairo) | [0x029260ce936efafa6d0042bc59757a653e3f992b97960c1c4f8ccd63b7a90136](https://goerli.voyager.online/contract/0x029260ce936efafa6d0042bc59757a653e3f992b97960c1c4f8ccd63b7a90136) |

## Points list

Today you will deploy your own ERC20 token on StarkNet!

### Setting up

- Create a git repository and share it with the teacher.
- Set up your environment (2 pts). Note that it requires Python 3.7+.
These points will be attributed manually if you do not manage to have your contract interact with the evaluator, or automatically in the first question.

## Part 1

| 📝 Submissions for this part are given to the Evaluator by calling `submit_erc20_solution()` 📝 <br/>(*NOT `submit_exercise_solution()`*)|
|--------------------------------------------------------------------------------------------------------------------------------------------|

### ERC20 basics

#### Exercise 1

- Call `ex1_assign_rank()` in the evaluator contract to receive a random ticker for your ERC20 token, as well as an initial token supply (1 pt). You can read your assigned ticker and supply in [`Evaluator.cairo`](https://goerli.voyager.online/contract/0x05bf05eece944b360ff0098eb9288e49bd0007e5a9ed80aefcb740e680e67ea4) by calling getters `read_ticker()` and `read_supply()`

- Create an ERC20 token contract with the proper ticker and supply (2 pts)
- Deploy it to the Goerli-alpha testnet (1 pts)
- Call `submit_erc20_solution()` in the Evaluator to configure the contract you want evaluated (2pts) (Previous 3 points for the ERC20 and the deployment are also attributed at that step)

#### Exercise 2

- Call `ex2_test_erc20()` in the evaluator to check ticker and supply and receive your points (2 pts)

The total amount of points to collect from completing all exercises up to this point is : 8 points

### Distributing tokens

#### Exercise 3

- Create a `get_tokens()` function in your contract, deploy it, and call the `ex3_test_get_token()` function that distributes tokens to the caller (2 pts).
- `get_tokens()` should mint the caller some of your token. It should return the exact amount it sends so the Evaluator can check that the increase of balance and the amount sent corresponds.

The total amount of points to collect from completing all exercises up to this point is : 10 points

### Creating an ICO allow list

#### Exercises 4, 5 and 6

- Create a customer allow listing function. Only allow listed users should be able to call `get_tokens()`.
- Create a function `request_allowlist()` that the evaluator will call during the exercise check to be allowed to get tokens.
- Create a function `allowlist_level()` that can be called by anyone to know whether an account is allowed to get tokens.
- Call `ex4_5_6_test_fencing()` in the evaluator to show
  - It can't get tokens using `get_tokens()` (1 pt)
  - It can call `request_allowlist()` and have confirmation that it went through (1 pt)
  - It can then get tokens using the same `get_tokens()` (2 pt)

The total amount of points to collect from completing all exercises up to this point is : 14 points

### Creating multi tier allow list

#### Exercises 7, 8 and 9

- Create a customer multi tier listing function. Only allow listed users should be able to call `get_token()`; and customers should receive a different amount of tokens based on their level
- Create a function `request_allowlist_level()` that the evaluator will call during the exercise check to be allowed to get tokens at a certain tier level
- Modify the function `allowlist_level()` so that it returns the allowed level of accounts.
- Call `ex7_8_9_test_fencing_levels()` in the evaluator to show
  - It can't get tokens using `get_tokens()` (1 pt)
  - It can call `request_allowlist_level(1)` , then call `get_tokens()` and get N tokens (2 pt)
  - It can call `request_allowlist_level(2)` , then call `get_tokens()` and get > N tokens (2 pt)

The total amount of points to collect from completing all exercises up to this point is : 19 points

## Part 2

### Submissions

| ❗Submissions for this part are given to the Evaluator by calling `submit_exercise_solution()`❗<br/>(instead of `submit_erc20_solution()`)|
|--------------------------------------------------------------------------------------------------------------------------------------------|

### Manipulating ERC20 tokens from other contracts

#### Exercise 10

- Manually claim tokens on the predeployed claimable ERC20 (DTK tokens) (1 pts)
- Claim your points by calling `ex10_claimed_tokens()` in the evaluator (1 pts)

The total amount of points to collect from completing all exercises up to this point is : 21 points

### Calling another contract from your contract

#### Exercise 11

- Create a contract `ExerciseSolution` that:
  - Can claim and hold DTK tokens on behalf of the calling address
  - Keeps track of addresses who claimed tokens, and how much
  - Implements a `tokens_in_custody` function to show these claimed amounts
- Deploy `ExerciseSolution` and submit it to the evaluator with `submit_exercise_solution()`.
- Call `ex11_claimed_from_contract()` in the evaluator to prove your code works (3 pts)

#### Exercise 12

- Create a function `withdraw_all_tokens()` in `ExerciseSolution` to withdraw the claimed tokens from the `ExerciseSolution` to the address that initially claimed them
- Call `ex12_withdraw_from_contract()` in the evaluator to prove your code works (2 pts)

The total amount of points to collect from completing all exercises up to this point is : 26 points

### Approve and transferFrom

#### Exercise 13get_tokens() should send the caller some of your tokens. It should return the exact amount it sends so the Evaluator can check that the increase of balance and the amount sent corresponds.


- Use ERC20 function to allow your contract to manipulate your DTKs. Call `ex13_approved_exercise_solution()` to claim points (1 pts)

#### Exercise 14

- Use ERC20 to revoke this authorization. Call `ex14_revoked_exercise_solution()` to claim points (1 pts)

#### Exercise 15

- Create a function `deposit_tokens()` through which a user can deposit DTKs in `ExerciseSolution`, using `transferFrom`
- Call `ex15_deposit_tokens` in the evaluator to prove your code works (2 pts)

The total amount of points to collect from completing all exercises up to this point is : 30 points

### Tracking user deposits with a deposit wrapper ERC20

#### Exercise 16 and 17

- Create and deploy a new ERC20 `ExerciseSolutionToken` to track user deposit. This ERC20 should be mintable and mint authorization given to `ExerciseSolution`
- Deploy `ExerciseSolutionToken` and make sure that `ExerciseSolution` knows its address
- Update the deposit function on `ExerciseSolution` so that user balances are tokenized: when a deposit is made in `ExerciseSolution`, tokens are minted in `ExerciseSolutionToken` and transferred to the address depositing
- Call `ex16_17_deposit_and_mint` in the evaluator to prove your code works (4 pts)

#### Exercise 18

- Update the `ExerciseSolution` withdraw function so that it uses `transferFrom()` in `ExerciseSolutionToken`, burns these tokens, and returns the DTKs
- Call `ex18_withdraw_and_burn` in the evaluator to prove your code works (2 pts)

The total amount of points to collect from completing all exercises up to this point is : 36 points

#### The end?

Congratulations on reaching the end of the tutorial!

As new exercises could be added, there might be additional points to collect in the future, though. Who knows?
