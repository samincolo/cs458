/* SPDX-License-Identifier: GNU GENERAL PUBLIC LICENSE */

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "./WeightedPoll.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//interface WeightedPollInterface {
//    function getPoll() external view returns (address pollAddress,
//        string memory pollQuestion,
//        bool isWeighted,
//        bool isPollOpen,
//        uint pollCreationDate,
//        uint pollEndDate,
//        string[] memory pollOptions,
//        uint[] memory pollVotes,
//        uint[] memory pollWeights);
//}

contract PollFactory is Ownable {

    // Records voters' registration timestamps. Useful for knowing how long an address has been a registered voter.
    mapping(address => uint) registrationTimestamps;

    event NewPoll(uint id);

    // Array of deployed polls.
    WeightedPoll[] public polls;

    /*
        Called when the contract is deployed to the blockchain.
    */
    constructor() {
        console.log("PollFactory: Deployed on blockchain with address", address(this));
    }

    /*
        After a poll is deployed, its address is sent to this function to be added
        to the total list of deployed polls, and a NewPoll event is emitted.
    */
    function addPoll(bool _weightVotes, string memory _question, string[] memory _options) public {
        polls.push(new WeightedPoll(address(this), _weightVotes, _question, _options)); // Add address to deployed polls
        uint id = polls.length - 1; // Get index as new size
        console.log("Added poll #", id);
        emit NewPoll(id);
    }

    function votePollById(uint _id, uint8 _optionIndex) public isRegistered validPollId(_id) {
        polls[_id].votePoll(_optionIndex, msg.sender);
    }

    /*
        Retrieves a poll address by its id.
    */
    function getPoll(uint _id) public view validPollId(_id) returns (address pollAddress,
                                                                        string memory pollQuestion,
                                                                        bool isWeighted,
                                                                        bool isPollOpen,
                                                                        uint pollCreationDate,
                                                                        uint pollEndDate,
                                                                        string[] memory pollOptions,
                                                                        uint[] memory pollVotes,
                                                                        uint[] memory pollWeights) {
        return polls[_id].getPoll();
    }

    /*
        Fetches the total number of polls.
    */
    function numPolls() public view returns (uint) {
        return polls.length;
    }

    /*
        Function modifier for ensuring a valid poll id is sent.
    */
    modifier validPollId(uint _id) {
        require(_isValidPollId(_id), "Poll ID is invalid");
        _;
    }

    function _isValidPollId(uint _id) private view returns (bool) {
        return _id < polls.length;
    }

    // -------------- VOTER REGISTRATION FUNCTIONS ------------------

    /*
        Records a registered timestamp for a voter address.
    */
    function registerVoter() public {
        require(!isRegisteredToVote(), "PollFactory.sol: Sender is already registered to vote");
        registrationTimestamps[msg.sender] = block.timestamp;
    }

    /*
        Function modifier for ensuring the msg.sender is a registered voter.
    */
    modifier isRegistered() {
        require(isRegisteredToVote(), "PollFactory.sol: Sender is not a registered voter");
        _;
    }

    /*
        Checks if an address has been registered with a valid timestamp.
    */
    function isRegisteredToVote() public view returns (bool) {
        if (registrationTimestamps[msg.sender] > 0) {
            return true;
        } else {
            return false;
        }
    }

    /*
        Checks if an address has been registered with a valid timestamp.
    */
    function isAddressRegisteredToVote(address _address) public view returns (bool) {
        if (registrationTimestamps[_address] > 0) {
            return true;
        } else {
            return false;
        }
    }

    /*
        Returns the amount of time a user has been registered to vote.
    */
    function registeredVoterFor() public view isRegistered() returns (uint) {
        return (block.timestamp - registrationTimestamps[msg.sender]);
    }

    /*
        Returns the amount of time a user has been registered to vote.
    */
    function addressRegisteredVoterFor(address _address) public view returns (uint) {
        return (block.timestamp - registrationTimestamps[_address]);
    }

    /*
        Returns the beginning time a user has been registered to vote.
    */
    function registeredVoterSince() public view isRegistered() returns (uint) {
        return (registrationTimestamps[msg.sender]);
    }
}
