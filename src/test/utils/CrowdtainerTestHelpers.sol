// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// import "ds-test/test.sol";
import "forge-std/Test.sol";
import "./Hevm.sol";
import "../../contracts/ICrowdtainer.sol";

contract CrowdtainerTestHelpers is Test {
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

    uint256 internal constant ONE = 10 ** 6; // 6 decimal places

    // @dev Helper function used to slice bytes, and get a custom error revert signature.
    function getSignature(bytes calldata data) external pure returns (bytes4) {
        assert(data.length >= 4);
        return bytes4(data[:4]);
    }

    // @dev Helper function used to get the parameters of a custom error revert.
    function getParameters(
        bytes calldata data
    ) external pure returns (bytes calldata) {
        return data[4:];
    }

    struct AvoidStackTooDeep {
        uint256[] quantities;
        uint256[] unitPricePerType;
    }

    function calculateTotalCost(
        AvoidStackTooDeep memory quantitiesAndPrice
    ) internal returns (uint256 totalCost) {
        assertEq(quantitiesAndPrice.quantities.length, quantitiesAndPrice.unitPricePerType.length);
        for (uint256 i = 0; i < quantitiesAndPrice.quantities.length; i++) {
            totalCost += quantitiesAndPrice.quantities[i] * quantitiesAndPrice.unitPricePerType[i];
        }
    }

    // @dev Helper function to check wheether the thrown Custom Error type matches expectation.
    function isEqualSignature(
        bytes calldata expectedSignature,
        bytes calldata receivedBytes
    ) external returns (bool) {
        if (receivedBytes.length < 4) {
            emit log_string("No custom error");
            return false;
        }

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
        return abi.encode(selector);
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
}
