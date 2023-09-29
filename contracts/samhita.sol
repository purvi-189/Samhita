// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./ITemplateNFT.sol";
import "./ISamhitaToken.sol";
import "./ITimelock.sol";
import "hardhat/console.sol";

contract Samhita {
    string public constant name = "Samhita";

    // 4% of 1000
    function quorumVotes() public pure returns (uint256) {
        return 40;
    }   

    function proposalMaxOperations() public pure returns (uint256) {
        return 10;
    }

    function proposalThreshold() public pure returns (uint256) {
        return 10;
    }

    function votingDelay() public pure returns (uint256) {
        return 1;
    } // 1 block

    function votingPeriod() public pure returns (uint256) {
        return 40;
    } // 10 min ==> 40 blocks

    ITimelock public timelock;
    ISamhitaToken public token;
    ITemplateNFT public templateNFT;
    uint256 public proposalCount;
    address public guardian;

    struct Proposal {
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
    }

    mapping(uint256 => mapping(address => Receipt)) public proposalReceipts;

    struct Receipt {
        bool hasVoted;
        bool support;
        uint96 votes;
    }
    // states proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public latestProposalIds;
    mapping(address => uint256) public memberWithdrawAmount;
    mapping(uint256 => address) public proposalToNFTOwner; // mapping for NFT owner if proposal succeeded
    mapping(address => bool) public receivedTemplateNFT;

    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
    event VoteCast(
        address voter,
        uint256 proposalId,
        bool support,
        uint256 votes
    );
    event ProposalCanceled(uint256 id);
    event ProposalQueued(uint256 id, uint256 eta);
    event ProposalExecuted(uint256 id);

    address[] allDaoMemberAddress;
    mapping(address => bool) public isMemberAdded;
    uint96 public proposalStake = 5000000000000000000; //5 ETH
    uint96 requiredTokens = 10; //  tokens required to be member

    constructor(address timelock_, address token_, address templateNFT_) {
        timelock = ITimelock(timelock_);
        token = ISamhitaToken(token_);
        templateNFT = ITemplateNFT(templateNFT_);
        guardian = msg.sender;
        isMemberAdded[msg.sender] = true;
    }

    function addMember(uint96 _tokens) public payable {
        require(
            _tokens >= requiredTokens,
            "You must purchase at least 10 tokens to become a member"
        );
        require(
            msg.value == (_tokens * token.getTokenPrice()),
            "Not enough value"
        );
        require(
            token.balanceOf(address(this)) >= _tokens,
            "Contract does not have enough samhitaTokens"
        );
        if (!isMemberAdded[msg.sender]) {
            allDaoMemberAddress.push(msg.sender);
            isMemberAdded[msg.sender] = true;
        }
        token.transfer(msg.sender, (_tokens * 10 ** 18));
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        string memory category,
        string memory proposalFile
    ) public payable returns (uint256) {
        require(
            isMemberAdded[msg.sender],
            "You are not the member of ths Samhita DAO"
        );
        require(
            msg.value == proposalStake,
            "You must have valid stake amount to create a proposal"
        );
        require(
            token.getPriorVotes(msg.sender, sub256(block.number, 1)) >
                proposalThreshold(),
            "proposer votes below proposal threshold"
        );
        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "proposal function information arity mismatch"
        );
        require(targets.length != 0, "some action must be there");
        require(targets.length <= proposalMaxOperations(), "too many actions");
        token.transferFrom(msg.sender, address(this), proposalStake);
        // retrives latest proposalid submitted by msg.sender
        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            //means proposer has submitted the proposal before
            ProposalState latestProposalState = state(latestProposalId); /// state based on ID
            require(
                latestProposalState != ProposalState.Active,
                "Found an already active proposal"
            );
            require(
                latestProposalState != ProposalState.Pending,
                "Found an already pending proposal"
            );
        }
        uint256 startBlock = add256(block.number, votingDelay()); //  represents the number of blocks that must pass after the proposal is submitted before the voting can start.
        uint256 endBlock = add256(startBlock, votingPeriod()); // time for which voting will be open

        proposalCount++;
        proposals[proposalCount] = Proposal(
            proposalCount,
            msg.sender,
            0,
            targets,
            values,
            signatures,
            calldatas,
            startBlock,
            endBlock,
            0,
            0,
            false,
            false,
            false,
            category,
            proposalFile
        );
        latestProposalIds[msg.sender] = proposalCount;

        emit ProposalCreated(
            proposalCount,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            startBlock,
            endBlock,
            description
        );
        return proposalCount;
    }

    function queue(uint256 _proposalId) public {
        // checks current state is succeeded or not
        require(
            state(_proposalId) == ProposalState.Succeeded,
            "proposal can only be queued if it is succeeded"
        );
        require(
            keccak256(abi.encodePacked(proposals[_proposalId].category)) ==
                keccak256(abi.encodePacked("template")),
            "Not a template proposal"
        );

        // memberWithdrawAmount[proposals[_proposalId].creator] += proposalStake;


          // Store the NFT owner in the mapping
            proposalToNFTOwner[_proposalId] = proposals[_proposalId].creator;
            receivedTemplateNFT[msg.sender] = true;

        // fetches data assciated with proposal
        Proposal storage proposal = proposals[_proposalId];
        // timestamp at which prop is executed
        uint256 eta = add256(block.timestamp, timelock.delay()); // 600
        // loop for all actions in proposal
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            // queue each actions
            _queueOrRevert(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta
            );
        }
        //record timestamp at which prop can be executed
        proposal.eta = eta;  

         token.transfer(proposals[_proposalId].creator, proposalStake);


        // Template NFT -- if proposal is approved ; means succeeded
        //    mint NFT as proposal is succeed
        if (receivedTemplateNFT[msg.sender] == false) {
            templateNFT.mintTemplate(
                proposals[_proposalId].creator,
                proposals[_proposalId].proposalFile,
                _proposalId
            );
          

        }

        // Returning stake as proposal succeeded
        // address _member = proposals[_proposalId].creator;
        // memberWithdrawAmount[_member] += proposalStake;
        

        emit ProposalQueued(_proposalId, eta);
    }

    function _queueOrRevert(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        //encoding the data and then computing hash  this requ checks prop actions is already queued or not
        require(
            !timelock.queuedTransactions(
                keccak256(abi.encode(target, value, signature, data, eta))
            ),
            " proposal action already queued at eta"
        );

        timelock.SetTempSender(msg.sender);
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint256 _proposalId) public payable {
        require(
            state(_proposalId) == ProposalState.Queued,
            "proposal can only be executed if it is queued"
        );
        Proposal storage proposal = proposals[_proposalId];
        proposal.executed = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value: proposal.values[i]}(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i]
            );
        }
        emit ProposalExecuted(_proposalId);
    }

    function cancel(uint256 _proposalId) public {
        require(
            state(_proposalId) != ProposalState.Executed,
            "cannot cancel executed proposal"
        );
        Proposal storage proposal = proposals[_proposalId];
        // prop can't be canceled if gained enough votes
        require(
            msg.sender == guardian ||
                token.getPriorVotes(proposal.creator, sub256(block.number, 1)) <
                proposalThreshold(),
            "proposer above threshold"
        );
        proposal.cancel = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalCanceled(_proposalId);
    }

    // used to determine current state of spec prop
    function state(uint256 _proposalId) public view returns (ProposalState) {
        require(
            proposalCount >= _proposalId && _proposalId > 0,
            "invalid proposal id"
        );
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.cancel) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            // curr block is less than SB -> voting period is not started
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (
            proposal.forVotes <= proposal.againstVotes ||
            proposal.forVotes < quorumVotes()
        ) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (
            block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())
        ) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint256 _proposalId, bool support) public {
        return _castVote(msg.sender, _proposalId, support);
        
    }
    // updates the vote count and records the voter's receipt (record of vote) for the given proposal
    function _castVote(
        address voter,
        uint256 _proposalId,
        bool support
    ) internal {
        require(state(_proposalId) == ProposalState.Active, "voting is closed");
        Proposal storage proposal = proposals[_proposalId];

        // receipt of the voter for given prop
        Receipt storage receipt = proposalReceipts[_proposalId][voter];

        require(receipt.hasVoted == false, "voter has already voted");
        uint96 votes = token.getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }
        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;
        emit VoteCast(voter, _proposalId, support, votes);
    }

             // Function to fetch proposal.forVotes
   function getForVotes(uint proposalId) public view returns (uint) {
    require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
    console.log(proposals[proposalId].forVotes);
    return proposals[proposalId].forVotes;
   }
 
    // function getAllTemplates() public view returns (Proposal[] memory) {
    //     uint totalTemplates = 0;
    //     Proposal[] memory allProposals = new Proposal[](totalTemplates);
    //     uint j = 0; // Initialize j outside the loop

    //     for (uint i = 0; i < proposalCount; i++) {
    //         // Start from 1, not 0
    //         Proposal storage proposal = proposals[i];
    //         if (
    //             keccak256(abi.encodePacked(proposal.category)) ==
    //             keccak256(abi.encodePacked("template")) &&
    //             state(i) == ProposalState.Succeeded
    //         ) {
    //             totalTemplates++;
    //         }
    //     }
    //     // Store all succeeded proposals

    //     for (uint i = 0; i < totalTemplates; i++) {
    //         Proposal storage proposal = proposals[i];
    //         if (
    //             keccak256(abi.encodePacked(proposal.category)) ==
    //             keccak256(abi.encodePacked("template")) &&
    //             state(i) == ProposalState.Succeeded
    //         ) {
    //             allProposals[j] = proposal; // Use proposal, not proposals
    //             j++;
    //         }
    //     }
    //     return allProposals;
    // }

    function add256(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }
}
