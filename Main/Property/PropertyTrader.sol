// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NoProceeds();
error NotOwner();
error isowner(); 
error PriceMustBeAboveZero();
error NotApprovedForMarketplace();
error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NotapprovedForchanges(address nftaddress , uint256 tokenId); 
error this_request_already_approved();
error you_already_approved_this_request();
error you_cannot_update_your_listing();
error your_request_is_not_approved_yet();
error Invalid_Eth_sent();
error Auction_Listing_Fee_not_paid();

contract PropertyTrader is ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
    }
    struct RequestedForApproval{
        address nftAddress ; 
        uint256 tokenId ;
    }
    struct Auction{
        uint256 minAmount; 
        uint256 EndingTime; 
        address seller; 
    }
    struct BuyAuction{
        uint256 HighestBidamount; 
        address HighestBidder; 
    }
    struct bid{
        uint256 _highestamt; 
        address _highestbidder; 
    }
    struct contractAddress {
        address NftMintingContract; 
        address MasterWhitelistingContract;
        address CommissionsContract;
    }
    enum AuctionState{
        Listed, 
        Sold, 
        Cancelled 
    }

    // Events
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );
    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event StartAuction(
        string msg, 
        uint256 startedAt, 
        uint256 endAt
    );
    event EndAuction(
        address highestBidder, 
        uint256 highestBid
    );
    event Bid(
        address indexed sender, 
        uint256 amount
    );
    event Withdraw(
        address indexed bidder, 
        uint256 amount
    );
    event StartOpenForBids(
        address seller,
        string msg, 
        uint256 startedAt
    );
    event openBidded(
        address bidder, 
        uint256 bid
    );
    event soldOnOpenForBids(
        address buyer, 
        uint256 bidPrice
    );

    // State Variables
    uint256 public MarketplaceCommission; 
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds;
    mapping(address => bool)private IsOwner ; 
    mapping(address => mapping(uint256 => address)) private  creators_Addresses; 
    mapping(address => mapping(uint256 => bool)) private isFreezed;
    mapping(address => mapping(uint256 => bool))private isApproved; 
    mapping(address => mapping(uint256 => uint256)) private NoOfApproved; 
    mapping(address => mapping(uint256 => mapping(address => bool)))private AlreadyApproved; 
    mapping(address => bool) public isAuctionListingFeePaid;
    bool public isCustomListingFeeUser;
    address public nftSeller;
    bool private AuctionStarted;
    bool private openForBidsStarted;
    bool private AuctionEnded;
    uint256 public AuctionEndAt;
    uint256 private nftId;
    uint256 public highestBid;
    address public highestBidder;
    address[] private bidders;
    mapping(address => uint256) public openBidders;
    uint256 private startingBids;

    
    address public PlatformContractAddress;
    address private PSAdmin;
    uint256 public NFTListingFee;
    address public PropertyMintingContract;

    constructor(
        address _platformContractAddress,
        address _propertyMintingContract, 
        address _PSAdmin
    ) {
        PlatformContractAddress = _platformContractAddress;
        PropertyMintingContract = _propertyMintingContract;
        PSAdmin = _PSAdmin;
    }

    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        nftSeller = nft.ownerOf(tokenId);
        if (spender != nftSeller) {
            revert NotOwner();
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier checkAuctionListingFeePaid() {
        if(!isAuctionListingFeePaid[msg.sender]) {
            revert Auction_Listing_Fee_not_paid();
        }
        _;
    }

    function isnotOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) internal view{
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender == owner) {
            revert NotOwner();
        }
    }

    // Getting Listingfee creation fee based on condition(Normal_user & GBUser).
    function getListingFee() internal {
        (, bytes memory _data) = PlatformContractAddress.call(
                abi.encodeWithSignature("GetPlatformCommissions()")
        );
        (,NFTListingFee) = abi.decode(_data, 
            (uint256, uint256)
        );
    }  

    // Fixed Price
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        public 
        payable 
        notListed(nftAddress, tokenId, msg.sender)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        getListingFee();
        if(msg.value != NFTListingFee) {
                revert Invalid_Eth_sent();
            }

         if(NFTListingFee > 0) {
            payable(PSAdmin).transfer(NFTListingFee);
        }

        IERC721 nft = IERC721(nftAddress);
        require(nft.getApproved(tokenId) == address(this), "Contract must be approved");

        s_listings[address(nft)][tokenId] = Listing(price, msg.sender);
        itemListed(msg.sender, nftAddress, tokenId, price);
    }

    function buyItem(address nftAddress, uint256 tokenId)
        external
        payable
        isListed(nftAddress, tokenId)
        nonReentrant
        returns (
            address buyer,
            address _nftAddress,
            uint256 _tokenId,
            uint256 price
        )
        {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert PriceNotMet(nftAddress, tokenId, listedItem.price);
        }

        payable(msg.sender).transfer(msg.value);

        s_proceeds[listedItem.seller] += msg.value;
        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            tokenId
        );
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
        return(msg.sender, nftAddress, tokenId, listedItem.price);
    }

    function itemListed(
        address _owner, 
        address _nftAddress, 
        uint256 _tokenId,
        uint256 _price
    ) internal 
    returns(
        address seller,
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) {
        emit ItemListed(_owner, _nftAddress, _tokenId, _price);
        return (_owner, _nftAddress, _tokenId, _price);
    }
 
    // Auction
    function ListNftOnAuction(
        address _nftAddress, 
        uint256 _nftId, 
        uint256 startingBid, 
        uint256 endtime
    )
        public 
        payable
        notListed(_nftAddress, _nftId, msg.sender)
        isOwner(_nftAddress, _nftId, msg.sender)
    {
        getListingFee();
        isAuctionListingFeePaid[msg.sender] = true;
        if(msg.value != NFTListingFee) {
            revert Invalid_Eth_sent();
        }
        
        IERC721 nft = IERC721(_nftAddress);
        require(!openForBidsStarted, "Open-For-Bids is Already Started");
        require(nft.getApproved(_nftId) == address(this), "Contract must be approved");
        require(!AuctionStarted, "Already started!");

        highestBid = startingBid;
        nftId = _nftId;

        AuctionStarted = true;
        AuctionEndAt = block.timestamp + endtime; 

        emit StartAuction("Auction started", block.timestamp, AuctionEndAt);
    }

    function ListAgainOnAuction(
        address _nftAddress, 
        uint256 _nftId, 
        uint256 startingBid, 
        uint256 endtime
    )
        public 
        checkAuctionListingFeePaid
        notListed(_nftAddress, _nftId, msg.sender)
        isOwner(_nftAddress, _nftId, msg.sender)
    {
        IERC721 nft = IERC721(_nftAddress);
        require(!openForBidsStarted, "Open-For-Bids is Already Started");
        require(nft.getApproved(_nftId) == address(this), "Contract must be approved");
        require(AuctionStarted, "Cannot List Again, Auction not yet started before!");

        highestBid = startingBid;
        nftId = _nftId;

        AuctionStarted = true;
        AuctionEndAt = block.timestamp + endtime; 

        emit StartAuction("Auction started", block.timestamp, AuctionEndAt);
    }

    function bidOnAuction(address _nftAddress, uint256 _nftId, uint256 _bid) public {
        require(AuctionStarted, "Auction Not Started!");
        require(block.timestamp < AuctionEndAt, "Auction have been Ended!");
        require(_bid >= highestBid, "You cannot bid, minimum than a highest bid");
        
        // Storing the New HighestBidder and his Bids!
        highestBid = _bid;
        highestBidder = msg.sender;
        // bids[highestBidder] += highestBid; // Cumalative sum of bids by single Person - Future purpose!

        bidders.push(msg.sender);

        IERC721 nft = IERC721(_nftAddress);
        address owner = nft.ownerOf(_nftId);
        if(owner != address(this)) {
            nft.transferFrom(nftSeller, address(this), nftId);
        }

        emit Bid(highestBidder, highestBid);
    }

    function endAuction(address _nftAddress) 
    public
    payable 
    {
        require(AuctionStarted, "You need to start the Auction first!");
        require(block.timestamp >= AuctionEndAt, "Auction is Still onGoing!");
        require(!AuctionEnded, "Auction Already ended!");
        AuctionEnded = true;

        if(msg.value < highestBid) {
            revert Invalid_Eth_sent();
        }

        if (highestBidder != address(0)) {
            IERC721(_nftAddress).safeTransferFrom(address(this), highestBidder, nftId);
            payable(nftSeller).transfer(highestBid);
        } else {
            // If no one bids, tranferring the nft back to the seller!
            IERC721(_nftAddress).safeTransferFrom(address(this), nftSeller, nftId);
        }

        emit EndAuction(highestBidder, highestBid);
    }

    // OpenForBids
    function ListNftOnOpenForBids(
        address _nftAddress, 
        uint256 _nftId
    )
        public 
        payable
        notListed(_nftAddress, _nftId, msg.sender)
        isOwner(_nftAddress, _nftId, msg.sender)
    {
        getListingFee();
        if(msg.value != NFTListingFee) {
            revert Invalid_Eth_sent();
        }
        
        IERC721 nft = IERC721(_nftAddress);
        require(nft.getApproved(_nftId) == address(this), "Contract must be approved");
        require(!openForBidsStarted, "Cannot List the NFT Again(OpenForBids)!");

        nftId = _nftId;

        openForBidsStarted = true;
        emit StartOpenForBids(nftSeller, "Bidding started", block.timestamp);
    }

    function bidOnOpenForBids(address _nftAddress, uint256 _nftId, uint256 _bid) public {
        require(openForBidsStarted, "OpenForBids-Not Started!");

        openBidders[msg.sender] = _bid;
        // OpenBidderArrays.push(msg.sender); 

        IERC721 nft = IERC721(_nftAddress);
        address owner = nft.ownerOf(_nftId);
        if(owner != address(this)) {
            nft.transferFrom(nftSeller, address(this), nftId);
        }

        emit openBidded(msg.sender, _bid);
    }

    function sellToBidder(address _nftAddress, address _openBidder, uint256 _nftId) public payable {
        require(openForBidsStarted, "OpenForBids, Not Started!");

        uint256 bidPrice = openBidders[_openBidder];
        if(msg.value < bidPrice) {
            revert Invalid_Eth_sent();
        }

        IERC721(_nftAddress).safeTransferFrom(address(this), _openBidder, _nftId);
        payable(nftSeller).transfer(bidPrice);

        emit soldOnOpenForBids(_openBidder, bidPrice);
    }

    function getTimeStamp() public view returns(uint256) {
        return block.timestamp;
    }  
}