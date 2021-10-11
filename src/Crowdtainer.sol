// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

library Errors {
    error ZeroAddress();
    error CallerNotAllowed(address expected, address actual);
}

abstract contract WithModifiers {
    /**
     * @dev Throws if called by any account other than the deployer.
     */
    modifier onlyAddress(address requiredAddress) {
        if (requiredAddress != msg.sender)
            revert Errors.CallerNotAllowed({
                expected: msg.sender,
                actual: requiredAddress
            });
        _;
    }
}

contract Crowdtainer is WithModifiers {
    // address used when deploying this contract.
    address public mDeployer;
    string public receivedMessage;

    event CrowdtainerCreated(address indexed deployer);
    event DummyFunctionCalledWith(string message);

    /**
     * @dev Initializes a Crowdtainer.
     */
    constructor() {
        if (msg.sender == address(0)) revert Errors.ZeroAddress(); // dev: Constructor invoked with address(0)
        mDeployer = msg.sender;

        emit CrowdtainerCreated(mDeployer);
    }

    function dummyFunction(string memory message)
        public
        onlyAddress(mDeployer)
    {
        receivedMessage = message;
        emit DummyFunctionCalledWith({message: message});
    }
}
