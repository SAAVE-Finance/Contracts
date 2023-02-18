//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurve_Pool {
    function calc_token_amount(uint256[3] memory _amounts, bool _is_deposit) external returns (uint256);
    function remove_liquidity(uint256 _amount, uint[3] memory _min_amounts) external returns (uint256);
    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external returns (uint256);
    function balances(uint256 i) external view returns(uint256);

   
    
}

interface V2Pool {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);
}