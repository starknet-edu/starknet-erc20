# ERC20 on StarkNet

PLAYERS BEWARE

THIS TUTORIAL IS STILL UNDER DEVELOPMENT. YOU CAN START WORKING ON IT, BUT YOUR BALANCES MAY BE RESET IN THE COMING DAYS.

## Introduction

Welcome! This is an automated workshop that will explain how to deploy an ERC20 token on StarkNet and customize it to perform specific functions.
It is aimed at developers that:

- Understand Cairo syntax
- Understand the ERC20 token standard

This workshop is the third in a series that will cover broad smart contract concepts (writing and deploying ERC20/ERC721, bridging assets, L1 <-> L2 messaging...).
Interested in helping writing those? [Reach out](https://twitter.com/HenriLieutaud)!

### Disclaimer

Don't expect any kind of benefit from using this, other than learning a bunch of cool stuff about StarkNet, the first general purpose validity rollup on the Ethereum Mainnet.

StarkNet is still in Alpha. This means that development is ongoing, and the paint is not dry everywhere. Things will get better, and in the meanwhile, we make things work with a bit of duct tape here and there!

### Providing feedback

Once you are done working on this tutorial, your feedback would be greatly appreciated!
**Please fill [this form](https://forms.reform.app/starkware/untitled-form-4/kaes2e) to let us know what we can do to make it better.**

And if you struggle to move forward, do let us know! This workshop is meant to be as accessible as possible; we want to know if it's not the case.

Do you have a question? Join our [Discord server](https://discord.gg/YHz7drT3), register and join channel #tutorials-support

## How to work on this TD

Will update, simple copy from ERC721 should work

## Points list

Today you will deploy your own ERC20 token on StarkNet!

### Setting up

- Create a git repository and share it with the teacher.
- Set up your environment (2 pts). Note that it requires Python 3.7+.
These points will be attributed manually if you do not manage to have your contract interact with the evaluator, or automatically in the first question.

## Part 1

### ERC20 basics

- Call `ex1_assign_rank()` in the evaluator contract to receive a random ticker for your ERC20 token, as well as an initial token supply (1 pt). You can read your assigned ticker and supply in `Evaluator.cairo` by calling getters `read_ticker()` and `read_supply()`
- Create an ERC20 token contract with the proper ticker and supply (2 pt)
- Deploy it to the Goerli-alpha testnet (1 pts)
- Call `submit_erc20_solution()` in the Evaluator to configure the contract you want evaluated (Previous 5 points are attributed at that step)
- Call `ex2_test_erc20()` in the evaluator to check ticker and supply and receive your points (2 pts)

The total amount of points to collect from completing all exercises up to this point is : 8 points

### Distributing tokens

- Create a `get_tokens()` function in your contract, deploy it, and call the `ex3_test_get_token()` function that distributes token to the caller (2 pts).
- `get_tokens()` should return the amount of token distributed

The total amount of points to collect from completing all exercises up to this point is : 10 points

### Creating an ICO allow list

- Create a customer allow listing function. Only allow listed users should be able to call `get_tokens()`.
- Create a function `request_allowlist()` that the evaluator will call during the exercise check to be allowed to get tokens.
- Create a function `allowlist_level()` that can be called by anyone to know whether an account is allowed to get tokens.
- Call `ex4_5_6_test_fencing()` in the evaluator to show
  - It can't get tokens using `get_tokens()` (1 pt)
  - It can call `request_allowlist()` and have confirmation that it went through (1 pt)
  - It can then get tokens using the same `get_tokens()` (2 pt)

The total amount of points to collect from completing all exercises up to this point is : 14 points

### Creating multi tier allow list

- Create a customer multi tier listing function. Only allow listed users should be able to call `get_token()`; and customers should receive a different amount of token based on their level
- Create a function `request_allowlist_level()` that the evaluator will call during the exercise check to be allowed to get tokens at a certain tier level
- Modify the function `allowlist_level()` so that it returns the allowed level of accounts.
- Call `ex7_8_9_test_fencing_levels()` in the evaluator to show
  - It can't get tokens using `get_tokens()` (1 pt)
  - It can call `request_allowlist_level(1)` , then call `get_tokens()` and get N tokens (2 pt)
  - It can call `request_allowlist_level(2)` , then call `get_tokens()` and get > N tokens (2 pt)

The total amount of points to collect from completing all exercises up to this point is : 19 points

## Part 2

### Submissions

Submissions for this part are given by calling `submit_exercise_solution()` in the Evaluator, as explained below.

### Manipulating ERC20 tokens from other contracts

- Manually claim tokens on the predeployed claimable ERC20 (DTK-20 tokens) (1 pts)
- Claim your points by calling `ex10_claimed_tokens()` in the evaluator (1 pts)

The total amount of points to collect from completing all exercises up to this point is : 21 points

### Calling another contract from your contract

- Create a contract `ExerciseSolution` that can claim DTK-20 tokens. Keep track of addresses who claimed tokens through `ExerciseSolution` , and how much. This amount should be visible by calling `tokens_in_custody()` on `ExerciseSolution`.
- Deploy ExerciseSolution and submit it to the evaluator with `submit_exercise_solution()`.
- Call `ex11_claimed_from_contract()` in the evaluator to prove your code works (3 pts)
- Create a function `withdraw_all_tokens()` in `ExerciseSolution` to withdraw the claimed tokens from the `ExerciseSolution` to the address that initially claimed them.
- Call `ex12_withdraw_from_contract()` in the evaluator to prove your code works (2 pts)

The total amount of points to collect from completing all exercises up to this point is : 26 points

### Approve and transferFrom

- Use ERC20 function to allow your contract to manipulate your DTKs. Call `ex13_approved_exercise_solution()` to claim points (1 pts)
- Use ERC20 to revoke this authorization. Call `ex14_revoked_exercise_solution()` to claim points (1 pts)
- Create a function `deposit_tokens()` through which a user can deposit DTKs in ExerciseSolution, using `transferFrom()`
- Call `ex15_deposit_tokens` in the evaluator to prove your code works (2 pts)

The total amount of points to collect from completing all exercises up to this point is : 30 points

### Tracking user deposits with a deposit wrapper ERC20

- Create and deploy a new ERC20 `ExerciseSolutionToken` to track user deposit. This ERC20 should be mintable and mint authorization given to ExerciseSolution.
- Deploy `ExerciseSolutionToken` and make sure that `ExerciseSolution` knows its address.
- Update the deposit function on `ExerciseSolution` so that user balances are tokenized. When a deposit is made in `ExerciseSolution`, tokens are minted in `ExerciseSolutionToken` and transferred to the address depositing.
- Call `ex16_17_deposit_and_mint` in the evaluator to prove your code works (4 pts)
- Update the `ExerciseSolution` withdraw function so that it uses `transferFrom()` in `ExerciseSolutionToken`, burns these tokens, and returns the DTKs.
- Call `ex18_withdraw_and_burn` in the evaluator to prove your code works (2 pts)

The total amount of points to collect from completing all exercises up to this point is : 36 points

## Exercises & Contract addresses

To be updated after deployment
​
​
