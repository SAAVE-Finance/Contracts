# SAAVE Finance Contracts
### Summary
Lets users deposit stablecoins like DAI, USDC, and USDT to generate yields from the most battle tested strategies.
1. users can deposit any amount of DAI, USDC, and/or USDT. 
2. deposits are deployed into AAVE, Curve and Curve Gauge - all in 1 click
3. withdrawls can be done at any time, funds are withdrawn from all positions, and the deposit + rewards are delivered to the user.
#### FUTURE UPDATES 
- A way to fund auto compounding
- A way to pool CRV to increase returns 

<b>SAAVEFactory</b> in ` SAAVE.sol ` - All user interactions will be done here. <br/>
<b>SAAVE_Receiver</b> - in `SAAVE_Receiver.sol` - Abstract contract used to interact with external DeFi protocols, inherits `curveActions`, `AAVEActions` <br/>
<b>curveActions</b> - in `curveActions.sol` - contains all methods and elements needed to interact with Curve Finance. <br/>
<b>AAVEActions</b> - in `AAVEActions.sol` - contains all methods and elements needed to interact with AAVE.
<br/>
<br/>

## SAAVEFactory
### Description
All user interactions will be done through this factory contract. This contract deploys Receiver contracts that will act as abstract accounts for each user. 

`deposit()`
```solidity
function deposit() public payable nonReentrant
```
`
💡Requires approval of user tokens to be deposited.
`
<br/><br/>
- Initiates deposit of user funds into __SAAVEFactory__ contract. 
- Deploys and assigns a user a __SAAVE_Receiver__ contract if one has not been assigned yet.  <br/>
- User funds are transferred to the newly deployed receiver contract.
<br/>
<br/>


`withdraw()`
<br/>
```solidity 
 function withdraw() public
 ```
- withdraws user funds from all investment positions.
- returns deposit + profit to user

<br/>
<br/>

`checkUpKeep()` <br/>
```solidity
 function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /*performData*/)
 ```
 - check if required interval has been passed or not. Returns 'true' if upkeep neded.
 - Required for Chainlink Keepers.

<br/>
<br/>

`performUpkeep()` <br/>
```solidity
 function performUpkeep(bytes calldata /*performData*/) external override
```
- loops through all user accounts to check if they have a deposit > 0.
- harvests CRV rewards if user account has > 0

## SAAVE_Receiver
### Description
Abstract contract that is used to interact with external contracts like AAVE, Curve and Chainlink.
<br/>
<br/>
`constructor`
```solidity
    constructor(address SAAVEFactory, address _owner) {
        factory = SAAVEFactory;
        owner = _owner;
    }
```
- specifies the address of the __SAAVEFactory__ contract
- assigns the owner of the contract to the owner address

<br/>

`deposit()` <br/>

```solidity
function deposit() external 
```

- loans user's deposited stablecoins into AAVE V3 protocol
- adds liquidity to AAVE Stablecoin Pool using aTokens received from AAVE
- deposits LP Tokens received from Curve into the Curve Gauge to mine CRV

<br/>

`harvest()`
```solidity
function harvest() external 
```
`Inactive, no way to fund harvesting, will maybe introduce a way in the future`
- swaps CRV through multiple pools to aquire more am3 LP
- deposits more LP tokens into Curve Gauge to mine more CRV

<br/>

`widthdrawAll()`
```solidity
function withdrawAll() external
```


