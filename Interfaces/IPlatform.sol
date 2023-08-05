// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPlatform {
    function GetPlatformCommssions() external view returns(
        uint256 _PNFTMintingCommission,
        uint256 _PNFTListingCommission
    );
    function checkWhitelisted(address _userWalletAddress, uint256 _role) external view returns (bool);
    function getPSAdmin() external view returns (address);
}