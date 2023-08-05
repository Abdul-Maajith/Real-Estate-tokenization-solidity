// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../Main/Property/PropertyTrader.sol";

contract DeployPropertyTrader {
    address public MainPropertyTraderContract;

    function deployPropertyTraderContract(
        address _platformContractAddress,
        address _propertyMintingContract, 
        address _PSAdmin
    ) external returns(address) {
        PropertyTrader propertyTrader = new PropertyTrader(
            _platformContractAddress,
            _propertyMintingContract, 
            _PSAdmin   
        );
        
        MainPropertyTraderContract = address(propertyTrader);
        return address(propertyTrader);
    }
}