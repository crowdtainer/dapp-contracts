// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "ds-test/test.sol";
import "./Hevm.sol";

contract CrowdtainerTestHelpers is DSTest {
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

    // @dev Helper function to check wheether the thrown Custom Error type matches expectation.
    function assertEqSignature(
        bytes calldata expectedSignature,
        bytes calldata receivedBytes
    ) external returns (bool) {
        bytes memory receivedErrorSignature = receivedBytes[:4];
        bytes memory expected = expectedSignature[:4];

        if (!checkEq0(expected, receivedErrorSignature)) {
            emit log_named_bytes("  Expected", expected);
            emit log_named_bytes("    Actual", receivedErrorSignature);
            return false;
        }
        return true;
    }

    function makeError(bytes4 selector) internal pure returns (bytes memory) {
        bytes memory temp = toBytes(selector);
        return temp;
    }

    // @dev Helper function to decode 2 address parameters and print their values from returned data.
    function printAddresses(bytes calldata receivedBytes) external {
        (address expected, address actual) = abi.decode(
            receivedBytes,
            (address, address)
        );
        emit log_named_address("  Expected", expected);
        emit log_named_address("    Actual", actual);
    }

    // @dev Helper function to convert 'bytes32' into 'bytes memory'.
    function toBytes(bytes32 self)
        internal
        pure
        returns (bytes memory tempBytes)
    {
        // Copies 'self' into a new 'bytes memory'.
        // Returns the newly created 'bytes memory', which will be of length 32.
        tempBytes = new bytes(32);

        //solhint-disable no-inline-assembly
        assembly {
            mstore(
                add(
                    tempBytes,
                    /*BYTES_HEADER_SIZE*/
                    32
                ),
                self
            )
        }
        //solhint-enable no-inline-assembly
    }
}
