    // SPDX-License-Identifier: MIT

    pragma solidity ^0.8.19;
    import "hardhat/console.sol";
    contract LangToken{

        string public constant name = "LangToken";
        string public constant symbol = "LTK";

        uint public constant decimals = 18;
        uint public constant totalSupply = 1000000000000000000000 ;    // 1000 eth
        
        uint256 tokenPrice = 10000000000000000000;
        // token balances for each account
        mapping(address => uint96) internal balances;
        mapping (address => address ) public delegates;

        // record of voting power
        struct Checkpoint{
            uint32 fromBlock;
            uint96 votes;
        }   
        //record of votes checkpoint for each account
        // add as key => (block no => struct )
        mapping(address => mapping(uint32 => Checkpoint))  public checkpoints;

        // no of checkpoint for each account
        mapping(address => uint32) public numCheckpoints;
        bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

        /// @notice The EIP-712 typehash for the delegation struct used by the contract
        bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
        //  amt on behalf of others
        mapping (address => mapping (address => uint96)) internal allowances;
        mapping (address => uint) public nonces;

        event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
        event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

        event Transfer(address indexed from, address indexed to, uint amount);
        event Approval(address indexed owner, address indexed spender, uint256 amount);

        constructor(){
            balances[msg.sender] = uint96(totalSupply);
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        function allowance(address admin, address spender) external view returns (uint){
            return allowances[admin][spender];
        }

        function approve(address spender, uint val)external returns (bool) {
            uint96 amt;

            if(val == uint (2**256- 1) ){
                amt = uint96(2**96 -1);
            }
            else{
                amt = safe96(val, "amount exceeds 96 bits");
            }
            allowances[msg.sender][spender] = amt;
            emit Approval(msg.sender, spender, amt);

            return true;
        }

        function balanceOf(address account) external view returns (uint) {
            return balances[account];
        }
            // transfers amt tokens from msg.sender to dest
        function transfer(address dst, uint96 rawAmount) payable external  returns (bool) {
            uint96 amount = safe96(rawAmount, "transfer: amount exceeds 96 bits");
            transferTokens(msg.sender, dst, amount);
            return true;
        }

        function transferFrom(address src, address dest, uint96 rawAmount) payable external returns (bool) {
            address spender = msg.sender;
            uint96 spenderAllowance = allowances[src][spender];
            uint96 amount = safe96(rawAmount, " amount exceeds 96 bits");

            if (spender != src && spenderAllowance != uint96(2**96-1)) {
                uint96 newAllowance = sub96(spenderAllowance, amount, "transfer amount exceeds spender allowance");
                allowances[src][spender] = newAllowance;

                emit Approval(src, spender, newAllowance);
            }
            transferTokens(src, dest, amount);
            return true;
        }

        // transfer tokens from source to dest   
        function transferTokens(address src, address dest, uint96 amt) public{
            require(src != address(0) , "cannot transfer from 0 address");
            require(dest != address(0) , "cannot transfer to 0 address");
    
            balances[src] = sub96(balances[src] , amt, "transfer amt is more than balance");
            balances[dest] = add96(balances[dest], amt, "transfer amount overflows"); 
            emit Transfer(src, dest, amt);
            //trsnfered tokens so moving delegates
            moveDelegates(delegates[src] , delegates[dest], amt);
        }
        
        function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
            bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
            bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
            address signatory = ecrecover(digest, v, r, s);
            require(signatory != address(0), "invalid signature");
            require(nonce == nonces[signatory]++, "invalid nonce");
            require(block.timestamp <= expiry, "signature expired");
            return delegateTransfer(signatory, delegatee);
        }


        // curent voting power with specific account
        // votes of the latest block is extracted
        function getCurrentVotes(address account) external view returns (uint96) {
            uint32 nCheckpoints = numCheckpoints[account];
            return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        }

        // allows to get voting power of blockNo.
        function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
            require(blockNumber < block.number, "getPriorVotes: not yet determined");

            uint32 nCheckpoints = numCheckpoints[account];
            if (nCheckpoints == 0) {
                return 0;
            }

            // First check most recent balance
            if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
                return checkpoints[account][nCheckpoints - 1].votes;
            }

            // Next check implicit zero balance
            if (checkpoints[account][0].fromBlock > blockNumber) {
                return 0;
            }

            uint32 lower = 0;
            uint32 upper = nCheckpoints - 1;
            while (upper > lower) {
                uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
                Checkpoint memory cp = checkpoints[account][center];
                if (cp.fromBlock == blockNumber) {
                    return cp.votes;
                } else if (cp.fromBlock < blockNumber) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }
            return checkpoints[account][lower].votes;
        }

        function delegate(address to) payable  public {
            return delegateTransfer(msg.sender, to);
        }

        //tranfering the delegator and delegates  and moveDelegates
        function delegateTransfer(address from , address to) public {
            address curr = delegates[from]; // address of current
            uint96 fromBal = balances[from]; // balance of delegator
            delegates[from] =  to;  //This line updates the delegate of the from address to the specified to address. This effectively means that the voting power associated with the tokens held by the from address will now be delegated to the to address.

            emit DelegateChanged(from, curr, to);
            //. The event includes information about the previous delegate (curr) and the new delegate (to).
            moveDelegates(curr , to, fromBal);
        }
        
        // updating the voting power associated with two address
        // called whem change in voting power or when tokens are transfered betwn address
        function moveDelegates(address srcRep, address destRep, uint96 amt) public {
        if (srcRep != destRep && amt > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];  // blocknum
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;

                // Ensure srcRep has enough tokens to subtract and meets the minimum balance requirement
                require(srcRepOld >= amt && srcRepOld >= 10000, "Insufficient voting power or balance");


                uint96 srcRepNew = sub96(srcRepOld, amt, "votes amt underflows");
                writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (destRep != address(0)) {
                uint32 destRepNum = numCheckpoints[destRep];
                uint96 destRepOld = destRepNum > 0 ? checkpoints[destRep][destRepNum - 1].votes : 0;
                uint96 destRepNew = add96(destRepOld, amt, "votes amt overflows");

                writeCheckpoint(destRep, destRepNum, destRepOld, destRepNew);
            }
        }
    }
        //  when change in voting power 
    function writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) public {
    
        uint32 blockNumber = safe32(block.number, "block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        }
        else {
                        // new voting power
            if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock < blockNumber) {

                // Create an intermediate checkpoint at the current block number
                checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, checkpoints[delegatee][nCheckpoints - 1].votes);
                nCheckpoints++;
            }
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
        }

      function setTokenprice(uint _tokenPrice) public {
        tokenPrice = _tokenPrice;
        }

     function getTokenPrice() public view returns (uint) {
        return tokenPrice;
        }
            // used to ensure that given value is converted to 96 bit unsigned int 
            // n is unsigned int
            // value of n is less than 2**96. In other words, it ensures that the value 
            //  of n can be represented using 96 bits without causing an overflow.
        function safe96(uint n, string memory errMsg) internal pure returns (uint96){
            
            require(n < 2**96, errMsg);
            return uint96(n);
        }
        
        function safe32(uint n, string memory errMsg) internal pure returns (uint32) {
            require(n < 2**32, errMsg);
            return uint32(n);
        }

        function sub96(uint96 x, uint96 y, string memory errMsg) internal pure returns(uint96){
            require(y<=x , errMsg);
            return x-y;
        }
        
        function add96(uint96 x, uint96 y, string memory errMsg) internal pure returns(uint96){
            uint96 z = x+y;
            require( z>=y, errMsg);
            return z;
        }

        function getChainId() internal view returns (uint) {
            uint256 chainId;
            assembly { chainId := chainid() }
            return chainId;
        }

    }
