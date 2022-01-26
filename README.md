# ERC20 on StarkNet 

PLAYERS BEWARE

THIS TUTORIAL IS STILL UNDER DEVELOPMENT. YOU CAN START WORKING ON IT, BUT YOUR BALANCES MAY BE RESET IN THE COMING DAYS.

## Introduction
Welcome! This is an automated workshop that will explain how to deploy an ERC20 token on StarkNet and customize it to perform specific functions.
It is aimed at developers that:
- Understand Cairo syntax
- Understand the ERC20 token standard

​
This workshop is the first in a series that will cover broad smart contract concepts (writing and deploying ERC20/ERC721, bridging assets, L1 <-> L2 messaging...). 
Interested in helping writing those? [Reach out](https://twitter.com/HenriLieutaud)!
​

### Disclaimer
​
Don't expect any kind of benefit from using this, other than learning a bunch of cool stuff about StarkNet, the first general purpose validity rollup on the Ethereum Mainnnet.
​
StarkNet is still in Alpha. This means that development is ongoing, and the paint is not dry everywhere. Things will get better, and in the meanwhile, we make things work with a bit of duct tape here and there!
​

### Providing feedback
Once you are done working on this tutorial, your feedback would be greatly appreciated! 
**Please fill [this form](https://forms.reform.app/starkware/untitled-form-4/kaes2e) to let us know what we can do to make it better.** 
​
And if you struggle to move forward, do let us know! This workshop is meant to be as accessible as possible; we want to know if it's not the case.
​
Do you have a question? Join our [Discord server](https://discord.gg/YHz7drT3), register and join channel #tutorials-support
​

## How to work on this TD
Will update, simple copy from ERC721 should work

## Points list
Today you will deploy yur own ERC20 token on StarkNet!
### Setting up
- Create a git repository and share it with the teacher
- Set up your environement (2 pts). 
These points will be attributed manually if you do not manage to have your contract interact with the evaluator, or automatically in the first question.

### ERC20 basics
- Call  `ex1_getTickerAndSupply()` in the evaluator contract to receive a random ticker for your ERC20 token, as well as an initial token supply (1 pt). You can read your assigned ticker and supply in `Evaluator.sol` by calling getters `readTicker()` and `readSupply()`
- Create an ERC20 token contract with the proper ticker and supply (2 pt)
- Deploy it to the Rinkeby testnet (1 pts)
- Call `submitExercice()` in the Evaluator to configure the contract you want evaluated (Previous 5 points are attributed at that step)
- Call `ex2_testErc20TickerAndSupply()` in the evaluator to receive your points (2 pts) 

### Distributing and selling tokens
- Create a `getToken()` function in your contract, deploy it, and call the `ex3_testGetToken()` function that distributes token to the caller (2 pts).
- `getToken()` should return the amount of token distributed

### Creating an ICO allow list
- Create a customer allow listing function. Only allow listed users should be able to call `getToken()`
- Call `ex5_testDenyListing()` in the evaluator to show he can't get tokens using `getToken()` (1 pt)
- Allow the evaluator to get tokens
- Call `ex6_testAllowListing()`in the evaluator to show he can now get tokens `getToken()` (2 pt)

### Creating multi tier allow list
- Create a customer multi tier listing function. Only allow listed users should be able to call `getToken()`; and customers should receive a different amount of token based on their level
- Call `ex7_testDenyListing()` in the evaluator to show he can't get tokens using `getToken()` (1 pt)
- Add the evaluator in the first tier. He should now be able to get N tokens 
- Call `ex8_testTier1Listing()` in the evaluator to show he can now get tokens(2 pt)
- Add the evaluator in the second tier. He should now be able to get 2N tokens
- Call `ex9_testTier2Listing()` in the evaluator to show he can now get more tokens(2 pt)

### Manipulating ERC20 tokens froml within contracts
- Manually claim tokens on the predeployed claimable ERC20 (CTK tokens) (1 pts)
- Claim your points by calling `ex1_claimedPoints()` in the evaluator (1 pts)

### Calling another contract from your contract
- Create a contract `ExerciceSolution` that can claim CTK tokens. Keep track of addresses who claimed tokens through `ExerciceSolution` , and how much. This amount should be visible by calling `tokensInCustody` on `ExerciceSolution` 
- Deploy ExerciceSolution and submit it to the evaluator with  `submitExercice()` (1 pts)
- Call `ex2_claimedFromContract` in the evaluator to prove your code work (2 pts)
- Create a function `withdrawTokens()` in ExerciceSolution to withdraw the claimableTokens from the ExerciceSolution to the address that initially claimed them 
- Call `ex3_withdrawFromContract` in the evaluator to prove your code work (2 pts)

### Approve and transferFrom
- Use ERC20 function to allow your contract to manipulate your CTKs. Call `ex4_approvedExerciceSolution()` to claim points (1 pts) 
- Use ERC20 to revoke this authorization. Call `ex5_revokedExerciceSolution()` to claim points (1 pts)
- Create a function `depositTokens()` through which a user can deposit CTKs in ExerciceSolution, using transferFrom 
- Call `ex6_depositTokens` in the evaluator to prove your code work (2 pts)

### Tracking user deposits with a deposit wrapper ERC20
- Create and deploy a new ERC20 `ExerciceSolutionToken` to track user deposit. This ERC20 should be mintable and mint autorization given to ExerciceSolution. 
- Call `ex7_createERC20` in the evaluator to prove your code work (2 pts)
- Update the deposit function on `ExerciceSolution`  so that user balances are tokenized. When a deposit is made in `ExerciceSolution` , tokens are minted in `ExerciceSolutionToken` and transfered to the address depositing. 
- Call `ex8_depositAndMint` in the evaluator to prove your code work (2 pts)
- Update the `ExerciceSolution`  withdraw function so that it uses transferFrom() in `ExerciceSolutionToken`, burns these tokens, and returns the CTKs 
- Call `ex9_withdrawAndBurn` in the evaluator to prove your code work (2 pts)

## Exercises & Contract addresses 
To be updated after deployment
​
​
