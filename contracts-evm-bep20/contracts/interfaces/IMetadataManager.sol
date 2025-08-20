// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IMetadataManager {
    function updateMetadata(string calldata site, string calldata desc, string calldata logo) external;
    function updateSocialLinks(string calldata _telegram, string calldata _twitter, string calldata _discord, string calldata _github) external;
    function updateLogoURI(string calldata logo) external;
    function getFullMetadata() external view returns (string memory, string memory, string memory, string memory, string memory, string memory, string memory);
    function getWalletMetadata() external view returns (string memory);
    function getTokenMetadata() external view returns (string memory);
} 