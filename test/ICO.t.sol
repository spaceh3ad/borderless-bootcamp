// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {ICO} from "src/oracles/chainlink/ChainlinkFeed.sol";
import {Test, console} from "forge-std/Test.sol";

contract ICOTest is Test {
    ICO public ico;
    Handler public handler;

    function setUp() public {
        vm.createSelectFork("https://mainnet.base.org");
        ico = new ICO();
        handler = new Handler(ico);

        targetContract(address(handler));
        // targetSelector(

        // );
    }

    function testCommitToIco() public {
        // Simulate a user committing 1 ETH to the ICO
        vm.deal(address(this), 1 ether);
        ico.commitToIco{value: 1 ether}();

        uint256 contribution = ico.contributions(address(this));
        console.log("USD Contribution (8 decimals): %8e", contribution);
        assertGt(contribution, 0, "Contribution should be greater than 0");
    }

    function testFuzzCommit(uint256 ethAmount) public {
        ethAmount = bound(ethAmount, 0.001 ether, type(uint128).max);

        vm.deal(address(this), ethAmount);
        ico.commitToIco{value: ethAmount}();

        uint256 contribution = ico.contributions(address(this));
        console.log("Committed ETH: %e", ethAmount);
        console.log("USD Contribution (8 decimals): %8e", contribution);
        assertGt(contribution, 0, "Contribution should be greater than 0");
    }

    function invariant_contributionMustBeAboveAverage() public {
        if (ico.totalContributions() == 0) return;

        // if (avg == 0) return;
        uint256 avg = ico.getAverageContributionUSD();
        uint256 contribution = ico.contributions(address(handler));
        assertGe(
            contribution,
            avg,
            "Contribution should be >= average contribution"
        );
    }

    function invariant_contributorsShouldIncrease() public valueIncreases {
        // if (ico.totalContributions() == 0) return;
        // uint8 total = ico.totalContributions();
        // assertGt(total, 0, "Total contributors should be greater than 0");
    }

    modifier valueIncreases() {
        uint256 before = ico.contributions(address(handler));
        _;
        uint256 _after = ico.contributions(address(handler));
        assertGe(_after, before, "Contribution value should not decrease");
    }
}

contract Handler is Test {
    ICO public ico;

    constructor(ICO _ico) {
        ico = _ico;
    }

    function commit(uint256 ethAmount, address actor) public {
        ethAmount = bound(ethAmount, 0.001 ether, type(uint128).max);
        vm.deal(actor, ethAmount);
        vm.prank(actor);
        ico.commitToIco{value: ethAmount}();
    }
}
