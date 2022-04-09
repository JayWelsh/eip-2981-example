//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IERC2981.sol";

// OpenZeppelin Contracts @ version 4.5.0
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC2981 is ERC721, Ownable {

    // Using Strings lib for `_tokenId.toString()` in `tokenURI`
    // If your tokenID doesn't need to be concatenated to the baseURI then this isn't needed
    using Strings for uint256;

    string public baseURI;
    address public royaltyReceiver;
    uint16 public royaltyBasisPoints;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseURI,
        address _royaltyReceiver,
        uint16 _royaltyBasisPoints
    ) public ERC721(_tokenName, _tokenSymbol) {
        baseURI = _baseURI;
        royaltyReceiver = _royaltyReceiver;
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    // We signify support for ERC2981, ERC721 & ERC721Metadata

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ERC2981 logic

    function updateRoyaltyInfo(address _royaltyReceiver, uint16 _royaltyBasisPoints) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    // Takes a _tokenId and _price (in wei) and returns the royalty receiver's address and how much of a royalty the royalty receiver is owed
    function royaltyInfo(uint256 _tokenId, uint256 _price) external view returns (address receiver, uint256 royaltyAmount) {
        // This contract assumes that all token IDs within the contract have the same royalty info (if that's not an issue, no need to read the rest of this comment)
        // The `_tokenId` param can also be used if you want each token ID to have independent royalty receivers and/or royaltyAmounts
        // (e.g. in the case of an NFT contract being shared between multiple artist, and/or a marketplace)
        // In such cases, you would need to set up a storage space for this data
        // e.g. mapping a uint256 (token ID) to a struct which stores the royalty info for each token
        receiver = royaltyReceiver;
        royaltyAmount = getPercentageOf(_price, royaltyBasisPoints);
    }

    // Uses basisPoints (i.e. 100% = 10000, 1% = 100)
    function getPercentageOf(
        uint256 _amount,
        uint16 _basisPoints
    ) internal pure returns (uint256 value) {
        value = (_amount * _basisPoints) / 10000;
    }

    // You would change this function to suit the token, right now it operates assuming the baseURI will be an IPFS folder for `.json` files
    // This is included due to supporting the IERC721Metadata interface
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Concatenate the tokenID along with the '.json' to the baseURI
        return string(abi.encodePacked(baseURI, _tokenId.toString(), '.json'));
    }
}
