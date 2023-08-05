// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeployPropertyTrader {
    function deployPropertyTraderContract(
        address _platformContractAddress,
        address _propertyMintingContract, 
        address _PSAdmin
    ) external returns(address);
}