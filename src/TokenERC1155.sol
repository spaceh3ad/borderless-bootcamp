// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155Token is ERC1155 {
    constructor() ERC1155("https://myapi.com/metadata/{id}.json") {
        _mint(msg.sender, 1, 1000, "");
    }
}
