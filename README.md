<h1>Summary</h1>
<b>SAAVEFactory</b> in `SAAVE.sol` - All user interactions will be done here. <br/>
<b>SAAVE_Receiver</b> - in `SAAVE_Receiver.sol` - Abstract contract used to interact with external DeFi protocols, inherits `curveActions`, `AAVEActions` <br/>
<b>curveActions</b> - in `curveActions.sol` - contains all methods and elements needed to interact with Curve Finance. <br/>
<b>AAVEActions</b> - in `AAVEActions.sol` - contains all methods and elements needed to interact with Curve Finance.
<br/>
<br/>

<h3>SAAVEFactory</h3>
`deposit()` 
```solidity
function deposit() public payable nonReentrant
```
Requires approval of user tokens to be deposited. 
