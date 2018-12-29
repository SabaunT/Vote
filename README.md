Vote
=====

This is a Vote contract that allows you to establish election event with it's period, candidate list using ERC20 tokens as voices. 

Some crucial features
-------------------
There are some features that should be described before using this "project".  
  
Token contract which is `TestToken.sol` follows ERC20 standart, but minting and burning methods do not check if they were called by the contract owner. There is an `owner` modifier, but it is documented. That was done to make tests easier. Actually there aren't any `require` and checks, because it's a test erc20. It is assumed, that for voting will be used another, secure erc20 token contract.
  
Concerning Vote contract it should be mentioned that `uint votingDeadline` stores deadline in seconds. That was done due to the same reason that was mentioned previously. In order to use the contract on your personal purposes I strongly recomend to change `seconds` in `constructor` function. And of course `timeLimit` param in migration `.js` file should be chanched too.  
  
Tests were made to check if the contract and its methods behave like they should. So, tests require: 
1. Minting tokens for 3 addresses, stated before tests (they were taken from Ganache GUI. You can access them with `accounts[i]` too)
2. Setting allowance for the Vote contract;
3. Registering the addresses in the Vote contract and voting for the choosen candidate;
4. Ending vote event with finding a winner and rewarding those who gave voices for a winner with losers tokens. A Rewards is given to a winner in accordance with his voice - token stake in a winning group.

Commit-reveal contract
-----------------------
You can test a `VoteCR.sol` contract, which uses commit - reveal mechanism. Almost all the methods are the same. The main difference between these contracts is that each voter should check if he won, because `Vote.sol` required one voter to send Tx to the `honorWinners()` method to **honor** winners.

The mechanism of getting hex, concatenated secret and candidate values is described below.

```solidity

pragma solidity ^0.5.0;

contract Test{

    function getConcatenatedValue(bytes32 _secret, bytes32 _candidate) public pure returns (bytes memory){
        bytes memory a = abi.encodePacked(_secret, _candidate);
        return a;
    }
    
    function getHash(bytes32 _secret, bytes32 _candidate) public pure returns (bytes32) {
        bytes memory a = abi.encodePacked(_secret, _candidate);
        return keccak256(a);
    }
}
```


Requirements
-------------
1. Truffle - better the latest (v5.0.0)
2. Solidity v0.5.0 (solc-js)
3. Node v9.11.2
4. Ganache (GUI was used for this)

Test it (run it)
-----------------
Make sure you have Chai and Mocha node modules
1. Ganache GUI (truffle-config should suit ganache settings)
2. `truffle test`
3. Enjoy
