// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeployPlatform {
    function deployPlatformContract(
        address _PSAdmin
    ) external returns(address);
}