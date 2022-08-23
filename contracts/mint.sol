// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract mint is ERC721, Ownable {
    using Strings for uint256;

    // Allowlist (whitelist)
    bytes32 public root;
    bool public isAllowListActive; // can make time lag with public sell and blindbox open timing

    // Market
    bool public isSaleActive;
    uint256 internal s_saledConuter;
    uint8 public constant PUCHASE_LIMIT = 3;
    uint256 public constant SALE_LIMIT = 1000; //temporally set
    uint256 private constant PRICE_PER_TICKET = 1000000; //temporally set

    // Metadata, Uri
    bool public isBlindboxOpen;
    string private ticketURI =
        "https://ipfs.io/ipfs/QmTupSXieyjY9Sc9zCf4v7gmAHtnCWXrfyrt8XqzWrJhVE/"; //blindTokenURI

    /* Functions */
    constructor() ERC721("Go Traveling", "Trav Ticket") {
        s_saledConuter = 1;
        isSaleActive = false;
        isAllowListActive = false;
        isBlindboxOpen = false;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setSaleState(bool _newState) external onlyOwner {
        isSaleActive = _newState;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setIsBlindboxOpen(bool _isBlindboxOpen, string memory _ticketURI) external onlyOwner {
        isBlindboxOpen = _isBlindboxOpen;
        ticketURI = _ticketURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return ticketURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // _requireMinted(tokenId);
        require(tokenId < s_saledConuter, "unminted ticketID");
        string memory baseURI = _baseURI();
        return
            isBlindboxOpen
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : string(abi.encodePacked(baseURI));
    }

    /**
     * @dev free mint successfully for the first time minter
     * however, once one own the nft, should pay to mint more (free mint, >1 mint cost).
     * ps: if wanna random mint can use chainlink
     */
    function mintTicket(uint8 numOfTokens) public payable returns (uint256) {
        require(s_saledConuter + numOfTokens < SALE_LIMIT, "Ticket sale limit reached");
        require(isSaleActive || isAllowListActive, "Tickets are not allowed to sale");

        if (balanceOf(msg.sender) >= 1) {
            require(numOfTokens <= PUCHASE_LIMIT, "Exceeded max tickets purchase");
            require(msg.value >= PRICE_PER_TICKET * numOfTokens);
        }
        if (balanceOf(msg.sender) == 0 && balanceOf(msg.sender) > 1) {
            require(numOfTokens <= PUCHASE_LIMIT + 1, "Exceeded max tickets purchase");
            require(msg.value >= PRICE_PER_TICKET * (numOfTokens - 1));
        }

        for (uint8 i = 0; i < numOfTokens; i++) {
            _safeMint(msg.sender, s_saledConuter + i);
        }
        s_saledConuter = s_saledConuter + numOfTokens;
        return s_saledConuter;
    }

    // maybe creater(devMint) can use this function too
    function mintAllowList(bytes32[] memory proof, uint8 numOfTokens) public payable {
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        require(isAllowListActive, "Allow list is not active");

        //maybe we could modify this function to make those allowlist minter mint with lower price
        mintTicket(numOfTokens);
    }

    /**
     * @dev deployer can mint specific ammount of nft token without paying
     * ps. or use mintAllowList directally
     */
    function devMint(uint256 numOfTokens) external onlyOwner {
        require(s_saledConuter + numOfTokens < SALE_LIMIT, "Ticket sale limit reached");
        require(isSaleActive || isAllowListActive, "Tickets are not allowed to sale");

        for (uint256 i = 0; i < numOfTokens; i++) {
            _safeMint(msg.sender, s_saledConuter + i);
        }
        s_saledConuter = s_saledConuter + numOfTokens;
    }

    /* View/ Pure functions */
    function getTokenCounter() public view returns (uint256) {
        return s_saledConuter - 1;
    }

    function getTicketCost() public pure returns (uint256) {
        return PRICE_PER_TICKET;
    }

    function getMintRemaining() public view returns (uint256) {
        return SALE_LIMIT - s_saledConuter;
    }
}
