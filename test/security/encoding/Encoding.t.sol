// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {VulnerableSignature} from "./VulnerableSignature.sol";
import {SecureSignature} from "./SecureSignature.sol";
import {HashCollision} from "./HashCollision.sol";
import {
    MessageHashUtils
} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract EncodingTest is Test {
    VulnerableSignature public vulnerableSignature;
    SecureSignature public secureSignature;
    HashCollision public hashCollision;

    address public owner;
    uint256 public ownerPrivateKey;
    address public attacker;

    function setUp() public {
        owner = makeAddr("owner");
        ownerPrivateKey = 0x1234;
        owner = vm.addr(ownerPrivateKey);
        attacker = makeAddr("attacker");

        // Deploy contracts
        vm.prank(owner);
        vulnerableSignature = new VulnerableSignature();

        vm.prank(owner);
        secureSignature = new SecureSignature();

        hashCollision = new HashCollision();
    }

    /*//////////////////////////////////////////////////////////////
                    HASH COLLISION DEMONSTRATIONS
    //////////////////////////////////////////////////////////////*/

    function test_hashCollision_basicCollision() public {
        console.log("=== Demonstrating Basic Hash Collision ===");
        console.log("");

        // Get hashes for two different string pairs
        bytes32 hash1 = keccak256(abi.encodePacked("ab", "c"));
        bytes32 hash2 = keccak256(abi.encodePacked("a", "bc"));

        console.log("Hash of ('ab', 'c'):");
        console.logBytes32(hash1);
        console.log("Hash of ('a', 'bc'):");
        console.logBytes32(hash2);
        console.log("");

        // COLLISION: Both hashes are identical!
        assertTrue(
            hash1 == hash2,
            "COLLISION: Different inputs produce same hash!"
        );
        console.log("VULNERABILITY: Hash collision detected!");
    }

    function test_hashCollision_demonstrateAll() public {
        bool collision1 = hashCollision.demonstrateBasicCollision();
        assertTrue(collision1, "Basic collision should occur");

        bool collision2 = hashCollision.demonstrateMultiCollision();
        assertTrue(collision2, "Multi-parameter collision should occur");

        bool noCollision = hashCollision.demonstrateSecureEncoding();
        assertTrue(noCollision, "abi.encode should prevent collision");

        bool safeFixed = hashCollision.demonstrateSafeEncodePacked();
        assertTrue(safeFixed, "Fixed types should be safe");
    }

    function test_hashCollision_compareEncodingMethods() public {
        console.log("=== Comparing abi.encodePacked vs abi.encode ===");
        console.log("");

        (
            bytes32 hashPacked1,
            bytes32 hashPacked2,
            bytes32 hashEncode1,
            bytes32 hashEncode2
        ) = hashCollision.compareHashes("ab", "c", "a", "bc");

        console.log("Using abi.encodePacked:");
        console.log("  ('ab', 'c'):");
        console.logBytes32(hashPacked1);
        console.log("  ('a', 'bc'):");
        console.logBytes32(hashPacked2);
        console.log("  COLLISION:", hashPacked1 == hashPacked2 ? "YES" : "NO");
        console.log("");

        console.log("Using abi.encode:");
        console.log("  ('ab', 'c'):");
        console.logBytes32(hashEncode1);
        console.log("  ('a', 'bc'):");
        console.logBytes32(hashEncode2);
        console.log("  COLLISION:", hashEncode1 == hashEncode2 ? "YES" : "NO");
        console.log("");

        assertTrue(hashPacked1 == hashPacked2, "encodePacked has collision");
        assertTrue(hashEncode1 != hashEncode2, "encode prevents collision");
    }

    function test_hashCollision_showEncodingDifference() public {
        (bytes memory packed, bytes memory encoded) = hashCollision
            .showEncodingDifference("ab", "c");

        console.log("abi.encodePacked('ab', 'c'):");
        console.logBytes(packed);
        console.log("Length:", packed.length);
        console.log("");

        console.log("abi.encode('ab', 'c'):");
        console.logBytes(encoded);
        console.log("Length:", encoded.length);
        console.log("");

        // encodePacked is shorter (just concatenation)
        // encode includes length and padding
        assertTrue(packed.length < encoded.length, "encodePacked is shorter");
    }

    /*//////////////////////////////////////////////////////////////
                VULNERABLE SIGNATURE - ATTACK SCENARIO
    //////////////////////////////////////////////////////////////*/

    function test_vulnerableSignature_collisionAttack() public {
        console.log("=== Hash Collision Attack on Signature System ===");
        console.log("");

        // Owner signs authorization for action ("transfer", "100")
        bytes32 messageHash1 = keccak256(abi.encodePacked("transfer", "100"));
        bytes32 ethSignedMessageHash1 = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash1)
        );
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(
            ownerPrivateKey,
            ethSignedMessageHash1
        );
        bytes memory signature1 = abi.encodePacked(r1, s1, v1);

        console.log("Owner signs: action='transfer', param='100'");
        console.log("Message hash:");
        console.logBytes32(messageHash1);
        console.log("");

        // Attacker finds collision: ("transfe", "r100") has SAME hash!
        bytes32 messageHash2 = keccak256(abi.encodePacked("transfe", "r100"));

        console.log("Attacker discovers collision:");
        console.log("  action='transfe', param='r100'");
        console.log("  Message hash:");
        console.logBytes32(messageHash2);
        console.log("");

        assertTrue(messageHash1 == messageHash2, "Collision exists");
        console.log("COLLISION CONFIRMED: Different actions have same hash!");
        console.log("");

        // Original authorized action
        vm.prank(owner);
        vulnerableSignature.executeAction("transfer", "100", signature1);

        assertTrue(
            vulnerableSignature.wasExecuted("transfer", "100"),
            "Original action executed"
        );
        console.log("Original action executed successfully");
        console.log("");

        // Attacker tries to execute with collision
        // This should fail because it's marked as executed
        vm.prank(attacker);
        vm.expectRevert(VulnerableSignature.AlreadyExecuted.selector);
        vulnerableSignature.executeAction("transfe", "r100", signature1);

        console.log("Attacker CANNOT re-execute due to AlreadyExecuted check");
        console.log(
            "BUT: The collision means attacker could have front-run the original!"
        );
    }

    function test_vulnerableSignature_frontRunWithCollision() public {
        console.log("=== Front-Running Attack Using Hash Collision ===");
        console.log("");

        // Owner creates signature for ("approve", "alice")
        bytes32 messageHash = keccak256(abi.encodePacked("approve", "alice"));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            messageHash
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey,
            ethSignedMessageHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        console.log("Owner signs: action='approve', param='alice'");
        console.log("");

        // Attacker sees this in mempool and front-runs with collision
        // ("approv", "ealice") has the SAME hash
        bytes32 collisionHash = keccak256(abi.encodePacked("approv", "ealice"));
        assertTrue(messageHash == collisionHash, "Collision exists");

        console.log(
            "Attacker front-runs with: action='approv', param='ealice'"
        );
        console.log("Same hash - signature is valid!");
        console.log("");

        // Attacker executes first
        vm.prank(attacker);
        vulnerableSignature.executeAction("approv", "ealice", signature);

        console.log("Attacker's transaction succeeds");
        console.log("");

        // Owner's original transaction fails (already executed)
        vm.prank(owner);
        vm.expectRevert(VulnerableSignature.AlreadyExecuted.selector);
        vulnerableSignature.executeAction("approve", "alice", signature);

        console.log("Owner's legitimate transaction FAILS");
        console.log(
            "VULNERABILITY EXPLOITED: Attacker front-ran with collision!"
        );
    }

    /*//////////////////////////////////////////////////////////////
                    SECURE SIGNATURE - NO COLLISION
    //////////////////////////////////////////////////////////////*/

    function test_secureSignature_noCollision() public {
        console.log("=== Secure Signature Prevents Collision Attack ===");
        console.log("");

        // Owner signs with abi.encode
        bytes32 messageHash1 = keccak256(abi.encode("transfer", "100"));
        bytes32 ethSignedMessageHash1 = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash1)
        );
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(
            ownerPrivateKey,
            ethSignedMessageHash1
        );
        bytes memory signature1 = abi.encodePacked(r1, s1, v1);

        console.log("Owner signs: action='transfer', param='100'");
        console.log("Hash with abi.encode:");
        console.logBytes32(messageHash1);
        console.log("");

        // Try collision with abi.encode
        bytes32 messageHash2 = keccak256(abi.encode("transfe", "r100"));
        console.log("Potential collision: action='transfe', param='r100'");
        console.log("Hash with abi.encode:");
        console.logBytes32(messageHash2);
        console.log("");

        assertTrue(
            messageHash1 != messageHash2,
            "NO COLLISION with abi.encode!"
        );
        console.log("SECURE: Hashes are different!");
        console.log("");

        // Execute original action
        vm.prank(owner);
        secureSignature.executeAction("transfer", "100", signature1);

        assertTrue(secureSignature.wasExecuted("transfer", "100"));
        console.log("Original action executed");
        console.log("");

        // Attacker tries collision attack - will fail with InvalidSignature
        vm.prank(attacker);
        vm.expectRevert(SecureSignature.InvalidSignature.selector);
        secureSignature.executeAction("transfe", "r100", signature1);

        console.log("Attacker's collision attempt FAILS: InvalidSignature");
        console.log("SECURE: abi.encode prevents the attack!");
    }

    function test_secureSignature_safeEncodePacked() public {
        // When using ONLY fixed-size types, abi.encodePacked is safe
        bytes32 messageHash = keccak256(
            abi.encodePacked(uint256(1), uint256(100))
        );
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            messageHash
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey,
            ethSignedMessageHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(owner);
        secureSignature.executeFixedAction(1, 100, signature);

        // No collision possible with fixed types
        bytes32 hash1 = keccak256(abi.encodePacked(uint256(1), uint256(100)));
        bytes32 hash2 = keccak256(abi.encodePacked(uint256(11), uint256(0)));
        assertTrue(hash1 != hash2, "Fixed types don't collide");
    }

    /*//////////////////////////////////////////////////////////////
                    COMPARISON TESTS
    //////////////////////////////////////////////////////////////*/

    function test_comparison_vulnerableVsSecure() public {
        console.log("=== Direct Comparison: Vulnerable vs Secure ===");
        console.log("");

        // Same input to both systems
        string memory action = "withdraw";
        string memory param = "500";

        // Vulnerable uses encodePacked
        bytes32 vulnHash = keccak256(abi.encodePacked(action, param));
        console.log("Vulnerable (encodePacked):");
        console.logBytes32(vulnHash);

        // Find collision for vulnerable
        bytes32 vulnCollision = keccak256(abi.encodePacked("withd", "raw500"));
        console.log("Collision ('withd', 'raw500'):");
        console.logBytes32(vulnCollision);
        console.log(
            "Vulnerable has collision:",
            vulnHash == vulnCollision ? "YES" : "NO"
        );
        console.log("");

        // Secure uses encode
        bytes32 secureHash = keccak256(abi.encode(action, param));
        console.log("Secure (encode):");
        console.logBytes32(secureHash);

        // Try same collision on secure
        bytes32 secureCollision = keccak256(abi.encode("withd", "raw500"));
        console.log("Attempt ('withd', 'raw500'):");
        console.logBytes32(secureCollision);
        console.log(
            "Secure has collision:",
            secureHash == secureCollision ? "YES" : "NO"
        );
        console.log("");

        assertTrue(vulnHash == vulnCollision, "Vulnerable has collision");
        assertTrue(secureHash != secureCollision, "Secure prevents collision");
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_encodePacked_canCollide(
        string memory a,
        string memory b
    ) public {
        // Limit string lengths for practical fuzzing
        vm.assume(bytes(a).length > 0 && bytes(a).length < 20);
        vm.assume(bytes(b).length > 0 && bytes(b).length < 20);

        bytes32 hash1 = keccak256(abi.encodePacked(a, b));

        // Create collision by splitting differently
        string memory combined = string(abi.encodePacked(a, b));
        bytes memory combinedBytes = bytes(combined);

        if (combinedBytes.length > 1) {
            // Split at different position
            uint256 splitPos = combinedBytes.length / 2;

            bytes memory firstPart = new bytes(splitPos);
            bytes memory secondPart = new bytes(
                combinedBytes.length - splitPos
            );

            for (uint256 i = 0; i < splitPos; i++) {
                firstPart[i] = combinedBytes[i];
            }
            for (uint256 i = splitPos; i < combinedBytes.length; i++) {
                secondPart[i - splitPos] = combinedBytes[i];
            }

            bytes32 hash2 = keccak256(
                abi.encodePacked(string(firstPart), string(secondPart))
            );

            // These should be equal (collision)
            assertEq(hash1, hash2, "encodePacked allows collisions");
        }
    }

    function testFuzz_encode_preventsCollision(
        string memory a1,
        string memory b1,
        string memory a2,
        string memory b2
    ) public {
        // Ensure different inputs
        vm.assume(
            keccak256(bytes(a1)) != keccak256(bytes(a2)) ||
                keccak256(bytes(b1)) != keccak256(bytes(b2))
        );
        vm.assume(bytes(a1).length < 50 && bytes(b1).length < 50);
        vm.assume(bytes(a2).length < 50 && bytes(b2).length < 50);

        bytes32 hash1 = keccak256(abi.encode(a1, b1));
        bytes32 hash2 = keccak256(abi.encode(a2, b2));

        // With abi.encode, different inputs always give different hashes
        assertTrue(hash1 != hash2, "encode prevents collisions");
    }

    function testFuzz_fixedTypes_safeWithEncodePacked(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) public {
        // Ensure different inputs
        vm.assume(a != c || b != d);

        bytes32 hash1 = keccak256(abi.encodePacked(a, b));
        bytes32 hash2 = keccak256(abi.encodePacked(c, d));

        // Fixed types don't collide even with encodePacked
        assertTrue(hash1 != hash2, "Fixed types are safe");
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_edgeCase_emptyStrings() public {
        // Empty strings can cause collisions
        bytes32 hash1 = keccak256(abi.encodePacked("a", ""));
        bytes32 hash2 = keccak256(abi.encodePacked("", "a"));

        assertTrue(hash1 == hash2, "Empty strings cause collisions");

        // abi.encode handles this correctly
        bytes32 hashEncode1 = keccak256(abi.encode("a", ""));
        bytes32 hashEncode2 = keccak256(abi.encode("", "a"));

        assertTrue(hashEncode1 != hashEncode2, "encode handles empty strings");
    }

    function test_edgeCase_multipleParameters() public {
        // With 3+ parameters, even more collisions possible
        bytes32 hash1 = keccak256(abi.encodePacked("a", "b", "c"));
        bytes32 hash2 = keccak256(abi.encodePacked("ab", "", "c"));
        bytes32 hash3 = keccak256(abi.encodePacked("", "ab", "c"));
        bytes32 hash4 = keccak256(abi.encodePacked("a", "", "bc"));

        assertTrue(hash1 == hash2, "Multiple collisions possible");
        assertTrue(hash1 == hash3, "Multiple collisions possible");
        assertTrue(hash1 == hash4, "Multiple collisions possible");
    }
}
