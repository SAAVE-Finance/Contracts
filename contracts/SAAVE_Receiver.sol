//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./curveActions.sol";
import "./AAVEActions.sol";



//we need this contract because curve Gauge distributes rewards every time the user deposits or withdraws LP Tokens.
//This is a problem if we have only 1 contract, it would be hard to track how much each user deserves.
//making a separate contract makes it way easier to track.

contract SAAVE_Receiver is curveActions, AAVEActions {

    address factory;
    address owner;

    constructor(address SAAVEFactory, address _owner) {
        factory = SAAVEFactory;
        owner = _owner;
    }
    
    function deposit() external {
        require(msg.sender == factory);

        //loan tokens to AAVE
        depositStablesAAVE();
        //add liquidity to curve
        addCurve();
        //deposit into curve gauge
        depositGauge();
    }

    // 4+ times a year:
    // swap CRV rewards for amTokens
    // deposit all amTokens into curve again

    function harvest() external {
        require(msg.sender == factory);
        
        //swap CRV for AM3 LP
        swapCRVtoAM3CRV();

        //add all aave matic tokens into am3
        addCurve();

        //deposit new AM3 LP into gauge
        depositGauge();
    }


    //withdraw function
    //withdraw from gauge
    //sell crv for am3
    //withdraw from am3 pool
    //burn am3 for ma

    function withdrawAll() external {
        require(msg.sender == factory);

        CRVEarned = 0;
        withdrawGauge();
        swapCRVtoAM3CRV();
        removeLiquidityAM3();
        withdrawAAVE(owner);
        //refundGas();
        
    }

    //frontend helpers

    function refundGas() internal {
        require(msg.sender == owner);
        address payable _owner = payable(owner);
        _owner.transfer(address(this).balance);
    }










   



}

