// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract travelNFT_basic is ERC721 {
    string public constant TOKEN_URI =
        "https://ipfs.io/ipfs/QmXqEgjRdNxtyWoW9YwWX7rZyjD9geWYR16kjRv4kqS5ut?filename=bunnytoken01.json";
    uint256 private s_tokenCounter;

    /* Functions */
    constructor() ERC721("Bonnie", "Bun") {
        s_tokenCounter = 0;
    }

    function mintNft() public returns (uint256) {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter = s_tokenCounter + 1;
        return s_tokenCounter;
    }

    // overide the original one in erc721
    function tokenURI(
        uint256 /* tokenId */
    ) public view override returns (string memory) {
        // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return TOKEN_URI;
    }

    /* View/ Pure functions */
    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
