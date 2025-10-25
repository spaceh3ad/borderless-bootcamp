// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SmartWallet {
    function intetgration() external {
        // call some contract with some data
        // => entry points on your platform (context would be msg.sender == this)
    }

    function batchTransfer(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external {
        require(
            recipients.length == amounts.length,
            "Recipients and amounts length mismatch"
        );

        // TODO: check if the contract has the tokens

        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = token.call(
                abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    recipients[i],
                    amounts[i]
                )
            );
            require(success, "Transfer failed");
        }
    }
}
