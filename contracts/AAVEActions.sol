//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/OpenZeppelin/IERC20.sol";
import "../interfaces/AAVE/IPool.sol";

contract AAVEActions {

    IERC20 USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 DAI = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    IERC20 USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    //V2 POOL ADDRESS WORKS
    address AAVEPool = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    IPool LendingPool = IPool(AAVEPool);

    //AAVE Token Addresses
    address constant amDAI = 0x27F8D03b3a2196956ED754baDc28D73be8830A6e;
    address constant amUSDC = 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F;
    address constant amUSDT = 0x60D55F02A771d515e077c9C2403a1ef324885CeC;

    function depositStablesAAVE() internal {

        address USDTAddr = address(USDT);

        uint16 REFERRAL_CODE = uint16(0);

        uint daiAmt = DAI.balanceOf(address(this));
        uint USDCAmt = USDC.balanceOf(address(this));
        uint USDTAmt = USDT.balanceOf(address(this));

        DAI.approve(AAVEPool, daiAmt );
        USDC.approve(AAVEPool, USDCAmt);
        USDT.approve(AAVEPool, USDTAmt);

        //LendingPool.z(address(DAI), daiAmt , address(this), REFERRAL_CODE);
        //LendingPool.deposit(address(USDC), USDCAmt , address(this), REFERRAL_CODE);
        LendingPool.deposit(USDTAddr, USDTAmt , address(this), REFERRAL_CODE);

    }



    function withdrawAAVE(address _owner) internal {
        IERC20 _amUSDT = IERC20(amUSDT);
        IERC20 _amUSDC = IERC20(amUSDC);
        IERC20 _amDAI = IERC20(amDAI);

        uint amUSDTAmt = _amUSDT.balanceOf(address(this));
        uint amUSDCAmt = _amUSDC.balanceOf(address(this));
        uint amDAIAmt = _amDAI.balanceOf(address(this));

        LendingPool.withdraw(address(USDT), amUSDTAmt, _owner );
        LendingPool.withdraw(address(USDC), amUSDCAmt, _owner );
        LendingPool.withdraw(address(DAI), amDAIAmt, _owner );
    }


    
    
}


