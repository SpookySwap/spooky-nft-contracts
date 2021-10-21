// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// copied from https://etherscan.io/address/0xbd3531da5cf5857e7cfaa92426877b022e612cf8#code
// modified ERC721Pausable to use @openzeppelin contract
// modified PRICE to 150
// removed reveal_timestamp, creatorAddress, devAddress

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Magicats is ERC721Enumerable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    mapping (address => uint) claimWhitelist;
    string public MAGICATS_PROVENANCE = "";
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public revealTimestamp;
    uint256 public claimTimestampEnd;
    uint256 public whitelistedElements;
    uint256 public constant MAX_ELEMENTS = 5000;
    uint256 public constant PRICE = 150 * 10**18;
    uint256 public constant MAX_BY_MINT = 10;
    address public constant creatorAddress = 0x0000000000000000000000000000000000000000;
    address public constant devAddress = 0x0000000000000000000000000000000000000000;
    string public baseTokenURI;

    bool public saleOpen = false;
    bool public canChangeURI = true;

    event CreateCat(uint256 indexed id);
    constructor(string memory baseURI) ERC721("Magicats", "MGC") {
        setBaseURI(baseURI);
        revealTimestamp = block.timestamp + (86400 * 7); // reveal in 7 days
        claimTimestampEnd = block.timestamp + (86400 * 2); // claim window is 2 days
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(saleOpen, "saleIsOpen: sale not open");
        }
        _;
    }

    function addToWhitelist(address[] memory addrs, uint[] memory quantity) public onlyOwner {
        require(addrs.length == quantity.length, "Addrs and quantity should have the same number of elements");

        for (uint256 i = 0; i < addrs.length; i++) {
            claimWhitelist[addrs[i]] = quantity[i];
            whitelistedElements += quantity[i];
        }
    }
    function removeFromWhitelist(address addr) public onlyOwner {
        claimWhitelist[addr] = 0;
    }
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
    function _setStartingIndexBlock() internal {
        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (_totalSupply() == MAX_ELEMENTS || block.timestamp >= revealTimestamp)) {
            startingIndexBlock = block.number;
        } 
    }
    function _maxNonWhitelistElements() internal view returns (uint) {
        if (block.timestamp <= claimTimestampEnd) {
            return MAX_ELEMENTS - whitelistedElements;
        }

        return MAX_ELEMENTS;
    }
    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= _maxNonWhitelistElements(), "Max limit");
        require(total <= _maxNonWhitelistElements(), "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }

        _setStartingIndexBlock();
    }
    function claim(address _to) public saleIsOpen {
        require(claimWhitelist[msg.sender] > 0, "Address not whitelisted");
        require(block.timestamp <= claimTimestampEnd, "Claim window has expired");

        for (uint256 i = 0; i < claimWhitelist[msg.sender]; i++) {
            _mintAnElement(_to);
        }

        claimWhitelist[msg.sender] = 0;

        _setStartingIndexBlock();
    }
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateCat(id);
    }
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // permanently revoke ability to change URI
    function revokeSetURIAbility() public onlyOwner {
        canChangeURI = false;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(canChangeURI, "Ability to change URI was revoked");
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setSaleStatus(bool val) public onlyOwner {
        saleOpen = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(devAddress, balance.mul(35).div(100));
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRevealTimestamp(uint256 newRevealTimestamp) public onlyOwner {
        revealTimestamp = newRevealTimestamp;
    }

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        MAGICATS_PROVENANCE = provenanceHash;
    }
    
    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_ELEMENTS;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_ELEMENTS;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }
}