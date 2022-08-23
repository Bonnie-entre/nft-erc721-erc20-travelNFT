// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFT is ERC721A, Ownable {
    uint256 MAX_MINTS = 5;
    uint256 MAX_SUPPLY = 3333;
    uint256 public mintPrice = 0.005 ether;

    // Allowlist (whitelist)
    bytes32 public root;

    // Metadata, Uri
    string public baseURI = "ipfs://QmTupSXieyjY9Sc9zCf4v7gmAHtnCWXrfyrt8XqzWrJhVE/";

    // Market
    bool public isPublicSaleActive = false;
    bool public isWhiteSaleActive = false;


    constructor() ERC721A("Travel seatBelt", "seatBelt") {}

    function mintAllowList(bytes32[] memory proof, uint256 quantity) public payable {
        require(isWhiteSaleActive, "Allowlist mint is not active");
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");

        uint256 numMinted = _numberMinted(msg.sender);
        require(quantity + numMinted <= MAX_MINTS, "Exceeded the personal limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Seatbelts left");
        if(numMinted>=1){
            require(msg.value >= (mintPrice * quantity), "Not enough ether sent");
        }
        else{
            if(quantity==5){
                require(msg.value >= (mintPrice * 3), "Not enough ether sent");
            }
            else{
                require(msg.value >= (mintPrice * (quantity-1)), "Not enough ether sent");
            }
            
        }
        _safeMint(msg.sender, quantity);
    }

    function mintPublic(uint256 quantity) public payable {
        require(isPublicSaleActive, "Public mint is not active");

        uint256 numMinted = _numberMinted(msg.sender);
        require(quantity + numMinted <= MAX_MINTS, "Exceeded the personal limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Seatbelts left");
        if(numMinted>=1){
            require(msg.value >= (mintPrice * quantity), "Not enough ether sent");
        }
        else{
            if(quantity==5){
                require(msg.value >= (mintPrice * 3), "Not enough ether sent");
            }
            else{
                require(msg.value >= (mintPrice * (quantity-1)), "Not enough ether sent");
            }
            
        }
        _safeMint(msg.sender, quantity);
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function devMint(uint256 quantity) external payable onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Seatbelts left");
        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _seatURI) external onlyOwner {
        baseURI = _seatURI;
    }
    
    function setIsWhiteSaleActive(bool _newState) external onlyOwner {
        isWhiteSaleActive = _newState;
    }

    function setIsPublicSaleActive(bool _newState) external onlyOwner {
        isPublicSaleActive = _newState;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

}
