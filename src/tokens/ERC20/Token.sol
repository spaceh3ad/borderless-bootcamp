// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC20Permit, ERC20} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract Token is ERC20Permit {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20Permit(_name) ERC20(_name, _symbol) {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}

contract TokenHandler {
    function handleToken(
        address tokenAddress,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        ERC20Permit(tokenAddress).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        // TODO:do something with the tokens
    }
}
