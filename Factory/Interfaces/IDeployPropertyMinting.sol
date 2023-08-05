// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeployPropertyMinting {
    function deployPropertyMintingContract(
        string memory NAME, 
        string memory SYMBOL, 
        address _platformContractAddress,
        address _propertyTraderDeploymentContract,
        address _PSAdmin
    ) external returns(address);
}