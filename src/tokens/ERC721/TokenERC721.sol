// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract ERC721Token is ERC721 {
    string uri;

    constructor() ERC721("MyNFTToken", "NFTTOKEN") {
        _mint(msg.sender, 10);
    }

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function setBaseURI(string memory newuri) public {
        uri = newuri;
    }
}
