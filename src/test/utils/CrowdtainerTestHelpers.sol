// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

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
    // @dev This function can be removed once Solidity has support for decoding revert args of custom error types.
    function printTwoAddresses(bytes calldata receivedBytes) external {
        (address actual, address expected) = abi.decode(
            receivedBytes[4:],
            (address, address)
        );
        emit log_named_address("  Expected", expected);
        emit log_named_address("    Actual", actual);
    }

    // @dev Helper function to decode 2 uint256 parameters and print their values from returned data.
    // @dev This function can be removed once Solidity has support for decoding revert args custom error types.
    function printTwoUint256(bytes calldata receivedBytes) external {
        (uint256 received, uint256 limit) = abi.decode(
            receivedBytes[4:],
            (uint256, uint256)
        );
        emit log_named_uint("  Received", received);
        emit log_named_uint("    Limit", limit);
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
