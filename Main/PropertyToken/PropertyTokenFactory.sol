// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../Interfaces/IPlatform.sol";
import "./PropertyTokenMinting.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error User_is_not_WhiteListed();

contract PropertyTokenFactory {
    mapping(address => bool) public isTokenExists;
    address[] private token_allCollections;
    address public PlatformContractAddress;
    bool public isUserWhitelisted;
    address public PSAdmin;
    address public propertyTokenMintingContract;
    struct TokenSale {
        address seller;
        uint256 price;
        uint256 remainingTokens;
    }

    mapping(address => TokenSale) public tokenSales;

    event NewTokenCreated(address indexed token, string name, string symbol);
    event TokenSold(address indexed token, address indexed buyer, uint256 amount, uint256 price);

    constructor(
        address _PlatformContractAddress
    ) {
        PlatformContractAddress = _PlatformContractAddress;
        (PSAdmin) = IPlatform(PlatformContractAddress).getPSAdmin();
    }

    event tokenCreated(address owner, address deployedAt);

    function createToken(string memory NAME, string memory SYMBOL, uint8 decimals, uint256 initialSupply) 
    public 
    returns (address)
    {
        (isUserWhitelisted) = IPlatform(PlatformContractAddress).checkWhitelisted(
            msg.sender,
            1
        );

        if(isUserWhitelisted) {
            PropertyTokenMinting propertyToken = new PropertyTokenMinting(NAME, SYMBOL, decimals, initialSupply, msg.sender);
            emit NewTokenCreated(address(propertyToken), NAME, SYMBOL);
            isTokenExists[address(propertyToken)] = true;
            return address(propertyToken);

        } else {
            revert User_is_not_WhiteListed();
        }
    }

    //Amount of token to be sold
    function listTokenForSell(address token, uint256 price, uint256 amount) public {
        require(isTokenExists[token], "No token Exists");
        (isUserWhitelisted) = IPlatform(PlatformContractAddress).checkWhitelisted(
            msg.sender,
            1
        );
        if(isUserWhitelisted) {
            require(price > 0, "Price must be greater than zero");
            require(amount > 0, "Amount must be greater than zero");

            IERC20(token).approve(address(this), amount);
            tokenSales[token] = TokenSale(msg.sender, price, amount);
        } else {
            revert User_is_not_WhiteListed();
        }
    }

    function buyToken(address token, uint256 noOfTokens) public payable {
        TokenSale storage sale = tokenSales[token];
        require(sale.price > 0, "Token not available for sale");
        require(sale.remainingTokens > 0, "No more tokens available for sale");
        require(noOfTokens > 0, "Number of tokens must be greater than zero");
        require(noOfTokens <= sale.remainingTokens, "Not enough tokens available for sale");
        require(msg.value >= sale.price, "Insufficient funds");

       IERC20(token).transferFrom(sale.seller, msg.sender, noOfTokens);
       sale.remainingTokens -= noOfTokens;
        emit TokenSold(token, msg.sender, noOfTokens, sale.price);

        if (msg.value > sale.price) {
            payable(msg.sender).transfer(msg.value - sale.price);
        }
    }
}