// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

    contract TemplateNFT is ERC721, ERC721URIStorage, Ownable {
    constructor() ERC721("MyTemplate", "MTL") {}

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _creatorIdCounter;
    Counters.Counter private  _memberIdCounter;

    struct TemplateData {
        uint tokenIds;
        address creator;
        string tokenIpfsUri;
    }

    struct creatorData{
        uint  creatorId;
        address owner;
        string badgeIpfsUri;

    }
    struct memberData{
        uint memberId;
        address member;
        string memberIpfsUri;
    }

    mapping(address => uint[]) public templateIdToUser;
    mapping(uint => TemplateData) public idToTemplateData;
    mapping(uint => uint) public proposalIdToTempId;

    // creator NFT
    mapping(address => uint[]) public userTocreatorNFTs;
    mapping(uint => creatorData) public creatorIdTocreatorData;

    // member NFT
    mapping(address => bool) public memberNFTReceived;

    mapping(address => uint[]) public userTomemberNFTs;
    mapping(uint => memberData) public memberIdTomemberData;



    function safeMint(address to, uint256 tokenId, string memory uri) public {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

       function safeMintOwnership(address to, uint256 creatorId, string memory uri) public {
        // _safeMintOwnership(to,creatorId );
        _safeMint(to, creatorId);
        _setTokenURI(creatorId, uri);
    }

    function mintTemplate(
        address _to,
        string memory _uri,
        uint _proposalId
    ) public {
        uint256 tokenId = _tokenIdCounter.current();
        proposalIdToTempId[_proposalId] = tokenId;

        _tokenIdCounter.increment();
        safeMint(_to, tokenId, _uri);
        templateIdToUser[_to].push(tokenId);
        idToTemplateData[tokenId] = TemplateData(tokenId, _to, _uri);
    }


    function mintcreatorNFT(address _to, string memory _uri)public onlyOwner() {
      
        uint256 creatorId = _creatorIdCounter.current(); // Get the unique creator ID
        _creatorIdCounter.increment();

        safeMintOwnership(_to, creatorId, _uri);
        // Store creator data associated with the creatorId.
        creatorIdTocreatorData[creatorId] = creatorData(creatorId, _to, _uri);

        // Add the creatorId to the user's list of owned creator NFTs.
        userTocreatorNFTs[_to].push(creatorId);
    }

    // member NFT

    function mintMemberNFT(address _to, string memory _uri) public {
            
        uint256 memberId = _memberIdCounter.current(); // Get the unique creator ID
        _memberIdCounter.increment();
         safeMintOwnership(_to, memberId, _uri);

        //   Store creator data associated with the creatorId.
        memberIdTomemberData[memberId] = memberData(memberId, _to, _uri);

        // Add the creatorId to the user's list of owned creator NFTs.
        userTomemberNFTs[_to].push(memberId);
        memberNFTReceived[_to] = true;

    }


    // Function to retrieve all creator NFTs owned by a user.
    function getUsercreatorNFTs(address _user) public view returns (uint[] memory) {
        return userTocreatorNFTs[_user];
    }



     // Function to retrieve creator data for a specific creator NFT.
    function getcreatorData(uint _creatorId) public view returns (creatorData memory) {
        return creatorIdTocreatorData[_creatorId];
    }

   
    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function getAlltemplateIDS(
        address _user
    ) public view returns (uint[] memory) {
        return templateIdToUser[_user];
    }

    function getTemplateData(
        uint _templateId
    ) public view returns (TemplateData memory) {
        return idToTemplateData[_templateId];
    }

    function getTemplateDetails(
        uint _templateId
    ) public view returns (address) {
        return idToTemplateData[_templateId].creator;
    }

     // Override supportsInterface to specify which base contract's function to use
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
