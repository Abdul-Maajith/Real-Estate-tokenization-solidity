// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../Interfaces/IPlatform.sol";
import "../../Factory/Interfaces/IDeployPropertyMinting.sol";

error User_is_not_WhiteListed();

contract PropertyFactory {
    address[] private s_allCollections;
    mapping(address => address[]) private s_userCollecions;
    address public PlatformContractAddress;
    bool public isUserWhitelisted;
    address public PSAdmin;
    address public propertyMintingContract;
    address public PropertyMintingDeploymentContract;
    address public PropertyTraderDeploymentContract;

    event collectionCreated(address owner, address deployedAt);

    constructor(
        address _PlatformContractAddress,
        address _propertyMintingDeploymentContract,
        address _propertyTraderDeploymentContract
    ) {
        PlatformContractAddress = _PlatformContractAddress;
        PropertyMintingDeploymentContract = _propertyMintingDeploymentContract;
        PropertyTraderDeploymentContract = _propertyTraderDeploymentContract;
        (PSAdmin) = IPlatform(PlatformContractAddress).getPSAdmin();
    }

    function createCollection(string memory NAME, string memory SYMBOL) 
    public 
    returns(address owner, address deployedAt)
    {
        (isUserWhitelisted) = IPlatform(PlatformContractAddress).checkWhitelisted(
            msg.sender,
            1
        );

        if(isUserWhitelisted) {
            propertyMintingContract = IDeployPropertyMinting(PropertyMintingDeploymentContract).deployPropertyMintingContract(
                NAME, 
                SYMBOL,  
                PlatformContractAddress,
                PropertyTraderDeploymentContract,
                PSAdmin
            );
            s_userCollecions[msg.sender].push(propertyMintingContract);
            s_allCollections.push(propertyMintingContract);

            emit collectionCreated(msg.sender, propertyMintingContract);
            return(msg.sender, propertyMintingContract);
        } else {
            revert User_is_not_WhiteListed();
        }
    }
}