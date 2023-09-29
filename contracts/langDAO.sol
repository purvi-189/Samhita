//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// import "hardhat/console.sol";
// import "./ITemplateNFT.sol";
// contract LangDAO {

//     string public constant name = "langDAO";
//     function quorumVotes() public pure returns (uint256) { return 40;  } //1000 --4%  ==30
//     // maxx no of action that can be included in proposal
//     function proposalMaxOperations() public pure returns (uint256) { return 10; } // each proposal can contain upto 10 action
//     // min req of 1% of total supply that propser must hold to create a new proposal
//     function proposalThreshold() public pure returns (uint256) { return 10;} // 1% of 1000
//     // delay before voting can begin
//     function votingDelay() public pure returns (uint256) {   return 1; }  //1 block
//     function votingPeriod() public pure returns (uint256) {
//         return 40;
//     } // 10 min ==> 40 blocks
//     TimelockInterface public timelock;
//     langTokenInterface public langtoken;
//     ITemplateNFT public templateNFT;
//     uint256 public proposalCount;
//     address public guardian;
//     uint96 public royaltyFee = 10000000000000000000; // 10 eth
//     uint256 public proposalStake = 5000000000000000000; //5 ETH
//     uint256 public total = royaltyFee + proposalStake;
//     struct Proposal {
//         uint256 id;
//         address creator;
//         uint256 eta;
//         address[] targets; // list of add for calls to be made
//         uint256[] values;
//         string[] signatures;
//         bytes[] calldatas;
//         uint256 startBlock;
//         uint256 endBlock;
//         uint256 forVotes;
//         uint256 againstVotes;
//         bool cancel;
//         bool executed;
//         string proposalFile;
//         uint256 templateId;
//     }
//     mapping(uint256 => mapping(address => Receipt)) public proposalReceipts;
//     struct Receipt {
//         bool hasVoted;
//         bool support;
//         uint96 votes;
//     }
//     struct Badge{
//         string creatorBadge;
//         string memberBadge;
//     }
//     // states proposal may be in
//     enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed}
//     mapping(uint256 => Proposal) public proposals;
//     mapping(address => uint256) public latestProposalIds;
//     mapping(address => uint256) public memberWithdrawAmount;
//     mapping(address => bool) public isMemberAdded;
//     // when proposal is created
//     event ProposalCreated(uint256 id,address proposer, address[] targets, uint256[] values,string[] signatures, bytes[] calldatas,uint256 startBlock,uint256 endBlock, string description);
//     //   when a vote has been cast on a proposal
//     event VoteCast(  address voter,uint256 proposalId,bool support,uint256 votes);
//     // when a proposal has been canceled
//     event ProposalCanceled(uint256 id);
//     //  when a proposal has been queued in the Timelock
//     event ProposalQueued(uint256 id, uint256 eta);
//     //  when a proposal has been executed in the Timelock
//     event ProposalExecuted(uint256 id);
//     address[] allDaoMemberAddress;

//     struct member {
//         uint256 memberID;
//         address memberAdd;
//     }
//     uint256 public nextMemberID = 1;
//     mapping(address => member) public members;
//     // voters array on proposal
//     mapping(uint256 => address[]) public votersForProposal;
//     // mapping for ownership (lang DAO)
//     mapping(uint256 => address) public langDAOcreator;
//     // for voting
//     mapping(address => uint256) public memberVotes;
//     mapping(address => uint256) public memberProposals;
//     // stake return
//    mapping(address => mapping(uint256 => bool) )public isStakeReturn ;
//       // royaltyFeeReturn
//    mapping(address=> mapping(uint256 => bool) )public royaltyFeeReturn;
//     mapping(address => bool) public receivedMemberNFT ;
//     mapping(address => bool ) public receivedCreatorNFT;

//     constructor(address timelock_,address token_, address template_, string memory creatorBadge ) {
//         timelock = TimelockInterface(timelock_);
//         langtoken = langTokenInterface(token_);
//         templateNFT = ITemplateNFT(template_);
//         guardian = msg.sender;
//         isMemberAdded[msg.sender] = true;
//         // owner NFT: when DAO is deployed

//         if(receivedCreatorNFT[msg.sender] == false){
//           templateNFT.mintcreatorNFT(msg.sender, creatorBadge);
//           receivedCreatorNFT[msg.sender] = true;
//         }
//     }
//     function addMember(uint96 _tokens) public payable {
//         require( msg.value == (_tokens * langtoken.getTokenPrice()),"Not enough value");
//         require(langtoken.balanceOf(address(this)) >= _tokens, "Contract does not have enough tokens");
//         if (!isMemberAdded[msg.sender]) {
//             allDaoMemberAddress.push(msg.sender);
//             isMemberAdded[msg.sender] = true;
//         }
//         langtoken.transfer(msg.sender, (_tokens * 10**18));
//         members[msg.sender] = member(nextMemberID, msg.sender);
//         nextMemberID++;
//     }

//     function propose(uint256 proposalId, address[] memory targets, uint256[] memory values, string[] memory signatures, bytes[] memory calldatas,  string memory proposalFile, string memory memberBadge ) public payable returns (uint) {
//         require(msg.value == total,"You must have valid stake amount to create a proposal");
//         require(langtoken.getPriorVotes(msg.sender, sub256(block.number, 1)) >proposalThreshold(),"proposer votes below proposal threshold" );
//         require(targets.length == values.length &&  targets.length == signatures.length && targets.length == calldatas.length, "proposal function information arity mismatch");
//         require(targets.length != 0, "some action must be there");
//         require(targets.length <= proposalMaxOperations(), "too many actions");
//         langtoken.transferFrom(msg.sender, address(this), total);
//         // retrives latest proposalid submitted by msg.sender
//         uint256 latestProposalId = latestProposalIds[msg.sender];
//         if (latestProposalId != 0) {
//             //means proposer has submitted the proposal before
//             ProposalState latestProposalState = state(latestProposalId); /// state based on ID
//             require(latestProposalState != ProposalState.Active,"Found an already active proposal");
//             require(latestProposalState != ProposalState.Pending,"Found an already pending proposal" );
//         }
//         uint256 startBlock = add256(block.number, votingDelay()); //  represents the number of blocks that must pass after the proposal is submitted before the voting can start.
//         uint256 endBlock = add256(startBlock, votingPeriod()); // time for which voting will be open

//         // increasing count of proposal of a particular user
//         memberProposals[msg.sender]++;  proposalCount++;
//      proposals[proposalCount] = Proposal(proposalId,  msg.sender,0, targets, values, signatures, calldatas, startBlock,endBlock, 0,0, false, false, proposalFile, 1 );
//         latestProposalIds[msg.sender] = proposalId;
       
//         require(memberVotes[msg.sender] >= 3, "User has not given 3 votes");
//         require( memberProposals[msg.sender] >= 2, "User has not created a proposal");

//          if(receivedMemberNFT[msg.sender] == false){
//             if( memberProposals[msg.sender] >= 2  && memberVotes[msg.sender] >=5)  {
//             { 
//                 templateNFT.mintMemberNFT(msg.sender, memberBadge); 
//                 receivedMemberNFT[msg.sender] = true ;
//             }
//          }

//         } 
//        isStakeReturn[msg.sender][proposalId] = true;
//         return proposalCount;
//     }

//    function queue(uint256 proposalId, uint256 templateId) public {
//         require(state(proposalId) == ProposalState.Succeeded,"proposal can only be queued if it is succeeded");
//         // fetches data assciated with proposal
//         Proposal storage proposal = proposals[proposalId];
//         // timestamp at which prop is executed
//         uint256 eta = add256(block.timestamp, timelock.delay()); // 600
//         // loop for all actions in proposal
//         for (uint256 i = 0; i < proposal.targets.length; i++) {
//             _queueOrRevert(proposal.targets[i],proposal.values[i],proposal.signatures[i],proposal.calldatas[i],eta);
//         }
//         //record timestamp at which prop can be executed
//         proposal.eta = eta;
//         // Returning only stake as proposal succeeded
//         if(isStakeReturn[msg.sender][proposalCount] == true)
//         {
//            address _member = proposals[proposalId].creator;
//             memberWithdrawAmount[_member] += proposalStake;
//             isStakeReturn[msg.sender][proposalCount] = false ;   
//         }
    
//         //  royalty to template creator
//         if (proposals[proposalId].templateId > 0) {
//             address tempCreator = templateNFT.getTemplateDetails(templateId);
//             langtoken.transfer(tempCreator, royaltyFee);
//         }
//         emit ProposalQueued(proposalId, eta);
//     }
    
//     function _queueOrRevert(address target, uint256 value,string memory signature,bytes memory data,uint256 eta) internal {
//         //encoding the data and then computing hash  this requ checks prop actions is already queued or not
//         require(!timelock.queuedTransactions( keccak256(abi.encode(target, value, signature, data, eta)))," proposal action already queued at eta" );
//         timelock.SetTempSender(msg.sender);
//         timelock.queueTransaction(target, value, signature, data, eta);
//     }
//     function execute(uint256 proposalId) public payable {
//         require( state(proposalId) == ProposalState.Queued, "proposal can only be executed if it is queued");
//         Proposal storage proposal = proposals[proposalId];
//         proposal.executed = true;
//         for (uint256 i = 0; i < proposal.targets.length; i++) {timelock.executeTransaction{value: proposal.values[i]}(  proposal.targets[i], proposal.values[i], proposal.signatures[i],  proposal.calldatas[i],  proposal.eta);}
//         emit ProposalExecuted(proposalId);
//     }
//     function cancel(uint256 proposalId) public {
//         require(state(proposalId) != ProposalState.Executed,"cannot cancel executed proposal");
//         Proposal storage proposal = proposals[proposalId];
//         // prop can't be canceled if gained enough votes
//         require( msg.sender == guardian || langtoken.getPriorVotes( proposal.creator, sub256(block.number, 1)) <proposalThreshold(), "proposer above threshold");
//         proposal.cancel = true;
//         for (uint256 i = 0; i < proposal.targets.length; i++) {
//             timelock.cancelTransaction(proposal.targets[i],proposal.values[i],proposal.signatures[i],proposal.calldatas[i],proposal.eta);
//         }
//         emit ProposalCanceled(proposalId);
//     }
//     function getActions(uint256 proposalId) public view returns (   address[] memory targets,   uint256[] memory values,   string[] memory signatures,   bytes[] memory calldatas ) {
//         Proposal storage p = proposals[proposalId];
//         return (p.targets, p.values, p.signatures, p.calldatas);
//     }
//     function getReceipt(uint256 proposalId, address voter) public view returns(Receipt memory)
//     {   return proposalReceipts[proposalId][voter];  } 

//     function state(uint256 proposalId) public view  returns (ProposalState) {
//         require(proposalCount >= proposalId && proposalId > 0," invalid proposal id" );
//         Proposal storage proposal = proposals[proposalId];
//         if (proposal.cancel) {
//             return ProposalState.Canceled;
//         } else if (block.number <= proposal.startBlock) {
//             return ProposalState.Pending;
//         } else if (block.number <= proposal.endBlock) {
//             return ProposalState.Active;
//         } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()){ 
//             return ProposalState.Defeated;
//         } else if (proposal.eta == 0) {
//             return ProposalState.Succeeded;
//         } else if (proposal.executed) {
//             return ProposalState.Executed;
//         } else if ( block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
//             return ProposalState.Expired;
//         } else {
//             return ProposalState.Queued;
//         }
//     }
//     function castVote(uint256 proposalId, bool support) public {
//         return _castVote(msg.sender, proposalId, support); }

//     // updates the vote count and records the voter's receipt (record of vote) for the given proposal
//     function _castVote( address voter, uint256 proposalId,bool support) internal {
//         require(state(proposalId) == ProposalState.Active, "voting is closed");
//         memberVotes[msg.sender]++;
//         Proposal storage proposal = proposals[proposalId];

//         // receipt of the voter for given prop
//         Receipt storage receipt = proposalReceipts[proposalId][voter];

//         require(receipt.hasVoted == false, "voter has already voted");
//         uint96 votes = langtoken.getPriorVotes(voter, proposal.startBlock);
//         if (support) {
//             proposal.forVotes = add256(proposal.forVotes, votes);
//         } else {
//             proposal.againstVotes = add256(proposal.againstVotes, votes);
//         }
//         receipt.hasVoted = true;
//         receipt.support = support;
//         receipt.votes = votes;
//         emit VoteCast(voter, proposalId, support, votes);
//     }

//     function latestState(address proposer) public view returns (ProposalState) {
//         uint256 proposalId = latestProposalIds[proposer];
//         if (proposalId == 0) {
//             return ProposalState.Pending; // No proposal submitted by this proposer
//         }
//         return state(proposalId);
//     }
//     function setRoyalty(uint96 _price) public {
//         royaltyFee = _price;
//     }
//     function __abdicate() public {
//         require(msg.sender == guardian, "sender must be gov guardian");
//         guardian = address(0);
//     }
//     function __acceptAdmin() public {
//         require(msg.sender == guardian, "sender must be gov guardian");
//         timelock.acceptAdmin();
//     }
//     function add256(uint256 a, uint256 b) internal pure returns (uint256) {
//         uint256 c = a + b;
//         require(c >= a, "addition overflow");
//         return c;
//     }
//     function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b <= a, "subtraction underflow");
//         return a - b;
//     }
// }
// interface TimelockInterface {
//     function delay() external view returns (uint256);
//     function GRACE_PERIOD() external view returns (uint256);
//     function acceptAdmin() external;
//     function queuedTransactions(bytes32 hash) external view returns (bool);
//     function queueTransaction(  address target,uint256 value,string calldata signature, bytes calldata data,uint256 eta ) external returns (bytes32);
//     function cancelTransaction( address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external;
//     function executeTransaction(address target, uint256 value, string calldata signature,bytes calldata data,uint256 eta ) external payable returns (bytes memory);
//     function SetTempSender(address _address) external;
// }

// interface langTokenInterface {
//     function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
//     function getTokenPrice() external view returns (uint256);
//     function balanceOf(address account) external view returns (uint256);
//     function transfer(address dst, uint96 rawAmount)external payable returns (bool);
//     function transferFrom(  address src,  address dest, uint256 rawAmount ) external payable returns (bool);
// }