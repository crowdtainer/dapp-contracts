pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../utils/Vouchers721Test.sol";

contract Handler is Test {

    Vouchers721 vouchers;
    address[] participants;

    Crowdtainer defaultCrowdtainer;
    uint256 defaultCrowdtainerId;

    uint nonce++;

    constructor(
        address[] _participants,
        Vouchers721 _vouchers,
        Crowdtainer _defaultCrowdtainer;
        uint256 _defaultCrowdtainerId;
    ) {
        vouchers = _vouchers;
        participants = _participants;
        defaultCrowdtainer = _defaultCrowdtainer;
        defaultCrowdtainerId = _defaultCrowdtainerId;
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