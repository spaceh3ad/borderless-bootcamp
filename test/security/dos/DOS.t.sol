// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";

contract DosTest is Test {
    Dosable dosable;
    EvilContract evil;

    address bob;
    address alice;
    address charlie;

    function setUp() public {
        dosable = new Dosable();

        bob = makeAddr("bob");
        alice = makeAddr("alice");
        charlie = makeAddr("charlie");

        vm.deal(bob, 10 ether);
        vm.deal(alice, 10 ether);
        vm.deal(charlie, 10 ether);

        evil = new EvilContract(address(dosable));
    }

    function test_DOS_Attack() public {
        vm.prank(bob);
        dosable.donate{value: 1 ether}();

        vm.prank(alice);
        dosable.donate{value: 1 ether}();

        vm.prank(charlie);
        dosable.donate{value: 1 ether}();

        evil.enter{value: 1 ether}();

        vm.prank(bob);
        dosable.donate{value: 1 ether}();
    }
}

contract Dosable {
    address[] public users;

    uint256 public constant MIN_AMOUNT = 0.001 ether;

    /// ALWAYS USE PULL OVER PUSH PATTERN
    function donate() external payable {
        require(msg.value >= MIN_AMOUNT, "Minimum donation not met");

        if (users.length == 0) {
            users.push(msg.sender);
            return;
        }

        uint256 dropAmount = address(this).balance / users.length;
        for (uint i = 0; i < users.length; i++) {
            // payable(users[i]).transfer(dropAmount);
            _account(users[i], dropAmount);
        }
        users.push(msg.sender);
    }

    function _account(address user, uint256 amount) internal {
        //
        // require(success, "Transfer failed");
    }
}

contract EvilContract {
    Dosable dosable;

    constructor(address _dosable) {
        dosable = Dosable(_dosable);
    }

    function enter() external payable {
        dosable.donate{value: msg.value}();
    }

    receive() external payable {
        revert("I refuse to accept funds");
    }
}
