//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/OpenZeppelin/IERC20.sol";
import "../interfaces/Curve/ICurve_Pool.sol";
import "../interfaces/Curve/ICurve_Gauge_Pool.sol";

contract curveActions {


    //AAVE Tokens
    address constant amDAIAddr = 0x27F8D03b3a2196956ED754baDc28D73be8830A6e;
    address constant amUSDCAddr = 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F;
    address constant amUSDTAddr = 0x60D55F02A771d515e077c9C2403a1ef324885CeC;


    //Curve AAVE StablePool
    address AAVECurvePoolAddr = 0x445FE580eF8d70FF569aB36e80c647af338db351;
    ICurve_Pool AAVECurvePool = ICurve_Pool(AAVECurvePoolAddr);
    
    //AM3 CRV Gauge Pool/Token
    address am3CRVGaugePoolAddr = 0x19793B454D3AfC7b454F206Ffe95aDE26cA6912c;
    ILiquidityGaugeV3 gaugePool = ILiquidityGaugeV3(am3CRVGaugePoolAddr);


    //CRV TriCrypto Pool
    address CRVTricryptoPoolAddr = 0xc7c939A474CB10EB837894D1ed1a77C61B268Fa7;
    V2Pool CRVTriPool = V2Pool(CRVTricryptoPoolAddr);

    //Tricrypto Pool
    address TricryptoPoolAddr = 0x92215849c439E1f8612b6646060B4E3E5ef822cC;
    ICurve_Pool TricryptoPool = ICurve_Pool(TricryptoPoolAddr);

    address am3CRV_LP = 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171;
    address CRVAddr = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;

    address amWBTC = 0x5c2ed810328349100A66B82b78a1791B101C9D61;
    address amWETH = 0x28424507fefb6f7f8E9D3860F56504E4e5f5f390;

    //CRV Earned counter
    uint CRVEarned;

    function addCurve() internal {
        IERC20 amDAI = IERC20(amDAIAddr);
        IERC20 amUSDC = IERC20(amUSDCAddr);
        IERC20 amUSDT = IERC20(amUSDTAddr);

        uint _daiAmount = amDAI.balanceOf(address(this));
        uint _USDCAmount = amUSDC.balanceOf(address(this));
        uint _USDTAmount = amUSDT.balanceOf(address(this));

        //approve
        //amDAI.approve(address(AAVECurvePoolAddr), type(uint256).max);
        //amUSDC.approve(address(AAVECurvePoolAddr), type(uint256).max);
        amUSDT.approve(address(AAVECurvePoolAddr), _USDTAmount);

        uint[3] memory aaveTokenAmount = [_daiAmount, _USDCAmount, _USDTAmount];
        //might want to set minimum to greater than 0.
        AAVECurvePool.add_liquidity(aaveTokenAmount, 0);

    }

    //deposit newly minted LP Tokens into Gauge
    // More info: https://curve.readthedocs.io/dao-gauges.html
    function depositGauge() internal {
        //LP token balance of this contract
        uint am3CRV_LP_amt = IERC20(am3CRV_LP).balanceOf(address(this));

        IERC20(am3CRV_LP).approve(am3CRVGaugePoolAddr, am3CRV_LP_amt);

        gaugePool.deposit(am3CRV_LP_amt, address(this), false);
    }


    function withdrawGauge() internal {
        checkCRVRewards();
        swapCRVtoAM3CRV();
        uint stakeTokenAmt = IERC20(am3CRVGaugePoolAddr).balanceOf(address(this));

        gaugePool.withdraw(stakeTokenAmt);
             

    }

    function removeLiquidityAM3() internal {
        uint LPTokenAmt = IERC20(am3CRV_LP).balanceOf(address(this));
        uint256[3] memory expected;
        AAVECurvePool.remove_liquidity(LPTokenAmt,expected);
    }

    //Should be view but compiler yells at me
    function checkCRVRewards() internal returns (uint256) {
        uint CRVReward = gaugePool.claimable_reward(address(this), CRVAddr);
        if (CRVReward > 0){
        CRVEarned += CRVReward;
        gaugePool.claim_rewards(msg.sender);
        }
        return CRVReward;
    }


    //CRV TriCrypto: Index 0 = CRV, 1 = TriCrypto_LP
    //a TriCrypto: Index 0 = am3CRV LP, 1 = amWBTC, 2 amWETH
    function swapCRVtoAM3CRV() internal {
        uint256[3] memory expected;
        uint CRVAmt = IERC20(CRVAddr).balanceOf(address(this));

        checkCRVRewards();
        //swap CRV for Tricrypto LP
        /*should update minimum to higher than 0*/
        if(CRVAmt > 0){
            //CRVTriPool.exchange(int128(0),int128(1),CRVAmt, 0);
            //uint TriPoolLPAmt = IERC20(TricryptoPoolAddr).balanceOf(address(this));
            //remove liquidity from TriPool, gain am3CRV and amWBTC and amWETH
            //TricryptoPool.remove_liquidity(TriPoolLPAmt, expected);

            //swap amWBTC and amWETH for am3CRV LP
            //uint amWBTCAmt = IERC20(amWBTC).balanceOf(address(this));
            //uint amWETHAmt = IERC20(amWETH).balanceOf(address(this));
            //TricryptoPool.exchange(1, 0, amWBTCAmt, 0);
            //TricryptoPool.exchange(2, 0, amWETHAmt, 0);
        }



    }


    //FRONTEND FUNCTIONS ===============================================
    function getDAISupply() public view returns (uint256) {
        
        uint _amount = AAVECurvePool.balances(uint256(0));
        return _amount;
    }

    function getUSDCSupply() public view returns (uint256) {
        uint _amount = AAVECurvePool.balances(uint256(1));
        return _amount;
    }

    function getUSDTSupply() public view returns (uint256) {
        uint _amount = AAVECurvePool.balances(uint256(2));
        return _amount;
    }

    function getGaugeBalance() public view returns (uint256) {
        uint stakeTokenAmt = IERC20(am3CRVGaugePoolAddr).balanceOf(address(this));
        return stakeTokenAmt;
    }
    
    function getTotalLP() public view returns (uint256) {
        uint totalLP = IERC20(am3CRV_LP).totalSupply();
        return totalLP;
    }

    function getCRVEarned() public view returns (uint256){
        return CRVEarned;
    }











    

}

