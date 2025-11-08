// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SecureLottery
/// @notice Demonstrates secure randomness using commit-reveal scheme
/// @dev This is a simplified example. Production should use Chainlink VRF
contract SecureLottery {
    address public owner;
    address[] public players;
    uint256 public constant ENTRY_FEE = 0.1 ether;
    uint256 public lotteryId;
    address public lastWinner;
    uint256 public lastWinAmount;

    // Commit-reveal state
    bytes32 public commitHash;
    uint256 public commitBlock;
    uint256 public constant REVEAL_DELAY = 5; // Must wait 5 blocks

    event PlayerEntered(address indexed player, uint256 lotteryId);
    event RandomnessCommitted(bytes32 commitHash, uint256 blockNumber);
    event WinnerSelected(address indexed winner, uint256 amount, uint256 lotteryId);
    event LotteryReset(uint256 newLotteryId);

    error InsufficientEntryFee();
    error NoPlayers();
    error OnlyOwner();
    error TransferFailed();
    error AlreadyCommitted();
    error NoCommitment();
    error TooEarly();
    error InvalidReveal();

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

    /// @notice Commit to a random number (step 1 of commit-reveal)
    /// @param _commitHash Hash of (secret + salt)
    /// @dev Owner commits to randomness BEFORE knowing all players
    function commitRandomness(bytes32 _commitHash) external onlyOwner {
        if (commitHash != bytes32(0)) revert AlreadyCommitted();

        commitHash = _commitHash;
        commitBlock = block.number;

        emit RandomnessCommitted(_commitHash, block.number);
    }

    /// @notice Reveal random number and select winner (step 2 of commit-reveal)
    /// @param _secret The secret number that was committed
    /// @param _salt Additional randomness salt
    /// @dev Must wait REVEAL_DELAY blocks to prevent manipulation
    function revealAndSelectWinner(uint256 _secret, bytes32 _salt) external onlyOwner {
        if (commitHash == bytes32(0)) revert NoCommitment();
        if (block.number < commitBlock + REVEAL_DELAY) revert TooEarly();
        if (players.length == 0) revert NoPlayers();

        // Verify the reveal matches the commitment
        bytes32 revealHash = keccak256(abi.encodePacked(_secret, _salt));
        if (revealHash != commitHash) revert InvalidReveal();

        // SECURE: Combine pre-committed secret with future block hash
        // Block hash is unknown at commit time, preventing manipulation
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    _secret,
                    _salt,
                    blockhash(commitBlock + 1), // Future block at commit time
                    players.length
                )
            )
        );

        uint256 winnerIndex = randomNumber % players.length;
        address winner = players[winnerIndex];
        uint256 prize = address(this).balance;

        lastWinner = winner;
        lastWinAmount = prize;

        // Reset state
        delete players;
        delete commitHash;
        delete commitBlock;
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

    /// @notice Helper to generate commit hash off-chain
    /// @param _secret Secret number to commit
    /// @param _salt Random salt
    function generateCommitHash(uint256 _secret, bytes32 _salt) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_secret, _salt));
    }

    receive() external payable {}
}
