// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../../Interfaces/IPlatform.sol";
import "../../Factory/Interfaces/IDeployPropertyTrader.sol";

error Invalid_Eth_sent();
error User_is_not_WhiteListed();
error URI_query_for_nonexistent_token();

contract PropertyMinting is ERC721, Pausable{
    using Counters for Counters.Counter;
    Counters.Counter _tokenIdTracker;
    
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => mapping(uint256 => bool)) private isMintedByUser;
    address public platformTradeContract;
    mapping(uint256 => address) private minter;
    address public platformContractAddress;
    address public PropertyTraderDeploymentContract;
    bool public isUserWhitelisted;
    uint256 public NFTMintingFee;
    address public PSAdmin;
    uint256 public NftId;
    mapping(address => bool) public isTraderContractApproved;
    mapping(uint256 => address) public traderContractAddressMappingWithNftId;

    event Minted(uint256 _NftId, address TradeContractAddr);

    constructor(
        string memory NAME, 
        string memory SYMBOL, 
        address _platformContractAddress,
        address _propertyTraderDeploymentContract,
        address _PSAdmin
    ) ERC721(NAME, SYMBOL) {
        platformContractAddress = _platformContractAddress;
        PropertyTraderDeploymentContract = _propertyTraderDeploymentContract;
        PSAdmin = _PSAdmin;
    }

    function getMintingFee() internal {
        (, bytes memory _data) = platformContractAddress.call(
                abi.encodeWithSignature("GetPlatformCommissions()")
        );
        (NFTMintingFee, ) = abi.decode(_data, 
            (uint256, uint256)
        );
    }

    function mintNft(string memory _tokenURI) 
        public
        payable
        returns(uint256 _NftId, address TradeContractAddr) 
    {
        getMintingFee();

        (isUserWhitelisted) = IPlatform(platformContractAddress).checkWhitelisted(
            msg.sender,
            1
        );

        if(isUserWhitelisted) {
            if(msg.value != NFTMintingFee) {
                revert Invalid_Eth_sent();
            }

            if(NFTMintingFee > 0) {
                payable(PSAdmin).transfer(NFTMintingFee);
            }

            NftId = _tokenIdTracker.current();
            _safeMint(msg.sender, NftId);
            isMintedByUser[msg.sender][NftId] = true;
            minter[NftId] = msg.sender;
            _setTokenURI(NftId, _tokenURI);
            _tokenIdTracker.increment();

            // Approving Nft trader contract, whenever we mint a new Nft!
            platformTradeContract = IDeployPropertyTrader(PropertyTraderDeploymentContract).deployPropertyTraderContract(
                platformContractAddress,
                address(this),
                PSAdmin
            );

            isTraderContractApproved[address(platformTradeContract)] = true;

            approve(
                address(platformTradeContract),
                NftId
            );

            traderContractAddressMappingWithNftId[NftId] = address(platformTradeContract);

            emit Minted(NftId, address(platformTradeContract));
            return(NftId, address(platformTradeContract));
        } else {
            revert User_is_not_WhiteListed();
        }
    }

    // sets uri for a token
    function _setTokenURI(uint256 _tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        _tokenURIs[_tokenId] = _tokenURI;
    }

    // returns uri of a particular token
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if(!_exists(_tokenId)) {
            revert URI_query_for_nonexistent_token();
        }
        string memory _tokenURI = _tokenURIs[_tokenId];

        return _tokenURI;
    }

    function pause() public {
        _pause();
    }

    function unPause() public {
        _unpause();
    }

    function approve(address to, uint256 tokenId) public virtual override {
        require(isTraderContractApproved[to], "Error: approving nft for sell is disabled for all other marketPlaces");

        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(isTraderContractApproved[operator], "Error: approving nft for sell is disabled for all other marketPlaces");
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes memory data
    // ) public virtual override {
    //     (isUserWhitelisted) = IPlatform(platformContractAddress).checkWhitelisted(
    //         msg.sender,
    //         2
    //     );
        
    //     if(isUserWhitelisted) {
    //         require(
    //             isTraderContractApproved[traderContractAddressMappingWithNftId[tokenId]], 
    //             "Error: we can't transfer the token for all other marketPlaces"
    //         );
    //     } else {
    //         revert("Error: we can't transfer the token for all other marketPlaces");
    //     }
    //     _safeTransfer(from, to, tokenId, data);
    // }
}