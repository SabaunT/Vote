"use strict";

const TestOne = artifacts.require("./TestToken.sol");
const TestTwo = artifacts.require("./Vote.sol");

//From constructor
const candidateOne = "0x436f6361436f6c61"; //CocaCola
const candidateTwo = "0x46616e7461"; //Fanta

//Addresses from Ganache GUI, used as voters and erc20 owners
const ADDRESS1 = "0x627306090abaB3A6e1400e9345bC60c78a8BEf57";
const ADDRESS2 = "0xf17f52151EbEF6C7334FAD080c5704D77216b732";
const ADDRESS3 = "0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef";

//Deadline from constructor
const DEADLINE = 30000; //sec in ms

contract("TestToken & Vote contracts", async accounts => {
    it("3 addresses get 10 tokens each one, their balances are checked", async () => {
        let instance = await TestOne.deployed();

        //First 3 addresses from Ganache GUI
        //Getting their tokens
        await instance.emitTokens(ADDRESS1, 10);
        await instance.emitTokens(ADDRESS2, 10);
        await instance.emitTokens(ADDRESS3, 10);

        //Calling balance method
        let balanceAddress1 = await instance.balanceOf(ADDRESS1);
        let balanceAddress2 = await instance.balanceOf(ADDRESS2);
        let balanceAddress3 = await instance.balanceOf(ADDRESS3);
        
        //Testing
        assert.equal(balanceAddress1.valueOf(), 10);
        assert.equal(balanceAddress2.valueOf(), 10);
        assert.equal(balanceAddress3.valueOf(), 10);
        
    });

    it("Total supply should be 30", async () => {
        let instance = await TestOne.deployed();
        let totalS = await instance.totalSupply();

        assert.equal(totalS.valueOf(), 30);
    });

    it("Call approve method and set allowance", async () => {
        let instance = await TestOne.deployed();

        let VoteContract = await TestTwo.deployed();
        
        //Calling approve methods
        await instance.approve(VoteContract.address, 10, { from: ADDRESS1});
        await instance.approve(VoteContract.address, 10, { from: ADDRESS2});
        await instance.approve(VoteContract.address, 10, { from: ADDRESS3});

        //Geting allowance value
        let allowanceAddress1 = await instance.allowance(ADDRESS1, VoteContract.address);
        let allowanceAddress2 = await instance.allowance(ADDRESS2, VoteContract.address);
        let allowanceAddress3 = await instance.allowance(ADDRESS3, VoteContract.address);

        //Testing
        assert.equal(allowanceAddress1.valueOf(), 10);
        assert.equal(allowanceAddress2.valueOf(), 10);
        assert.equal(allowanceAddress3.valueOf(), 10);
        
    });

    it("Register & vote from 3 addresses", async () => {
        let instance = await TestTwo.deployed();
       
        //First voter gives his voice
        await instance.registerVoter(candidateOne, { from: ADDRESS1});
        await instance.voteForYourCandidate(10, { from: ADDRESS1});

        //Second voter gives his voice
        await instance.registerVoter(candidateOne, { from: ADDRESS2});
        await instance.voteForYourCandidate(10, { from: ADDRESS2});

        //Third voter gives his voice
        await instance.registerVoter(candidateTwo, { from: ADDRESS3});
        await instance.voteForYourCandidate(10, { from: ADDRESS3});

        let votesForFirstCandidate = await instance.totalVotesForCandidate(candidateOne);
        let votesForSecondCandidate = await instance.totalVotesForCandidate(candidateTwo);

        //Testing
        assert.equal(votesForFirstCandidate.valueOf(), 20);
        assert.equal(votesForSecondCandidate.valueOf(), 10);
    });

    
    it("End voting with a deadline modifer", async () => {

        function timeout(ms) {
            return new Promise(resolve => setTimeout(resolve, ms));
        }

        //called to suit methods modifier
        await timeout(DEADLINE+5000);

        let instance = await TestTwo.deployed();
        await instance.honorWinners();
        //let a = await instance.votersData.call(ADDRESS3);
        //console.log(a.voices.valueOf());
    });

    it("Checking voters voices after processing stake reward", async () => {
        let instance = await TestTwo.deployed();

        let firstVoterVoicesRewarded = await instance.votersData.call(ADDRESS1);
        let secondVoterVoicesRewarded = await instance.votersData.call(ADDRESS2);
        let thirdVoterVoicesRewarded = await instance.votersData.call(ADDRESS3);

        assert.equal(firstVoterVoicesRewarded.voices.valueOf(), 15);
        assert.equal(secondVoterVoicesRewarded.voices.valueOf(), 15);
        assert.equal(thirdVoterVoicesRewarded.voices.valueOf(), 0);
    });
    
    it("Checking voters balances on ERC20 contract", async () => {
        let instance = await TestOne.deployed();

        let balanceAddress1 = await instance.balanceOf(ADDRESS1);
        let balanceAddress2 = await instance.balanceOf(ADDRESS2);
        let balanceAddress3 = await instance.balanceOf(ADDRESS3);

        assert.equal(balanceAddress1.valueOf(), 15);
        assert.equal(balanceAddress2.valueOf(), 15);
        assert.equal(balanceAddress3.valueOf(), 0);
    });
});
