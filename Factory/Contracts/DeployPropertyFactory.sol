// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../Main/Property/PropertyFactory.sol";

contract DeployPropertyFactory {
    address public MainPropertyFactoryContract;

    function deployPropertyFactoryContract(
        address _PlatformContractAddress,
        address _propertyMintingDeploymentContract,
        address _propertyTraderDeploymentContract
    ) external returns(address) {
        PropertyFactory propertyFactory = new PropertyFactory(
            _PlatformContractAddress,
            _propertyMintingDeploymentContract,
            _propertyTraderDeploymentContract
        );

        MainPropertyFactoryContract = address(propertyFactory);
        return address(propertyFactory);
    }
}