// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../Main/Property/PropertyMinting.sol";

contract DeployPropertyMinting {
    address public MainPropertyMintingContract;

    function deployPropertyMintingContract(
        string memory NAME, 
        string memory SYMBOL, 
        address _platformContractAddress,
        address _propertyTraderDeploymentContract,
        address _PSAdmin
    ) external returns(address) {
        PropertyMinting propertyMinting = new PropertyMinting(
            NAME, 
            SYMBOL, 
            _platformContractAddress,
            _propertyTraderDeploymentContract,
            _PSAdmin  
        );
        
        MainPropertyMintingContract = address(propertyMinting);
        return address(propertyMinting);
    }
}