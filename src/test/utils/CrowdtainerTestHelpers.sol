// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "ds-test/test.sol";

contract CrowdtainerTestHelpers is DSTest {
    // @dev Helper function to check wheether the thrown Custom Error type matches expectation.
    function assertEqSignature(
        string memory expectedMethodSignature,
        bytes calldata receivedBytes
    ) external {
        bytes memory expectedErrorSignature = abi.encodeWithSignature(
            expectedMethodSignature
        );
        bytes memory temp = receivedBytes[:4];
        if (!checkEq0(expectedErrorSignature, temp)) {
            emit log_named_bytes("  Expected", expectedErrorSignature);
            emit log_named_bytes("    Actual", temp);
            fail();
        }
    }

    // @dev Helper function to decode 2 address parameters and print their values.
    function printAddresses(bytes calldata receivedBytes) external {
        (address expected, address actual) = abi.decode(
            receivedBytes[4:],
            (address, address)
        );

        emit log_named_address("  Expected", expected);
        emit log_named_address("    Actual", actual);
    }
}
