//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILiquidityGaugeV3 {
    function deposit(uint256 amount, address receiver, bool claim) external;

    function claim_rewards(address _addr) external;

    function claimable_reward(address _addr, address _token) external returns (uint256) ;

    function withdraw(uint256 amount) external;

}