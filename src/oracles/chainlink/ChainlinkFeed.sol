// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {console} from "forge-std/console.sol";

contract ICO {
    // Chainlink Feed implementation
    AggregatorV3Interface public constant CHAINLINK_FEED_ADDRESS_ETH =
        AggregatorV3Interface(0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70); // Example: ETH/USD feed on Base

    mapping(address => uint256) public contributions;
    uint256 public averageContribution;
    uint8 public totalContributions;

    function commitToIco() external payable {
        uint256 ethAmount = msg.value;

        require(
            ethAmount >= getAverageContributionUSD(),
            "Must send ETH to commit"
        );

        int256 price = getPrice();
        require(price > 0, "Invalid price data");

        // Convert ETH amount to USD

        uint256 usdAmount = (ethAmount * uint256(price)) / 1 ether; // Convert to USD with 8 decimals
        contributions[msg.sender] += usdAmount;

        unchecked {
            ++totalContributions;
        }

        // Update average contribution
        averageContribution =
            (averageContribution + usdAmount) /
            totalContributions;
    }

    function getAverageContributionUSD() public view returns (uint256) {
        if (totalContributions == 0) {
            return 0.001 ether;
        }
        return (averageContribution * uint256(getPrice())) / 1 ether;
    }

    function getPrice() public view returns (int256 price) {
        (, price, , , ) = CHAINLINK_FEED_ADDRESS_ETH.latestRoundData();
    }

    function redeem() external {
        uint256 contribution = contributions[msg.sender];
        require(contribution > 0, "No contributions to redeem");

        // Logic to redeem tokens based on USD contribution
        // For simplicity, assume 1 USD = 1 Token
        uint256 tokensToRedeem = contribution; // Tokens with 8 decimals

        // Reset contribution
        contributions[msg.sender] = 0;

        // Transfer tokens to the user (token transfer logic not implemented here)
        // TODO: token.transfer(msg.sender, tokensToRedeem);
    }
}
