// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title HashCollision
/// @notice Demonstrates various hash collision scenarios with abi.encodePacked
/// @dev Educational contract showing why abi.encodePacked is dangerous with dynamic types
contract HashCollision {
    /// @notice Demonstrate basic collision with two strings
    /// @dev ("ab", "c") produces same hash as ("a", "bc")
    function demonstrateBasicCollision() external pure returns (bool collision) {
        bytes32 hash1 = keccak256(abi.encodePacked("ab", "c"));
        bytes32 hash2 = keccak256(abi.encodePacked("a", "bc"));

        collision = (hash1 == hash2); // TRUE - collision!
    }

    /// @notice Demonstrate collision with addresses and strings
    /// @dev Dynamic types can collide when concatenated
    function demonstrateAddressStringCollision(address addr) external pure returns (bool collision) {
        // These produce the same hash!
        bytes32 hash1 = keccak256(abi.encodePacked(addr, "transfer"));
        bytes32 hash2 = keccak256(abi.encodePacked(addr, "trans", "fer"));

        collision = (hash1 == hash2); // TRUE - collision!
    }

    /// @notice Demonstrate multiple parameter collision
    /// @dev With 3 strings, many collisions possible
    function demonstrateMultiCollision() external pure returns (bool collision) {
        bytes32 hash1 = keccak256(abi.encodePacked("a", "b", "c"));
        bytes32 hash2 = keccak256(abi.encodePacked("ab", "", "c"));
        bytes32 hash3 = keccak256(abi.encodePacked("a", "", "bc"));

        collision = (hash1 == hash2) && (hash2 == hash3); // TRUE - all same!
    }

    /// @notice Show that abi.encode prevents collisions
    /// @dev abi.encode includes length information
    function demonstrateSecureEncoding() external pure returns (bool noCollision) {
        bytes32 hash1 = keccak256(abi.encode("ab", "c"));
        bytes32 hash2 = keccak256(abi.encode("a", "bc"));

        noCollision = (hash1 != hash2); // TRUE - different hashes!
    }

    /// @notice Show safe use of abi.encodePacked with fixed types
    /// @dev Fixed-size types don't have collision issues
    function demonstrateSafeEncodePacked() external pure returns (bool noCollision) {
        bytes32 hash1 = keccak256(abi.encodePacked(uint256(1), uint256(2)));
        bytes32 hash2 = keccak256(abi.encodePacked(uint256(12), uint256(0)));

        noCollision = (hash1 != hash2); // TRUE - different with fixed sizes!
    }

    /// @notice Get collision examples for testing
    function getCollisionPairs()
        external
        pure
        returns (string memory str1a, string memory str1b, string memory str2a, string memory str2b)
    {
        return ("ab", "c", "a", "bc");
    }

    /// @notice Compare hashes for two string pairs
    function compareHashes(
        string memory a1,
        string memory b1,
        string memory a2,
        string memory b2
    ) external pure returns (bytes32 hashPacked1, bytes32 hashPacked2, bytes32 hashEncode1, bytes32 hashEncode2) {
        hashPacked1 = keccak256(abi.encodePacked(a1, b1));
        hashPacked2 = keccak256(abi.encodePacked(a2, b2));
        hashEncode1 = keccak256(abi.encode(a1, b1));
        hashEncode2 = keccak256(abi.encode(a2, b2));
    }

    /// @notice Show bytes representation difference
    function showEncodingDifference(string memory a, string memory b)
        external
        pure
        returns (bytes memory packed, bytes memory encoded)
    {
        packed = abi.encodePacked(a, b);
        encoded = abi.encode(a, b);
    }
}
