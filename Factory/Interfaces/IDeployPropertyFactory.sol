// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeployPropertyFactory {
    function deployPropertyFactoryContract(
        address _PlatformContractAddress,
        address _propertyMintingDeploymentContract,
        address _propertyTraderDeploymentContract
    ) external returns(address);
}