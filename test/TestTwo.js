"use strict";

const TestOne = artifacts.require("./TestToken.sol");
const TestTwo = artifacts.require("./VoteCR.sol");

//From constructor
const candidateOne = "0x436f6361436f6c61"; //CocaCola
const candidateTwo = "0x46616e7461"; //Fanta

//Addresses from Ganache GUI, used as voters and erc20 owners
const ADDRESS1 = "0x627306090abaB3A6e1400e9345bC60c78a8BEf57";
const ADDRESS2 = "0xf17f52151EbEF6C7334FAD080c5704D77216b732";
const ADDRESS3 = "0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef";

/**
 * Address1 secret and choice:
 *  -secret: "0x6669727374536563726574" - firstSecret;
 *  -choice: "0x436f6361436f6c61" - CocaCola
 */ 
const hashFromADDRESS1 = "0xda274219d736998d11c1988d12a8bd93c6ac4492860a9841ccc7a713b6d1de30";

/**
 * Address2 secret and choice:
 *  -secret: "0x7365636f6e64536563726574" - secondSecret;
 *  -choice: "0x436f6361436f6c61" - CocaCola 
 */
const hashFromADDRESS2 = "0x0e05548dee1610da74cfb695bc83943642776a8219c10bacfebdfc182cc0774c";

/**
 * Address3 secret and choice:
 *  -secret: "0x7468697264536563726574" - thirdSecret;
 *  -choice: "0x46616e7461" - Fanta;
 */ 
const hashFromADDRESS3 = "0xbe0be359d3f4b6ea6bff341e90dbb7386ece4a48e860aecdb55ef2f56c7c6d3d";

//Deadline from constructor
const DEADLINE = 10000; //sec in ms

contract("TestToken & Vote contracts", async accounts => {
    it("3 addresses get 10 tokens each one, their balances are checked", async () => {
        let instance = await TestOne.deployed();
        let tokenEmission = await instance.emitTokens;

        //First 3 addresses from Ganache GUI


        //Getting their tokens
        tokenEmission(ADDRESS1, 10);
        tokenEmission(ADDRESS2, 10);
        tokenEmission(ADDRESS3, 10);

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
        let approveMethod = await instance.approve;

        let VoteContract = await TestTwo.deployed();
        
        //Calling approve methods
        approveMethod(VoteContract.address, 10, { from: ADDRESS1});
        approveMethod(VoteContract.address, 10, { from: ADDRESS2});
        approveMethod(VoteContract.address, 10, { from: ADDRESS3});

        //Geting allowance value
        let allowanceAddress1 = await instance.allowance(ADDRESS1, VoteContract.address);
        let allowanceAddress2 = await instance.allowance(ADDRESS2, VoteContract.address);
        let allowanceAddress3 = await instance.allowance(ADDRESS3, VoteContract.address);

        //Testing
        assert.equal(allowanceAddress1.valueOf(), 10);
        assert.equal(allowanceAddress2.valueOf(), 10);
        assert.equal(allowanceAddress3.valueOf(), 10);
    });


    it("Commit votes from 3 addresses", async () => {
        let instance = await TestTwo.deployed();
        let commitMethod = await instance.commitVote;
        let token = await TestOne.deployed();

        commitMethod(hashFromADDRESS1, 10, {from: ADDRESS1});
        commitMethod(hashFromADDRESS2, 10, {from: ADDRESS2});
        commitMethod(hashFromADDRESS3, 10, {from: ADDRESS3});

        let firstCommit = await instance.votersData.call(ADDRESS1);
        let secondCommit = await instance.votersData.call(ADDRESS2);
        let thirdCommit = await instance.votersData.call(ADDRESS3);

        let voteBalance = await token.balanceOf(instance.address);

        assert.equal(firstCommit.voices.valueOf(), 10);
        assert.equal(secondCommit.voices.valueOf(), 10);
        assert.equal(thirdCommit.voices.valueOf(), 10);
        assert.equal(voteBalance.valueOf(), 30);
    });

    it("Reveal from 3 addresses", async () => {
        
        function timeout(ms) {
            return new Promise(resolve => setTimeout(resolve, ms));
        }

        await timeout(DEADLINE+5000);

        let instance = await TestTwo.deployed();

        await instance.revealVote("0x6669727374536563726574", candidateOne, {from: ADDRESS1});
        await instance.revealVote("0x7365636f6e64536563726574", candidateOne, {from: ADDRESS2});
        await instance.revealVote("0x7468697264536563726574", candidateTwo, {from: ADDRESS3});

        let firstVoter = await instance.votersData.call(ADDRESS1);
        let secondVoter = await instance.votersData.call(ADDRESS2);
        let thirdVoter = await instance.votersData.call(ADDRESS3);

        assert.equal(firstVoter.isRevealed, true);
        assert.equal(secondVoter.isRevealed, true);
        assert.equal(thirdVoter.isRevealed, true);
    });

    it("Ending vote event with honoring winners", async () => {
        let instance = await TestTwo.deployed();

        await instance.honorWinners(ADDRESS1, {from: ADDRESS1});
        await instance.honorWinners(ADDRESS2, {from: ADDRESS2});
        await instance.honorWinners(ADDRESS3, {from: ADDRESS3});
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