// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FarmFactory {
    address farmImplementation;

    function setFarmImplementation(address _farmImplementation) external {
        farmImplementation = _farmImplementation;
    }

    function createFarm() external returns (address) {
        Farm farm = new Farm();
        return address(farm);
    }

    function cloneFarm() external returns (address) {
        address clone = Clones.clone(farmImplementation);
        return clone;
    }
}

contract Farm {
    IERC20 token;

    struct Deposit {
        uint256 amount;
        uint256 depositedAt;
    }

    mapping(address => Deposit) public deposits;

    function setToken(address _token) external {
        token = IERC20(_token);
    }

    function commitToFarm(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);

        deposits[msg.sender] = Deposit({
            amount: amount,
            depositedAt: block.timestamp
        });
    }

    function withdraw() external {
        Deposit memory userDeposit = deposits[msg.sender];
        require(userDeposit.amount > 0, "No deposit found");

        // Simple interest calculation: 10% per year
        uint256 timeElapsed = block.timestamp - userDeposit.depositedAt;
        uint256 interest = (userDeposit.amount * 10 * timeElapsed) /
            (100 * 365 days);
        uint256 totalAmount = userDeposit.amount + interest;

        delete deposits[msg.sender];

        token.transfer(msg.sender, totalAmount);
    }
}
