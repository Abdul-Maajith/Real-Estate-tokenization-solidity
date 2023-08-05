// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error not_a_platform_super_admin();

contract Platform {
    address public PSAdmin;
    mapping(address => bool) public isPSAdmin;
    mapping(address => mapping(uint256 => bool)) public isUserWhitelisted; 
    mapping(address => uint256) public roles;
    address[] public PropertyAdmins;
    address[] public investors;

    struct Commission_P {
        uint256 NFTMintingCommission;
        uint256 NFTListingCommission;
    }
    uint256 public constant PROPERTY_ADMIN = 1;
    uint256 public constant INVESTOR = 2;

    Commission_P commission_p;

    modifier only_plateformAdmin() {
        if(msg.sender != PSAdmin) {
            revert not_a_platform_super_admin();
        }
        _;
    }
    
    // Setter
    constructor(address _PSAdmin){
        PSAdmin = _PSAdmin;
        isPSAdmin[_PSAdmin] = true;
    }

    function whiteListUserWalletAddress(address _addressToWhitelist, uint256 _role) public only_plateformAdmin {
        isUserWhitelisted[_addressToWhitelist][_role] = true;
        roles[_addressToWhitelist] = _role;
        if(_role == 1) {
            PropertyAdmins.push(_addressToWhitelist);
        } else {
            investors.push(_addressToWhitelist);
        }
    }

    function setCommission_P (
        uint256 _PNFTMintingCommission,
        uint256 _PNFTListingCommission
    ) public only_plateformAdmin {
        commission_p = Commission_P(
            _PNFTMintingCommission, 
            _PNFTListingCommission
        );
    }

    // getters
    function checkWhitelisted(address _userWalletAddress, uint256 _role) external view returns (bool) {
        return isUserWhitelisted[_userWalletAddress][_role];
    }

    function hasRole(address _userWalletAddress) external view returns(uint256) {
        return roles[_userWalletAddress];
    }

    function GetPlatformCommissions() external view returns(
        uint256 _PNFTMintingCommission,
        uint256 _PNFTListingCommission
    ) {
        return (
            commission_p.NFTMintingCommission,
            commission_p.NFTListingCommission
        );
    }

    function getPSAdmin() external view returns (address) {
        return PSAdmin;
    }

    function checkIsPSAdmin(address _address) external view returns (bool) {
        return isPSAdmin[_address];
    }
}