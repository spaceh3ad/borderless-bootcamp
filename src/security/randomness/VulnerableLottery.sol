// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VulnerableLottery
/// @notice Demonstrates insecure randomness vulnerability using block.timestamp
/// @dev WARNING: This contract is intentionally vulnerable for educational purposes
/// DO NOT use this pattern in production!
contract VulnerableLottery {
    address public owner;
    address[] public players;
    uint256 public constant ENTRY_FEE = 0.1 ether;
    uint256 public lotteryId;
    address public lastWinner;
    uint256 public lastWinAmount;

    event PlayerEntered(address indexed player, uint256 lotteryId);
    event WinnerSelected(
        address indexed winner,
        uint256 amount,
        uint256 lotteryId
    );
    event LotteryReset(uint256 newLotteryId);

    error InsufficientEntryFee();
    error NoPlayers();
    error OnlyOwner();
    error TransferFailed();

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
        lotteryId = 1;
    }

    /// @notice Enter the lottery by paying entry fee
    function enter() external payable {
        if (msg.value < ENTRY_FEE) revert InsufficientEntryFee();

        players.push(msg.sender);
        emit PlayerEntered(msg.sender, lotteryId);
    }

    /// @notice Select winner using INSECURE randomness
    /// @dev VULNERABILITY: Uses block.timestamp which is predictable!
    /// Miners can manipulate timestamp within ~15 seconds
    /// Anyone can predict the winner before calling this function
    function selectWinner() external {
        if (players.length == 0) revert NoPlayers();

        // VULNERABLE: Predictable randomness source
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    players.length
                )
            )
        );

        uint256 winnerIndex = randomNumber % players.length;
        address winner = players[winnerIndex];
        uint256 prize = address(this).balance;

        lastWinner = winner;
        lastWinAmount = prize;

        // Reset lottery
        delete players;
        lotteryId++;

        emit WinnerSelected(winner, prize, lotteryId - 1);
        emit LotteryReset(lotteryId);

        // Transfer prize
        (bool success, ) = winner.call{value: prize}("");
        if (!success) revert TransferFailed();
    }

    /// @notice Get all current players
    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    /// @notice Get current player count
    function getPlayerCount() external view returns (uint256) {
        return players.length;
    }

    /// @notice Get current prize pool
    function getPrizePool() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Predict the winner (demonstrates vulnerability)
    /// @dev Anyone can call this to know who will win!
    function predictWinner() external view returns (address) {
        if (players.length == 0) revert NoPlayers();

        // Same calculation as selectWinner - completely predictable!
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    players.length
                )
            )
        );

        uint256 winnerIndex = randomNumber % players.length;
        return players[winnerIndex];
    }

    receive() external payable {}
}
