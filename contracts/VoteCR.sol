pragma solidity ^0.5.0;

import "./SafeMath.sol";

interface TokenAction {
    function transferFrom(address from, address to, uint value) external returns (bool);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
}

/**
@title Vote
@author Sabaun Taraki (@SabaunT).
@notice Voting contract using ERC20 with the commit - reveal mechanism
Description: 
 */
contract VoteCR {

    using SafeMath for uint;

    //called erc20 contract
    TokenAction erc20Communication;

    modifier isActive() {
        require(votingDeadline > now, "voting event is ended");
        _;
    }

    modifier isEnded() {
        require(votingDeadline <= now, "voting event still lasts");
        _;
    }

    bool isDraw;
    uint maxContractBalance;
    uint votingDeadline;

    //candidates info
    bytes32[] public candidates;
    mapping (bytes32 => uint) public votesForCandidates;

    //voters info
    address[] public votersList;
    struct VoterInfo {
        bool registered;
        bytes32 votersCommit;
        bytes32 revealedCandidate;
        bool isHonored;
        uint voices;
        
    }
    mapping (address => VoterInfo) public votersData;

    event Commited (
        address indexed who,
        string message
    );

    event Revealed (
        address indexed who,
        bytes32 choice
    );

    constructor (uint timeLimit, address erc20Address, bytes32[] memory candidateList) public {
        votingDeadline = now + timeLimit * 1 seconds;
        erc20Communication = TokenAction(erc20Address);
        candidates = candidateList;
    }

    /**
    @dev commit method
    @param _votersCommit is a keccak256 of commiters secret concated with candidates name. 
    @param amount voices you give for a candidate
    @return true if processed successfully
     */
    function commitVote(bytes32 _votersCommit, uint amount) public isActive returns (bool) {
        require(amount > 0 && votersData[msg.sender].registered == false, "you are registered");
        require(erc20Communication.transferFrom(msg.sender, address(this), amount) == true, "invalid condition on ERC20");
        votersList.push(msg.sender);
        votersData[msg.sender] = VoterInfo(true, _votersCommit, "", false, amount);
        maxContractBalance = maxContractBalance.add(amount);
        //erc20Communication.transferFrom(msg.sender, address(this), amount);
        emit Commited(msg.sender, "Commited vote");
        return true;
    }

    /**
    @dev reveal method
    @param _secret bytes32 secret you used while commiting in string form
    @param _candidate bytes32 candidate name you used while commiting in string form
    @return true if processed without errors, otherwise - false
     */
    function revealVote(bytes32 _secret, bytes32 _candidate) public isEnded returns (bool) {
        require(votersData[msg.sender].registered == true && votersData[msg.sender].revealedCandidate == "", "you have already revealed your commit"); 
        require(votersData[msg.sender].votersCommit == keccak256(abi.encodePacked(_secret, _candidate)), "wrong data");
        if (_isValidCandidate(_candidate)) {
            votesForCandidates[_candidate] = votesForCandidates[_candidate].add(votersData[msg.sender].voices);
            votersData[msg.sender].revealedCandidate = _candidate;
            emit Revealed(msg.sender, _candidate);
            return true;
        } else {
            return false;
        }
    }

    function honorWinners(address yourAddress) public isEnded returns (bytes32) {
        require(votersData[msg.sender].isHonored == false, "you have already been honored"); 
        require(votersData[msg.sender].revealedCandidate != "", "you should first reveal your commit"); 
        bytes32 _winnerName = _findWinner();
        require(isDraw == false, "voting event ended up with draw");
        uint winnersPrey = maxContractBalance.sub(totalVotesForCandidate(_winnerName));
        if (votersData[msg.sender].revealedCandidate == _winnerName) {
            votersData[msg.sender].voices = votersData[msg.sender].voices.add((winnersPrey.mul(votersData[msg.sender].voices)).div(totalVotesForCandidate(_winnerName)));
            require(erc20Communication.transfer(yourAddress, votersData[msg.sender].voices) == true, "invalid condition on ERC20");
            votersData[msg.sender].isHonored = true; 
        } else {
            votersData[msg.sender].voices = 0;
        }
        return _winnerName;            
    }

    function totalVotesForCandidate(bytes32 candidate) public view returns (uint) {
        return votesForCandidates[candidate];
    }

    function _isValidCandidate(bytes32 candidate) internal view returns (bool) {
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i] == candidate) {
                return true;
            }
        }
        return false;
    }
    

    function _findWinner() internal isEnded returns (bytes32) {
        bytes32 winner;
        uint maxVotes = 0;
        for (uint i = 0; i < candidates.length; i++) {
            if (votesForCandidates[candidates[i]] >= maxVotes) {
                if (winner != candidates[i]) {
                    winner = candidates[i];
                    maxVotes = votesForCandidates[candidates[i]];
                    isDraw = false;
                } else {
                    isDraw = true;
                }
            }
        }
        return winner;
    }
}