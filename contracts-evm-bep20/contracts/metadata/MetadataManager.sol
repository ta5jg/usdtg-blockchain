// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract MetadataManager is AccessControl {
    bytes32 public constant METADATA_ADMIN_ROLE = keccak256("METADATA_ADMIN_ROLE");
    
    address public metadataTokenContract;
    
    // Metadata storage
    string public logoURI;
    string public website;
    string public description;
    string public telegram;
    string public twitter;
    string public discord;
    string public github;
    
    event MetadataUpdated(string logo, string website, string description);
    event SocialLinksUpdated(string telegram, string twitter, string discord, string github);
    event LogoURIUpdated(string logo);

    constructor(address _tokenContract) {
        metadataTokenContract = _tokenContract;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(METADATA_ADMIN_ROLE, msg.sender);
    }

    modifier onlyMetadataTokenContract() {
        require(msg.sender == metadataTokenContract, "Only token contract");
        _;
    }

    function updateMetadata(
        string calldata site, 
        string calldata desc, 
        string calldata logo
    ) external onlyRole(METADATA_ADMIN_ROLE) {
        website = site;
        description = desc;
        logoURI = logo;
        emit MetadataUpdated(logo, site, desc);
    }

    function updateSocialLinks(
        string calldata _telegram,
        string calldata _twitter,
        string calldata _discord,
        string calldata _github
    ) external onlyRole(METADATA_ADMIN_ROLE) {
        telegram = _telegram;
        twitter = _twitter;
        discord = _discord;
        github = _github;
        emit SocialLinksUpdated(_telegram, _twitter, _discord, _github);
    }

    function updateLogoURI(string calldata logo) external onlyRole(METADATA_ADMIN_ROLE) {
        logoURI = logo;
        emit LogoURIUpdated(logo);
    }

    function getFullMetadata() external view returns (
        string memory logo,
        string memory website_,
        string memory description_,
        string memory telegram_,
        string memory twitter_,
        string memory discord_,
        string memory github_
    ) {
        return (
            logoURI,
            website,
            description,
            telegram,
            twitter,
            discord,
            github
        );
    }

    function getWalletMetadata() external view returns (string memory) {
        return string(abi.encodePacked(
            '{"name":"USD eXchange Token","symbol":"USDxT","decimals":18,"logoURI":"',
            logoURI,
            '","website":"',
            website,
            '","description":"',
            description,
            '","socials":{"telegram":"',
            telegram,
            '","twitter":"',
            twitter,
            '","discord":"',
            discord,
            '","github":"',
            github,
            '"}}'
        ));
    }

    function getTokenMetadata() external pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{',
                    '"name":"USD exchange Token",',
                    '"symbol":"USDxT",',
                    '"description":"A multi-chain stable utility token backed by TG Group.",',
                    '"decimals":"6",',
                    '"logoURI":"https://yourdomain.com/images/usdxt_logo.png"',
                '}'
            )
        );
    }

}