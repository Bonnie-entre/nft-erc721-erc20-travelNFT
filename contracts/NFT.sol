// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFT is ERC721A, Ownable {
    uint256 constant MAX_MINTS = 5;
    uint256 constant MAX_SUPPLY = 3333;
    uint256 public mintPrice = 0.005 ether;

    // Allowlist (whitelist)
    bytes32 public root;

    // Metadata, Uri
    string public baseURI = "ipfs://QmTupSXieyjY9Sc9zCf4v7gmAHtnCWXrfyrt8XqzWrJhVE/";

    // ERC20 - Pledge
    address public _token20;
    bool private _token20Seted = false;

    // Market
    bool public isPublicSaleActive = false;
    bool public isWhiteSaleActive = false;


    constructor() ERC721A("Travel seatBelt", "seatBelt") {}

    function mintAllowList(bytes32[] memory proof, uint256 quantity) external payable {
        require(isWhiteSaleActive, "Allowlist mint is not active");
        require(_numberMinted(msg.sender)==0, "You have already claimed your seats");
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        require(quantity <= MAX_MINTS, "Exceeded the personal limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Seatbelts left");
        
        if(quantity==5){
            require(msg.value >= 0.015 ether, "Not enough ether sent");
        }
        else{
            require(msg.value >= (mintPrice * (quantity-1)), "Not enough ether sent");
        }
        
        _safeMint(msg.sender, quantity);
    }

    function mintPublic(uint256 quantity) external payable {
        require(isPublicSaleActive, "Public mint is not active");
        require(_numberMinted(msg.sender)==0, "You have already claimed your seats");
        require(quantity <= MAX_MINTS, "Exceeded the personal limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Seatbelts left");

        if(quantity==5){
            require(msg.value >= (mintPrice * 3), "Not enough ether sent");
        }
        else{
            require(msg.value >= (mintPrice * (quantity-1)), "Not enough ether sent");
        }

        _safeMint(msg.sender, quantity);
    }

    function burnSeat(uint256 tokenId) external{
        TokenOwnership memory prevOwnership = _ownershipAt(tokenId);
        require(prevOwnership.extraData == 0, "This NFT has already been pledged");

        _burn(tokenId, true); // no approve function, but need to check if owner
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
    * @dev set the address of erc20 contract interecting with this NFT 
    * 
    * called by once and only
    */
    function setErc20(address myErc20) external onlyOwner {
        require(!_token20Seted, "Token20 has been already set");
        //I trust that there is no one in team will randomly send some wrong contract to this function;
        _token20 = myErc20;
        _token20Seted = true;
    }

    /**
    * @dev set pledge status of NFT without change owner and owner's balance record 
    * 
    * Requirements:
    * - only call by the address of erc20 contract which has set by setErc20() function
    */
    function pledgeTransferFromWithoutOwnerChange(
        address from,
        address to,
        uint256 tokenId,
        uint24 isPledged
    ) external virtual {
        require(_msgSender() == _token20, "You're not our contract");

        TokenOwnership memory prevOwnership = _ownershipAt(tokenId);
        if (isPledged==0){
            require(prevOwnership.extraData == 1, "This NFT hasn't been pledged"); //extraData will be initialized to 1 when mint() & transferFrom() by erc721A
            require(prevOwnership.addr == to, "This NFT is not yours");
        }
        else{
            require(prevOwnership.extraData == 0, "This NFT has already been pledged");  //extradata=0=pledged
            require(prevOwnership.addr == from, "This NFT is not yours");
        }
        
        ////
        /* 
        * @dev 改讓其他會動用 nft 的 function 去檢查是否正在 pledge, ex. burn 
        * ERC721A 的 approve() 會被強制檢查是否為 token owner 或是 aproveall者，因此不用 approve
        * {Yolin} _approve(address(0), tokenId, prevOwnership.addr); //must
        */

       /*
       * @dev approve(addr(0), tokenid ) 可以確實阻擋正在pledge的使用者呼叫 burn, approve, transfer 嗎??
       * 1. in the pledge() in erc20, before call the pledgeTransferFromWithoutOwnerChange(), 
       *    should　setApprovalForAll(erc20.address, true) to approve erc20 execute _approve() in this pledgeTransferFromWithoutOwnerChange() function
       * 2. in the pledgeRetrieve() in erc20, after call the pledgeTransferFromWithoutOwnerChange(),
       *    should setApprovalForAll(erc20.address, false) to protect users
       * 
       */
      ////
        
        /* 
        * @dev 不因 pledge 更動持有者(from 與 to)的數量 (要麻煩在 erc20 執行時注意有沒有需要自己記錄了~)
        * ERC721A 的變數 _packedAddressData 設為 private，易無法透過改寫 transfer 來實現(限制 to ! addr(0))
        * {Yolin} _addressData[from].balance -= 1;
        * {Yolin} _addressData[to].balance += 1;
        */

        /*
        * @dev 用 _setExtraDataAt() 來記錄 plege 與否
        * {Yolin} _ownerships[tokenId].pledge = !_ownerships[tokenId].pledge; //important
        */
        _setExtraDataAt(tokenId, isPledged);
    }

    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view override returns (uint24) {
        return previousExtraData;
    }
    
    function getPledgeStatus(uint256 tokenId) public view returns(uint24){
        require(_exists(tokenId), "This seat does not exist");
        TokenOwnership memory prevOwnership = _ownershipAt(tokenId);
        return prevOwnership.extraData;
    }

    /**
    @dev `transfer` and `send` assume constant gas prices. 
    * onlyOwner, so we accept the reentrancy risk that `.call.value` carries.
    */
    function withdraw() external payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
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
