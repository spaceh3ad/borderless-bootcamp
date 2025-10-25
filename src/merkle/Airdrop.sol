// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Airdrop {
    bytes32 public merkleRoot;

    constructor(bytes32 _merkleRoot) {
        merkleRoot = _merkleRoot;
    }

    function claim(
        uint256 amount,
        bytes32 refUUID,
        address asset,
        bytes32[] calldata proof
    ) external view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, amount, refUUID, asset)
        );
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}
