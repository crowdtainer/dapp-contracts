pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../utils/CrowdtainerTest.sol";

contract Handler is Test {

    Crowdtainer crowdtainer;
    address[] participants;

    uint nonce++;

    constructor(address[] _participants, Crowdtainer _crowdtainer) {
        crowdtainer = _crowdtainer;
        participants = _participants;
    }

    modifier useRandomParticipant(uint _participantIndex) {
        address randomParticipant = participants[bound(_participantIndex, 0, participants.length - 1)];
        vm.startPrank(randomParticipant);
        _;
        vm.stopPrank();
    }

    function _randomize(uint256 seed, string memory salt) internal returns (uint256) {
        nonce++;
        return uint256(keccak256(abi.encodePacked(seed, salt)))+nonce;
    }

    function join(uint _seed) useRandomParticipant(_seed) external {

    }

}