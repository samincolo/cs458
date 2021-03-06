
/* SPDX-License-Identifier: GNU GENERAL PUBLIC LICENSE */

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
  Define the interface for the PollFactory contract, allowing us to see if
  a user is registered to vote.
*/
interface PollFactoryInterface {
  function isAddressRegisteredToVote(address _address) external view returns (bool);
  function addPoll(address newPollAddress) external;
  function addressRegisteredVoterFor(address _address) external view returns (uint);
}

contract WeightedPoll is Ownable {

  PollFactoryInterface pollFactoryContract;

  struct Option {
    string option;
    uint256 votes;
    uint256 voteWeight;
  }

  bool      private isOpen;
  bool      private weightVotes; // Should this poll be weighted?
  uint8     private weightRange; // [0, 200]
  string    private question;
  Option[]  private options;
  uint      private creationDate;
  uint      private endDate;
  address[] private voters;

  constructor(address _pfAddress, bool _weightVotes, string memory _question, string[] memory _options) {
    pollFactoryContract = PollFactoryInterface(_pfAddress);
    isOpen    = true;
    weightVotes = _weightVotes;
    weightRange = 100;
    question = _question;
    creationDate = block.timestamp;
    endDate   = 0;

    for (uint i = 0; i < _options.length; i++) {
      console.log("Options at", i, _options[i]);
      options.push(Option(_options[i], 0, 0));
    }

    console.log("WeightedPoll: Deployed on blockchain with address", address(this));
    console.log("WeightedPoll: Using PollFactory address", _pfAddress);
  }

  /*
      Function modifier for ensuring the poll is open.
  */
  modifier pollOpen() {
    require(isOpen, "Poll is closed");
    _;
  }

  /*
      Function modifier for ensuring the poll is open.
  */
  modifier pollClosed() {
    require(!isOpen, "Poll is open");
    _;
  }

  /*
    Disables a poll for voting.
  */
  function closePoll() public onlyOwner pollOpen {
    isOpen  = false;
    endDate = block.timestamp;
  }

  /*
      Enables a poll for voting.
  */
  function openPoll() public onlyOwner pollClosed {
    isOpen  = true;
    endDate = 0;
  }

  /*
      Retrieves a Poll's struct elements. We can't return a struct, so we have to disassemble the structs
      and return their components.
  */
  function getPoll() public view returns (address pollAddress,
                                          string memory pollQuestion,
                                          bool isWeighted,
                                          bool isPollOpen,
                                          uint pollCreationDate,
                                          uint pollEndDate,
                                          string[] memory pollOptions,
                                          uint[] memory pollVotes,
                                          uint[] memory pollWeights) {
    string[] memory optionsStrings = new string[](options.length);
    uint[] memory optionsVotes = new uint[](options.length);
    uint[] memory optionsWeights = new uint[](options.length);
    for (uint i = 0; i < options.length; i++) {
      optionsStrings[i] = options[i].option;
      optionsVotes[i]   = options[i].votes;
      optionsWeights[i] = options[i].voteWeight;
    }

    return (address(this), question, isWeighted, isOpen, creationDate, endDate, optionsStrings, optionsVotes, optionsWeights);
  }

  /*
      Casts a single vote for an option in a poll.
  */
  function votePoll(uint8 _optionIndex, address _address) public pollOpen hasNotAlreadyVoted(_address) {
    console.log("votePoll:", msg.sender, _optionIndex);
    require(_optionIndex < options.length, "Option index is invalid");

    // Get time that a voter has been registered to vote
    uint addressRegisteredTime = pollFactoryContract.addressRegisteredVoterFor(_address);
    voters.push(_address); // Add msg.sender to list of voters
    options[_optionIndex].votes++; // Increment chosen option's vote count
    options[_optionIndex].voteWeight += registeredTimeToVoteWeight(addressRegisteredTime);
  }

  /*
      Turns a time difference into a vote weight between 0 and 100.
      The _time difference variable is measured in seconds.
  */
  function registeredTimeToVoteWeight(uint _time) private pure returns (uint256 weight) {
    if (_time < 1 days) {
      return 10;
    } else if (_time < 1 weeks) {
      return 20;
    } else if (_time < 4 weeks) {
      return 40;
    } else if (_time < 180 days) {
      return 80;
    } else {
      return 100;
    }
  }

  /*
      Counts the votes for each of the options.
  */
  function countVotes() public view returns (uint256[] memory res) {
    uint256[] memory results = new uint[](options.length);
    for (uint i = 0; i < options.length; i++) {
      results[i] = options[i].votes;
    }

    return results;
  }

  /*
      Counts the vote weights for each of the options.
  */
  function countWeights() public view returns (uint256[] memory res) {
    uint256[] memory results = new uint[](options.length);
    for (uint i = 0; i < options.length; i++) {
      results[i] = options[i].voteWeight;
    }

    return results;
  }

  /*
      Function modifier for ensuring the sender has not already voted for the poll.
  */
  modifier hasNotAlreadyVoted(address _address) {
    require(!_hasVotedForPoll(_address), "You've already voted for this poll");
    _;
  }

  /*
      Checks if msg.sender has already voted for a specific poll.
  */
  function _hasVotedForPoll(address _voter) private view returns (bool) {
    for (uint i = 0; i < voters.length; i++) {
      if (voters[i] == _voter) {
        return true;
      }
    }
    return false;
  }

  /*
      Function modifier for ensuring the msg.sender is a registered voter.
  */
  modifier isRegistered() {
    require(pollFactoryContract.isAddressRegisteredToVote(msg.sender), "WeightedPoll.sol: Sender is not a registered voter");
    _;
  }
}

