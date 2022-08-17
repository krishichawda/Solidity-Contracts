// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// Voting with Delegation

contract Ballot {
    struct Voter {
        uint256 weight; // The capacity of casting a vote
        bool voted; // true or false depending on whether the person has voted or not
        address delegate; // address of the person delegated to
        uint256 vote; // index of voted proposal
    }

    struct Proposal {
        string name;
        uint256 VoteCount;
    }

    address public chairperson;

    // Stores a voter for each possible address
    mapping(address => Voter) public voters;

    // dynamically sized array of proposal structs
    Proposal[] public proposals;

    constructor(string[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], VoteCount: 0}));
        }
    }

    function giveRightToVote(address voter) external {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(!voters[voter].voted, "The voter has already voted!");

        require(voters[voter].weight == 0);
        voters[voter].weight == 1;
    }

    function delegate(address to) external {
        // assigning reference
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no right to vote");
        require(!sender.voted, "You already voted!");
        require(to != msg.sender, "Self-delegation is disallowed");

        // Forwarding the delegation as long as 'to' is delegated
        // sender -> voter1 -> voter2 -> voter3 -> to

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            require(to != msg.sender, "Found loop in delegation");
        }

        Voter storage delegate_ = voters[to];

        // Voters cannot delegate to accounts that cannot vote.
        require(delegate_.weight >= 1);

        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
            // If the delegate has already voted directly add the no of voted
            proposals[delegate_.vote].VoteCount += sender.weight;
        } else {
            // If the delegate did not vote yet
            // add to the existing wight
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint256 proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].VoteCount += sender.weight;
        // If proposal is out of the range of array then this will automatically revert all changes
    }

    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].VoteCount > winningVoteCount) {
                winningVoteCount = proposals[p].VoteCount;
                winningProposal_ = p;
            }
        }
    }

    // Calls winningProposal() function to get the index
    // of the winner contained in the proposals array and then
    // returns the name of the winner
    function winnerName() external view returns (string memory winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}
