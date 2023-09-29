// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISamhitaToken {
    struct Proposal{
         uint256 id;
        address creator;
        uint256 eta;
        address[] targets; // list of add for calls to be made
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool cancel;
        bool executed;
        bool isScrape; // true ==> scrape else its datacraft
        string category; // template , governance, finance
        string proposalFile;
        // mapping(address => Receipt) receipts;
    }

     struct Receipt {
        bool hasVoted;
        bool support;
        uint96 votes;
    }

    function getPriorVotes(address account, uint256 blockNumber) external view  returns (uint96);
    function getTokenPrice() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address dst, uint96 rawAmount) external payable returns (bool);
    function transferFrom(address src, address dest, uint96 rawAmount) payable external returns (bool);
    function getAllProposals() external view returns (Proposal[] memory) ;
     function getAllTemplates() external view returns (Proposal[] memory);
}   