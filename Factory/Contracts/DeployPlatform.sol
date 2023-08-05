// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../Main/Platform.sol";

contract DeployPlatform {
    address public MainPlatfromContract;

    function deployPlatformContract(
        address _PSAdmin
    ) external returns(address) {
        Platform platform = new Platform(
            _PSAdmin
        );
        
        MainPlatfromContract = address(platform);
        return address(platform);
    }
}