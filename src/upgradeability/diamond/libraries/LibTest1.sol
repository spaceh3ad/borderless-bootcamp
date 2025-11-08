// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library LibTest1 {
    struct Test1Storage {
        uint256 someValue;
        string someString;
        address someAddress;
    }

    bytes32 constant TEST1_STORAGE_POSITION =
        keccak256("diamond.standard.test1.storage");

    function getStorage() internal pure returns (Test1Storage storage ts) {
        bytes32 position = TEST1_STORAGE_POSITION;
        assembly {
            ts.slot := position
        }
    }
}
