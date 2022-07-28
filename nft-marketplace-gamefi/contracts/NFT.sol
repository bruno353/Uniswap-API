// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title SampleERC721
 * @dev Create a sample ERC721 standard token
 */
contract SampleERC721 is ERC721URIStorage {
  using Counters for Counters.Counter;

  Counters.Counter public _tokenIds;
  Counters.Counter public _itemsSold;
  address public ownerGovernance;

  constructor () ERC721("Extra-Life", "LIFE") {
        ownerGovernance = msg.sender;
  }




  //Creating the insured structs:
  struct Insured {
    uint256 id;
    address insured;
  }

  mapping(uint256 => Insured) public Insureds;
  

  //Creating the nfts struct:
  struct Item {
    uint256 id;
    address creator;
    string uri;//metadata url
  }

  event NFTMinted (uint256 id, address creator, string uri);

  mapping(uint256 => Item) public Items; //id => Item

  function mint(string memory uri, uint256 _payout) public payable returns(uint256){
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    approve(address(this), newItemId);
    _setTokenURI(newItemId, uri);
    
    Items[newItemId] = Item({
      id: newItemId, 
      creator: msg.sender,
      uri: uri
    });

    emit NFTMinted(Items[newItemId].id, Items[newItemId].creator, Items[newItemId].uri);
    return newItemId;
  }


  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].uri;
  }

    //MARKETPLACE:

    struct ItemForSale {
        uint256 id;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isSold;
    }

    ItemForSale[] public itemsForSale;
    mapping(uint256 => bool) public activeItems;
    mapping(uint256 => ItemForSale) private idToMarketItem;


    event itemAddedForSale(uint256 id, uint256 tokenId, uint256 price, address seller, bool sold);
    event itemSold(uint256 id, address buyer, uint256 price, bool sold);   



    modifier IsForSale(uint256 id){
        require(!itemsForSale[id].isSold, "Item is already sold");
        _;
    }

    modifier ItemExists(uint256 id){
        require(id < itemsForSale.length && itemsForSale[id].id == id, "Could not find item");
        _;
  }


    function putItemForSale(uint256 tokenId, uint256 price) 
        external 
        payable
        returns (uint256){
        require(!activeItems[tokenId], "Item is already up for sale");
        require(ownerOf(tokenId) == msg.sender, "You are not the token owner");

        uint256 newItemId = itemsForSale.length;
        itemsForSale.push(ItemForSale({
            id: newItemId,
            tokenId: tokenId,
            seller: payable(msg.sender),
            price: price,
            isSold: false
        }));
        activeItems[tokenId] = true;

        _transfer(msg.sender, address(this), tokenId);

        assert(itemsForSale[newItemId].id == newItemId);
        emit itemAddedForSale(newItemId, tokenId, price, msg.sender, false);
        return newItemId;
    }

    // Creates the sale of a marketplace item 
    // I need to check if this is okay, here we give the listingPrice for our pool, as the nft was sold.
    function buyItem(uint256 id) 
        ItemExists(id)
        IsForSale(id)
        payable 
        external {
        require(msg.value >= itemsForSale[id].price, "Not enough funds sent");
        require(msg.sender != itemsForSale[id].seller);

        itemsForSale[id].isSold = true;
        activeItems[itemsForSale[id].tokenId] = false;

        _transfer(address(this), msg.sender, itemsForSale[id].tokenId);
        
        payable(itemsForSale[id].seller).transfer(msg.value);

        _itemsSold.increment();

        emit itemSold(id, msg.sender, itemsForSale[id].price, true);
        }

    function totalItemsForSale() public view returns(uint256) {
        return itemsForSale.length;
    }

}