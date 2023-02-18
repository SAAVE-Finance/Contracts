//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SAAVE_Receiver.sol";
import "../utilities/ReentrancyGuard.sol";
import "../interfaces/Chainlink/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//add loading up contract with gas

contract SAAVEFactory is ReentrancyGuard, AutomationCompatibleInterface {

    // Variables
    uint totalFlowed;
    //track user ID for chainlink upkeeps
    mapping(address => uint) userId;
    //track to keep track of current user deposit in USD, and for chainlink upkeeps
    mapping(uint => mapping(address => uint)) userBalance;
    //counter for every time a user joins
    uint userIdCounter;

    //set first auto compounding interval to 3 months from deployment date
    uint autoCompoundInterval;

    address constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    //returns the receiver contract for each user
    mapping(address => SAAVE_Receiver) addressToReceiver;
    //quickly retrieve last user deposit
    mapping(address => uint256) addressDaiDeposit;
    mapping(address => uint256) addressUSDCDeposit;
    mapping(address => uint256) addressUSDTDeposit;

    //Chainlink Pricefeed for CRV on Polygon
    //Address: 0x336584C8E6Dc19637A5b36206B1c79923111b405
    AggregatorV3Interface priceFeed = AggregatorV3Interface(0x336584C8E6Dc19637A5b36206B1c79923111b405);


    constructor() {
        autoCompoundInterval = block.timestamp + 12 weeks;
    }

    function tokenDeposit(address _owner) internal {
        uint daiAllowance = IERC20(DAI).allowance(msg.sender, address(this));
        uint USDCAllowance = IERC20(USDC).allowance(msg.sender, address(this));
        uint USDTAllowance = IERC20(USDT).allowance(msg.sender, address(this));

        if(daiAllowance > 0) {
            IERC20(DAI).transferFrom(_owner, address(this), daiAllowance);
            addressDaiDeposit[_owner] = daiAllowance;
        }
        if(USDCAllowance > 0) {
            IERC20(USDC).transferFrom(_owner, address(this), USDCAllowance);
            addressUSDCDeposit[_owner] = USDCAllowance;
        }
        if(USDTAllowance > 0) {
            IERC20(USDT).transferFrom(_owner, address(this), USDTAllowance);
            addressUSDTDeposit[_owner] = USDTAllowance;
        }
    }



    //deposit function
    function deposit() public payable nonReentrant {

        //if an abstract/ receiver contract was not initialized
        if(address(addressToReceiver[msg.sender]) == address(0)) {
            
            //deposit user tokens to this contract
            tokenDeposit(msg.sender);
            //deploy new receiver
            SAAVE_Receiver newReceiver = new SAAVE_Receiver(address(this), msg.sender);
            
            //get new receiver address
            address receiverAddress = address(newReceiver);
            //assign new receiver to user to receiver mapping
            
            addressToReceiver[msg.sender] = newReceiver;

            

            uint daiAmount = addressDaiDeposit[msg.sender];
            uint USDCAmount = addressUSDCDeposit[msg.sender];
            uint USDTAmount = addressUSDTDeposit[msg.sender];
            

            //transfer recently deposited tokens to receiver contract,  assign user id number, and update balance.
            
            if(daiAmount > 0){
                IERC20(DAI).approve(receiverAddress, daiAmount);
                IERC20(DAI).transfer(receiverAddress, daiAmount);
                userBalance[userIdCounter][msg.sender] += daiAmount;
            }
            if(USDCAmount > 0){
                IERC20(USDC).approve(receiverAddress, USDCAmount);
                IERC20(USDC).transfer(receiverAddress, USDCAmount);
                userBalance[userIdCounter][msg.sender] += USDCAmount;
                
            }
            if(USDTAmount > 0){
                IERC20(USDT).approve(receiverAddress, USDTAmount);
                IERC20(USDT).transfer(receiverAddress, USDTAmount);
                userBalance[userIdCounter][msg.sender] += USDTAmount;
            }

            newReceiver.deposit();

            if (daiAmount > 0 || USDCAmount > 0 || USDTAmount > 0){
                userIdCounter++;
            }
        }
        else {

            //get user id
            uint _userId = userId[msg.sender];


            //address of user's receiver contract
            address receiverAddress = address(addressToReceiver[msg.sender]);
            //load up user's receiver instance
            SAAVE_Receiver userReceiver = SAAVE_Receiver(receiverAddress);

            tokenDeposit(msg.sender);

            uint daiAmount = addressDaiDeposit[msg.sender];
            uint USDCAmount = addressUSDCDeposit[msg.sender];
            uint USDTAmount = addressUSDTDeposit[msg.sender];

            //transfer deposited tokens into receiver contract
            // update user balance
            
            if(daiAmount > 0){
                IERC20(DAI).approve(receiverAddress, daiAmount);
                IERC20(DAI).transferFrom(address(this), receiverAddress, daiAmount);
                userBalance[_userId][msg.sender] += daiAmount;
            }
            if(USDCAmount > 0){
                IERC20(USDC).approve(receiverAddress, USDCAmount);
                IERC20(USDC).transferFrom(address(this), receiverAddress, USDCAmount);
                userBalance[_userId][msg.sender] += USDCAmount;
            }
            if(USDTAmount > 0){
                IERC20(USDT).approve(receiverAddress, USDTAmount);
                IERC20(USDT).transferFrom(address(this), receiverAddress, USDTAmount);
                userBalance[_userId][msg.sender] += USDTAmount;
            }

            //initiate strategy
            userReceiver.deposit();
        }
        }

    

    //withdraw from all positions, send funds to user
    //delete user Id balance
    //return matic deposited in receiver to owner
    function withdraw() public {

        address receiverAddress = address(addressToReceiver[msg.sender]);
        SAAVE_Receiver userReceiver = SAAVE_Receiver(receiverAddress);

        userReceiver.withdrawAll();

        uint _userId = userId[msg.sender];

        delete userBalance[_userId][msg.sender];

    }


    //chainlink upkeep stuff

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        //check condition
        //upkeepNeeded = something
        if(block.timestamp >= autoCompoundInterval){
            upkeepNeeded = true;
        }
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        //recheck maybe idk block.timestamp kinda sucks
        require(block.timestamp >= autoCompoundInterval, "interval has not passed yet");
        //check if at least 1 user has been harvested
        bool _deposited;
        //get number of users to parse through user balances;
        uint _numOfUsers = userIdCounter;

        for(uint i; i < _numOfUsers; i++ ){
            if(userBalance[i][msg.sender] > 0) {
                //address of user's receiver contract
                address receiverAddress = address(addressToReceiver[msg.sender]);
                //load up user's receiver instance
                SAAVE_Receiver userReceiver = SAAVE_Receiver(receiverAddress);
                //auto compound
                userReceiver.harvest();
                if(!_deposited) {
                    _deposited = true;
                }
            }

        }
    }



    /*TESTING Functions */ 

    function getUSDTApproval() public view returns (uint256) {
        uint _balance = IERC20(USDT).allowance(msg.sender, address(this));
        return _balance;
    }

    function getUSDTBalance() public view returns (uint256) {
        uint _balance = IERC20(USDT).balanceOf(msg.sender);
        return _balance;
    }

    function getReceiverAddress() public view returns (address){
        return address(addressToReceiver[msg.sender]);
    }

    function getUSDTDepositMapping() public view returns (uint256) {
        return addressUSDTDeposit[msg.sender];
    }

    //frontend functions ===================================================================

    
    // CALCULATE CURVE SUPPLY ON FRONTEND <----
    // DAI and USDT return 5 decimal places
    // USDC returns 17 decimal places for some reason
    // CALCULATION:
    // 1. Get ratio of LP Tokens relative to total supply
    // 2. multiply times each token supply
    
    //ENTIRE POOL DAI BALANCE
    function getPoolDAIBalance() public view returns (uint) {
        SAAVE_Receiver receiver = addressToReceiver[msg.sender];

        uint am3daiBalance = receiver.getDAISupply();

        return am3daiBalance;
    }

    //ENTIRE POOL USDC BALANCE
    function getPoolUSDCBalance() public view returns (uint) {
        SAAVE_Receiver receiver = addressToReceiver[msg.sender];

        uint am3daiBalance = receiver.getUSDCSupply();

        return am3daiBalance;
    }

        //ENTIRE POOL USDT BALANCE
    function getPoolUSDTBalance() public view returns (uint) {
        SAAVE_Receiver receiver = addressToReceiver[msg.sender];

        uint am3daiBalance = receiver.getUSDTSupply();

        return am3daiBalance;
    }

    //CURRENT USER DEPOSIT
    function getUserDeposit() public view returns (uint256) {

        //get user id
        uint _userId = userId[msg.sender];
        return userBalance[_userId][msg.sender];
    }


    //GET USER LP TOKEN AMOUNT
    function getUserLP() public view returns (uint256) {
        SAAVE_Receiver receiver = addressToReceiver[msg.sender];

        uint gaugeBalance = receiver.getGaugeBalance();

        return gaugeBalance;        
    }
    //GET TOTAL SUPPLY OF LP
    function totalLP() public view returns (uint256) {
        SAAVE_Receiver receiver = addressToReceiver[msg.sender];
        uint _totalLP = receiver.getTotalLP();
        return _totalLP;
    }

    //ALLOWANCES FOR DEPOSIT SCREEN

    function getDaiAllowance() public view returns (uint256) {
        uint256 _allowance = IERC20(DAI).allowance(msg.sender, address(this));
        return _allowance;
    }

    function getUSDCAllowance() public view returns (uint256) {
        uint256 _allowance = IERC20(USDC).allowance(msg.sender, address(this));
        return _allowance;
    }

    function getUSDTAllowance() public view returns (uint256) {
        uint256 _allowance = IERC20(USDT).allowance(msg.sender, address(this));
        return _allowance;
    }

    //return the total amount in wei of CRV earned through curve gauge
    function totalCRVEarned() public view returns (uint256) {
        SAAVE_Receiver receiver = addressToReceiver[msg.sender];
        uint _CRVEarned = receiver.getCRVEarned();
        return _CRVEarned;
    }

    //chainlink pricefeed for CRV
    function getLatestPrice() public view returns (uint) {
        (/* uint80 roundID */, int price, /*uint startedAt*/, /*uint timeStamp*/, /*uint80 answeredInRound*/ ) = priceFeed.latestRoundData();
        uint _price = uint(price);
        return _price;
    }

    //returns the $ amount using chainlink pricefeed * CRV Earned
    function getCRVSold() public view returns (uint256) {
        return (totalCRVEarned() * getLatestPrice());
    }



    











    

}