// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// import "erc721a/contracts/ERC721A.sol";
import "./ERC721A.sol";
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


    constructor() ERC721A("Passenger", "Passenger") {}

    /** 
     * @dev use AUX to record whether mintGive & mintAllowList or not
     * =0: no mintGive, no mintAllowList
     * =1: no mintGive, mintAllowList
     * =2: mintGive, mintAllowList
     * =3: mintGive, no mintAllowList
     * */ 
    function mintAllowList(bytes32[] memory proof, uint256 quantity) external payable {
        require(isWhiteSaleActive, "Allowlist mint is not active");
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        require(quantity <= MAX_MINTS, "Exceeded the personal limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Seatbelts left");
        uint64 _aux = _getAux(_msgSender());
        require(_aux == 0 || _aux == 3, "You have already mint whitelist");
        if(quantity==5){
            require(msg.value >= 0.02 ether, "Not enough ether sent");
        }
        else{
            require(msg.value >= (mintPrice * quantity), "Not enough ether sent");
        }
        
        _safeMint(msg.sender, quantity);

        if(_aux==0){
            _setAux(_msgSender(), 1);
        }
        else{
            _setAux(_msgSender(), 2);
        }
    }

    function mintPublic(uint256 quantity) external payable {
        require(isPublicSaleActive, "Public mint is not active");
        require(quantity <= MAX_MINTS, "Exceeded the personal limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Seatbelts left");

        if(quantity==5){
            require(msg.value >= 0.02 ether, "Not enough ether sent");
        }
        else{
            require(msg.value >= (mintPrice * quantity), "Not enough ether sent");
        }

        _safeMint(msg.sender, quantity);
    }
    /**
     * @dev can get one for free, if fill one other address can give 1 free token as present 
     * if not, need to fill in 0x0000000000000000000000000000000000000000, then only caller can get one for free
    */
   //
    function mintGive(address receiver) external {
        require(isPublicSaleActive, "Public mint is not active");
        require( receiver != _msgSender(), "You cannot fill in your own address");
        uint64 _aux = _getAux(_msgSender());
        require(_aux < 2, "You have already mint free give");
        if ( receiver == address(0)){
            require(totalSupply() + 1 <= MAX_SUPPLY, "Not enough Seatbelts left");
        }
        else{
            require(totalSupply() + 2 <= MAX_SUPPLY, "Not enough Seatbelts left");
            _safeMint(receiver, 1);
        }
        _safeMint(msg.sender, 1);

        if(_aux==0){
            _setAux(_msgSender(), 3);
        }
        else{
            _setAux(_msgSender(), 2);
        }
    }

    function burnSeat(uint256 tokenId) external{
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
    * 
    * who heve token pledged, still can call function setApprovalForAll
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
            require(prevOwnership.addr == to, "This NFT does not belong to this address");
        }
        else{
            require(prevOwnership.extraData == 0, "This NFT has already been pledged");  //extradata=0=pledged
            require(prevOwnership.addr == from, "This NFT is not yours");
        }
        
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

    function getNumOfBurned(address ownerAddr) public view returns(uint256){
        return _numberBurned(ownerAddr);
    }

    function getMintStatus() external view returns(uint64){
        return _getAux(_msgSender());
    }

}
