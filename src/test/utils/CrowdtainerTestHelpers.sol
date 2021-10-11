// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "ds-test/test.sol";

contract CrowdtainerTestHelpers is DSTest {
    // @dev Intermediate function to call assertEqSignature_ with params as calldata.
    function assertEqSignature(
        string memory expectedMethodSignature,
        bytes memory receivedBytes
    ) internal {
        // forward call and parameters
        (bool success, ) = address(this).call(
            abi.encodeWithSignature(
                "assertEqSignature_(string,bytes)",
                expectedMethodSignature,
                receivedBytes
            )
        );
        assertTrue(success);
    }

    // @dev Helper function to check wheether the thrown Custom Error type matches expectation.
    function assertEqSignature_(
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

    // @dev Intermediate function to call printAddress2_ with calldata params.
    function printAddress2(bytes memory receivedBytes) internal {
        // forward call and parameters
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("printAddress2_(bytes)", receivedBytes)
        );
        assertTrue(success);
    }

    // @dev Helper function to decode 2 address parameters and print their values.
    function printAddress2_(bytes calldata receivedBytes) external {
        (address expected, address actual) = abi.decode(
            receivedBytes[4:],
            (address, address)
        );

        emit log_named_address("  Expected", expected);
        emit log_named_address("    Actual", actual);
    }
}
