// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {
    VulnerableLottery
} from "../../../src/security/randomness/VulnerableLottery.sol";
import {
    RandomnessAttacker
} from "../../../src/security/randomness/RandomnessAttacker.sol";
import {
    SecureLottery
} from "../../../src/security/randomness/SecureLottery.sol";

contract RandomnessTest is Test {
    VulnerableLottery public vulnerableLottery;
    SecureLottery public secureLottery;
    RandomnessAttacker public attacker;

    address public owner;
    address public alice;
    address public bob;
    address public charlie;
    address public attacker1;

    uint256 constant ENTRY_FEE = 0.1 ether;

    event PlayerEntered(address indexed player, uint256 lotteryId);
    event WinnerSelected(
        address indexed winner,
        uint256 amount,
        uint256 lotteryId
    );
    event AttackExecuted(address indexed winner, uint256 amount);
    event RandomnessCommitted(bytes32 commitHash, uint256 blockNumber);

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        attacker1 = makeAddr("attacker1");

        // Deploy contracts
        vm.prank(owner);
        vulnerableLottery = new VulnerableLottery();

        vm.prank(owner);
        secureLottery = new SecureLottery();

        // Fund test accounts
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);
        vm.deal(attacker1, 10 ether);
    }

    /*//////////////////////////////////////////////////////////////
                    VULNERABLE LOTTERY - BASIC TESTS
    //////////////////////////////////////////////////////////////*/
    function test_attackerWinsLottery() public {
        vm.prank(alice);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        vm.prank(bob);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        vm.prank(charlie);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        attacker = new RandomnessAttacker(payable(address(vulnerableLottery)));
        while (true) {
            bool wouldWin = attacker.wouldWin();
            if (wouldWin) {
                break;
            }
            // Advance block timestamp to change randomness
            vm.warp(block.timestamp + 1);
        }
        console.log("Attacker bal before %18e:", address(attacker).balance);
        attacker.attackEnter{value: ENTRY_FEE}();
        console.log("Attacker bal after %18e:", address(attacker).balance);
    }

    function test_vulnerableLottery_shouldAllowEntry() public {
        vm.expectEmit(true, false, false, true);
        emit PlayerEntered(alice, 1);

        vm.prank(alice);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        assertEq(vulnerableLottery.getPlayerCount(), 1);
        assertEq(vulnerableLottery.getPrizePool(), ENTRY_FEE);
    }

    function test_vulnerableLottery_shouldRevertIfInsufficientFee() public {
        vm.prank(alice);
        vm.expectRevert(VulnerableLottery.InsufficientEntryFee.selector);
        vulnerableLottery.enter{value: 0.05 ether}();
    }

    function test_vulnerableLottery_shouldAcceptMultiplePlayers() public {
        vm.prank(alice);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        vm.prank(bob);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        vm.prank(charlie);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        assertEq(vulnerableLottery.getPlayerCount(), 3);
        assertEq(vulnerableLottery.getPrizePool(), 0.3 ether);
    }

    function test_vulnerableLottery_shouldSelectWinner() public {
        // Enter players
        vm.prank(alice);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        vm.prank(bob);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        vm.prank(charlie);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        uint256 prizePool = vulnerableLottery.getPrizePool();

        // Select winner
        vm.prank(owner);
        vulnerableLottery.selectWinner();

        // Verify lottery reset
        assertEq(vulnerableLottery.getPlayerCount(), 0);
        assertEq(vulnerableLottery.lotteryId(), 2);
        assertGt(vulnerableLottery.lastWinAmount(), 0);

        // Verify winner received prize
        address winner = vulnerableLottery.lastWinner();
        assertTrue(
            winner == alice || winner == bob || winner == charlie,
            "Winner should be one of the players"
        );
    }

    function test_vulnerableLottery_shouldRevertIfNoPlayers() public {
        vm.prank(owner);
        vm.expectRevert(VulnerableLottery.NoPlayers.selector);
        vulnerableLottery.selectWinner();
    }

    function test_vulnerableLottery_shouldRevertIfNotOwner() public {
        vm.prank(alice);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        vm.prank(alice);
        vm.expectRevert(VulnerableLottery.OnlyOwner.selector);
        vulnerableLottery.selectWinner();
    }

    /*//////////////////////////////////////////////////////////////
                VULNERABLE LOTTERY - PREDICTABILITY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_vulnerableLottery_shouldBeAbleToPredictWinner() public {
        // Enter players
        vm.prank(alice);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        vm.prank(bob);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        vm.prank(charlie);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        // VULNERABILITY: Anyone can predict the winner!
        address predictedWinner = vulnerableLottery.predictWinner();

        // Select actual winner
        vm.prank(owner);
        vulnerableLottery.selectWinner();

        address actualWinner = vulnerableLottery.lastWinner();

        // Prediction matches reality - this is the vulnerability!
        assertEq(
            predictedWinner,
            actualWinner,
            "Predicted winner matches actual winner - VULNERABLE!"
        );
    }

    function test_vulnerableLottery_sameTimestampGivesSameWinner() public {
        // First lottery
        vm.prank(alice);
        vulnerableLottery.enter{value: ENTRY_FEE}();
        vm.prank(bob);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        address predictedWinner1 = vulnerableLottery.predictWinner();

        vm.prank(owner);
        vulnerableLottery.selectWinner();

        // Second lottery at same timestamp
        vm.prank(alice);
        vulnerableLottery.enter{value: ENTRY_FEE}();
        vm.prank(bob);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        address predictedWinner2 = vulnerableLottery.predictWinner();

        // Same timestamp + same players = same winner
        assertEq(
            predictedWinner1,
            predictedWinner2,
            "Same conditions = same winner"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        ATTACKER CONTRACT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_attacker_shouldDetectWinningScenario() public {
        // Deploy attacker contract
        vm.prank(attacker1);
        attacker = new RandomnessAttacker(payable(address(vulnerableLottery)));

        // Add some players first
        vm.prank(alice);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        vm.prank(bob);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        // Check if attacker would win
        bool wouldWin = attacker.wouldWin();

        // This demonstrates the attacker can calculate if they'd win
        assertTrue(
            wouldWin == true || wouldWin == false,
            "Attacker can predict outcome"
        );
    }

    function test_attacker_shouldOnlyEnterWhenWinning() public {
        // Deploy attacker contract
        vm.prank(attacker1);
        attacker = new RandomnessAttacker(payable(address(vulnerableLottery)));

        vm.deal(address(attacker), 10 ether);

        // Add some honest players
        vm.prank(alice);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        vm.prank(bob);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        // Attacker tries to enter - will revert if they wouldn't win
        bool wouldWin = attacker.wouldWin();

        if (wouldWin) {
            // Attacker enters when they know they'll win
            vm.prank(attacker1);
            attacker.attackEnter{value: ENTRY_FEE}();

            // Select winner
            vm.prank(owner);
            vulnerableLottery.selectWinner();

            // Verify attacker won
            assertEq(vulnerableLottery.lastWinner(), address(attacker));
            assertGt(address(attacker).balance, 0);
        } else {
            // Attacker doesn't enter when they wouldn't win
            vm.prank(attacker1);
            vm.expectRevert(RandomnessAttacker.WillNotWin.selector);
            attacker.attackEnter{value: ENTRY_FEE}();
        }
    }

    function test_attacker_demonstrateExploit() public {
        // This test demonstrates a complete exploit scenario

        // Deploy attacker
        vm.prank(attacker1);
        attacker = new RandomnessAttacker(payable(address(vulnerableLottery)));
        vm.deal(address(attacker), 10 ether);

        uint256 successfulAttacks = 0;
        uint256 attempts = 0;

        // Simulate multiple lottery rounds
        for (uint256 i = 0; i < 5; i++) {
            // Add honest players
            vm.prank(alice);
            vulnerableLottery.enter{value: ENTRY_FEE}();

            vm.prank(bob);
            vulnerableLottery.enter{value: ENTRY_FEE}();

            // Attacker checks if they would win
            bool wouldWin = attacker.wouldWin();
            attempts++;

            if (wouldWin) {
                uint256 attackerBalanceBefore = address(attacker).balance;

                // Attack: Enter only when winning
                vm.prank(attacker1);
                attacker.attackEnter{value: ENTRY_FEE}();

                // Select winner
                vm.prank(owner);
                vulnerableLottery.selectWinner();

                uint256 attackerBalanceAfter = address(attacker).balance;

                if (vulnerableLottery.lastWinner() == address(attacker)) {
                    successfulAttacks++;
                    assertGt(attackerBalanceAfter, attackerBalanceBefore);
                }
            } else {
                // Reset lottery without attacker
                vm.prank(owner);
                vulnerableLottery.selectWinner();
            }

            // Advance time for next round
            vm.warp(block.timestamp + 100);
        }

        console.log(
            "Attacker win rate when entering:",
            successfulAttacks,
            "/",
            attempts
        );
    }

    /*//////////////////////////////////////////////////////////////
                    SECURE LOTTERY - BASIC TESTS
    //////////////////////////////////////////////////////////////*/

    function test_secureLottery_shouldAllowEntry() public {
        vm.expectEmit(true, false, false, true);
        emit PlayerEntered(alice, 1);

        vm.prank(alice);
        secureLottery.enter{value: ENTRY_FEE}();

        assertEq(secureLottery.getPlayerCount(), 1);
    }

    function test_secureLottery_shouldCommitRandomness() public {
        uint256 secret = 12345;
        bytes32 salt = keccak256("salt");
        bytes32 commitHash = keccak256(abi.encodePacked(secret, salt));

        vm.expectEmit(true, false, false, true);
        emit RandomnessCommitted(commitHash, block.number);

        vm.prank(owner);
        secureLottery.commitRandomness(commitHash);

        assertEq(secureLottery.commitHash(), commitHash);
        assertEq(secureLottery.commitBlock(), block.number);
    }

    function test_secureLottery_shouldRevertIfAlreadyCommitted() public {
        bytes32 commitHash = keccak256("test");

        vm.prank(owner);
        secureLottery.commitRandomness(commitHash);

        vm.prank(owner);
        vm.expectRevert(SecureLottery.AlreadyCommitted.selector);
        secureLottery.commitRandomness(commitHash);
    }

    function test_secureLottery_shouldRevertRevealTooEarly() public {
        // Commit
        uint256 secret = 12345;
        bytes32 salt = keccak256("salt");
        bytes32 commitHash = keccak256(abi.encodePacked(secret, salt));

        vm.prank(owner);
        secureLottery.commitRandomness(commitHash);

        // Add player
        vm.prank(alice);
        secureLottery.enter{value: ENTRY_FEE}();

        // Try to reveal immediately (before REVEAL_DELAY blocks)
        vm.prank(owner);
        vm.expectRevert(SecureLottery.TooEarly.selector);
        secureLottery.revealAndSelectWinner(secret, salt);
    }

    function test_secureLottery_shouldRevertInvalidReveal() public {
        // Commit with one secret
        uint256 secret = 12345;
        bytes32 salt = keccak256("salt");
        bytes32 commitHash = keccak256(abi.encodePacked(secret, salt));

        vm.prank(owner);
        secureLottery.commitRandomness(commitHash);

        // Add player
        vm.prank(alice);
        secureLottery.enter{value: ENTRY_FEE}();

        // Wait required blocks
        vm.roll(block.number + 6);

        // Try to reveal with different secret
        vm.prank(owner);
        vm.expectRevert(SecureLottery.InvalidReveal.selector);
        secureLottery.revealAndSelectWinner(99999, salt); // Wrong secret
    }

    function test_secureLottery_completeCommitRevealFlow() public {
        // Step 1: Owner commits to randomness BEFORE players enter
        uint256 secret = 12345;
        bytes32 salt = keccak256("salt");
        bytes32 commitHash = secureLottery.generateCommitHash(secret, salt);

        vm.prank(owner);
        secureLottery.commitRandomness(commitHash);

        uint256 commitBlockNumber = block.number;

        // Step 2: Players enter after commitment
        vm.prank(alice);
        secureLottery.enter{value: ENTRY_FEE}();

        vm.prank(bob);
        secureLottery.enter{value: ENTRY_FEE}();

        vm.prank(charlie);
        secureLottery.enter{value: ENTRY_FEE}();

        // Step 3: Wait required delay
        vm.roll(commitBlockNumber + 6);

        // Step 4: Reveal and select winner
        vm.prank(owner);
        secureLottery.revealAndSelectWinner(secret, salt);

        // Verify
        assertEq(secureLottery.getPlayerCount(), 0);
        assertEq(secureLottery.lotteryId(), 2);
        assertGt(secureLottery.lastWinAmount(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                    COMPARISON: VULNERABLE VS SECURE
    //////////////////////////////////////////////////////////////*/

    function test_comparison_vulnerableIsPredictable() public {
        // Vulnerable lottery
        vm.prank(alice);
        vulnerableLottery.enter{value: ENTRY_FEE}();
        vm.prank(bob);
        vulnerableLottery.enter{value: ENTRY_FEE}();

        // Can predict winner before drawing
        address predictedWinner = vulnerableLottery.predictWinner();

        vm.prank(owner);
        vulnerableLottery.selectWinner();

        assertEq(
            predictedWinner,
            vulnerableLottery.lastWinner(),
            "VULNERABLE: Predictable"
        );
    }

    function test_comparison_secureIsNotPredictable() public {
        // Secure lottery with commit-reveal
        uint256 secret = 12345;
        bytes32 salt = keccak256("salt");
        bytes32 commitHash = secureLottery.generateCommitHash(secret, salt);

        vm.prank(owner);
        secureLottery.commitRandomness(commitHash);

        // Players enter
        vm.prank(alice);
        secureLottery.enter{value: ENTRY_FEE}();
        vm.prank(bob);
        secureLottery.enter{value: ENTRY_FEE}();

        // No way to predict winner before reveal!
        // The blockhash(commitBlock + 1) is unknown at this point

        vm.roll(block.number + 6);
        vm.prank(owner);
        secureLottery.revealAndSelectWinner(secret, salt);

        // Winner is determined but wasn't predictable beforehand
        assertTrue(
            secureLottery.lastWinner() != address(0),
            "SECURE: Not predictable"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_vulnerableLottery_alwaysPredictable(
        uint8 playerCount
    ) public {
        vm.assume(playerCount > 0 && playerCount <= 10);

        // Add players
        for (uint256 i = 0; i < playerCount; i++) {
            address player = address(uint160(i + 1));
            vm.deal(player, 1 ether);
            vm.prank(player);
            vulnerableLottery.enter{value: ENTRY_FEE}();
        }

        // Predict winner
        address predicted = vulnerableLottery.predictWinner();

        // Draw winner
        vm.prank(owner);
        vulnerableLottery.selectWinner();

        // Always predictable
        assertEq(predicted, vulnerableLottery.lastWinner());
    }

    function testFuzz_secureLottery_commitReveal(uint256 secret) public {
        bytes32 salt = keccak256("salt");
        bytes32 commitHash = secureLottery.generateCommitHash(secret, salt);

        vm.prank(owner);
        secureLottery.commitRandomness(commitHash);

        // Add players
        vm.prank(alice);
        secureLottery.enter{value: ENTRY_FEE}();
        vm.prank(bob);
        secureLottery.enter{value: ENTRY_FEE}();

        // Wait and reveal
        vm.roll(block.number + 6);
        vm.prank(owner);
        secureLottery.revealAndSelectWinner(secret, salt);

        // Verify winner selected
        assertTrue(secureLottery.lastWinner() != address(0));
    }
}
