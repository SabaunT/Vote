pragma solidity ^"0.5.0";

interface TokenAction {
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function balanceOf(address who) external view returns (uint);
}

/**
@title Vote
@author Sabaun Taraki (@SabaunT).
@notice Just a simple ERC20 Voting contract, requires voting only for 1 candidate.
Description: 
 */
contract Vote {

    //called erc20 contract
    TokenAction erc20Communication;

    modifier votingProcesses() {
        require(votingDeadline > now, "voting event is ended");
        _;
    }

    modifier votingEnded() {
        require(votingDeadline <= now, "voting event still lasts");
        _;
    }

    uint votingDeadline;

    //candidates info
    bytes32[] public candidates;
    mapping (bytes32 => uint) public votesForCandidates;

    //voters info
    address[] public votersList;
    struct VoterInfo {
        bool registered;
        bytes32 choice;
        uint voices;
    }
    mapping (address => VoterInfo) public votersData;

    /**
    @dev constructor, defines main state variables.
    @param timeLimit accepts uint number of seconds. Read the description for more details.
    @param erc20Address an address of the erc20 token contract used as a base asset to count voices for candidates.
    @param candidateList an array of candidates, make sure you call the contract passing bytes32 elements to the array.    
     */
    constructor (uint timeLimit, address erc20Address, bytes32[] memory candidateList) public {
        votingDeadline = now + timeLimit * 1 seconds;
        erc20Communication = TokenAction(erc20Address);
        candidates = candidateList;
    }

    /**
    @dev registers voter if unless he registered and if his candidate is valid.
    @param candidate candidate in bytes32 form, checked by "require".
    @return true, if VM processed tx successfully.
     */
    function registerVoter(bytes32 candidate) public votingProcesses returns (bool) {
        require(votersData[msg.sender].registered == false && _validateCandidate(candidate) == true, "you are registered");
        votersList.push(msg.sender);
        votersData[msg.sender] = VoterInfo(true, candidate, 0);
        return true;
    }

    /**
    @dev msg.sender gives his voice for his candidate. ERC20 transferFrom is used to pay for voices.
    @param amount an amount of giving voices for a candidate, should be greater than 0.
    @return true, if VM processed tx successfully.
     */
    function voteForYourCandidate(uint amount) public votingProcesses returns (bool) {
        require(amount > 0 && votersData[msg.sender].registered == true, "incorrect data"); //нужен ли булеан?
        bytes32 candidate = votersData[msg.sender].choice;
        votesForCandidates[candidate] += amount;
        votersData[msg.sender].voices += amount;
        erc20Communication.transferFrom(msg.sender, address(this), amount);
        return true;
    }

    /**
    @dev method which finalize the voting event by honoring winners with losers tokens. Called only after deadline.
    @return winner name
     */
    function honorWinners() public votingEnded returns (bytes32) { 
        bytes32 _winnerName = _findWinner();
        uint winnersPrey = erc20Communication.balanceOf(address(this)) - totalVotesForCandidate(_winnerName);
        for (uint i = 0; i < votersList.length; i++) {
            if (votersData[votersList[i]].choice ==_winnerName) {
                votersData[votersList[i]].voices += (winnersPrey * votersData[votersList[i]].voices)/totalVotesForCandidate(_winnerName);              
            } else {
                votersData[votersList[i]].voices = 0;
            }
        }
        return _winnerName;            
    }

    /**
    @dev gets total votes for the candidate.
    @param candidate *
    @return a number of votes for the candidate.
     */
    function totalVotesForCandidate(bytes32 candidate) public view returns (uint) {
        return votesForCandidates[candidate];
    }

    /**
    @dev an internal method used to validate candidate by checking him in the candidates array.
    @param candidate *
    @return boolean. True if candidate was found, else - false.
     */
    function _validateCandidate(bytes32 candidate) internal view returns (bool) {
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i] == candidate) {
                return true;
            }
        }
        return false;
    }

    /**
    @dev an internal method used by honorWinners method to find a winner.
    @return winner name.
     */
    function _findWinner() internal view votingEnded returns (bytes32) {
        bytes32 winner = "";
        uint maxVotes = 0;
        for (uint i = 0; i < candidates.length; i++) {
            if (votesForCandidates[candidates[i]] > maxVotes) {
                winner = candidates[i];
                maxVotes = votesForCandidates[candidates[i]];
            }
        }
        return winner;
    }
}