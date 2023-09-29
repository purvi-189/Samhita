// const { ethers } = require("hardhat");
// const { expect } = require("chai");

// describe("langDAOToken", function(){
    
//     let Token;
//     let admin;
//     let user1, user2;
//     let token;

//     beforeEach(async function(){
//         Token = await ethers.getContractFactory("LangToken");
//         [admin, user1, user2 ] = await ethers.getSigners();
//         token = await Token.connect(admin).deploy();
//         await token.deployed();

//     });
//     it("Should have correct initial values", async function () {
//         console.log("admin in langDAOToken: "+ admin.address);
//         console.log("Lang DAO Token : "+token.address);
//         expect(await token.name()).to.equal("LangToken");
//         expect(await token.symbol()).to.equal("LTK");
//         expect(await token.decimals()).to.equal(18);

//         const totalSupply = await token.totalSupply();
//         const expectedTotalSupply = ethers.utils.parseUnits("1000", 18);
    
//         expect(totalSupply).to.equal(expectedTotalSupply);
//       });
//       it("should transfer tokens between accounts", async function () {
//                 const amount = ethers.utils.parseUnits("100", 18);
              
//                 // Check user1's balance before the transfer
//                 const user1BalanceBefore = await token.balanceOf(await user1.getAddress());
                
//                 // Transfer tokens from admin to user1
//                 await token.connect(admin).transfer(await user1.getAddress(), amount);
              
//                 const user1BalanceAfter = await token.balanceOf(await user1.getAddress());
//              expect(user1BalanceAfter.sub(user1BalanceBefore)).to.equal(amount);
//               });
        
//              //--> transfer from
//                   it("should transfer tokens using transferFrom ", async function(){
//                     const amount = ethers.utils.parseUnits("100", 18);
                
//                         //approve user1 to spend tokens on behalf of admin
//                      await token.connect(admin).approve(await user1.getAddress(), amount);
//                         // u1 transfer from admin to u2
//                     await token.connect(user1).transferFrom(await admin.getAddress(), await user2.getAddress(), amount);
//                         // check u2 received
//                      expect(await  token.balanceOf(await user2.getAddress()) ).to.equal(amount);
//                         // checking that both u1 and admin has 0 balance
//                     expect(await token.allowance(await admin.getAddress(), await user1.getAddress())).to.equal(0);
//                       });
        
                    
//                       // revert if transfer more tokens than allowance
//                   it("should not allow transfer if allowance is exceeded", async function () {
//                     // Decrease the allowance to a smaller value that is within the valid range
//                      allowance = ethers.utils.parseUnits("999", 18);
                
//                     // Approve user1 to spend tokens on behalf of admin with the smaller allowance
//                     await token.connect(admin).approve( user1.getAddress(), allowance);
                
//                     // Try to transfer more tokens than the allowance
//                     await expect(
//                       token.connect(user1).transferFrom( admin.getAddress(),  user2.getAddress(), allowance+1)
//                     ).to.be.revertedWith("transfer amount exceeds spender allowance");
                
//                     // Check that user2 didn't receive any tokens
//                     expect(await token.balanceOf(await user2.getAddress())).to.equal(0);
//                   }); 
        
                  
//         //           //  Transfer Tokens
//                   it("should transfer tokens and updates balance", async function(){
//                     const adminInitBal = await token.balanceOf(await admin.getAddress());
//                     const user1InitBal = await token.balanceOf(await user1.getAddress());
//                     const amount = ethers.utils.parseUnits("1000", 18); // admin
        
//                     // transferFrom : admin  to user1
//                     await token.connect(admin).transferTokens(await admin.getAddress(), await user1.getAddress(), amount);
//                     //  checking new balance
//                     expect(await token.balanceOf(await admin.getAddress())).to.equal(adminInitBal - amount);
//                     expect(await token.balanceOf(await user1.getAddress())).to.equal(user1InitBal + amount);
//                   });
        
                  
//                   // not alloww transfer from and to zero address
        
//                   it("should not allow transfer from and to zero address", async function(){
//                     const amount = ethers.utils.parseUnits("1000", 18);
        
//                     // should not transfer from a 0 address to user1
//                     await expect(
//                       token.connect(admin).transferTokens(ethers.constants.AddressZero, await user1.getAddress(), amount)
//                     ).to.be.revertedWith("cannot transfer from 0 address");
        
//                     // not vice-versa
//                     await expect(
//                         token.connect(admin).transferTokens( await user1.getAddress(),ethers.constants.AddressZero, amount)
//                       ).to.be.revertedWith("cannot transfer to 0 address");
//                   });
        
//                        /// -----> CURRENT VOTES
        
//                   it("should return zero for an acc that has no checkPoint", async function(){
//                     const currVotes =  await token.getCurrentVotes(await user2.getAddress() );
//                     expect(currVotes).to.equal(0);
//                   });
        
//                   it("Should return 0 votes for an acc with no voting power", async function () {
//                       const currVotes = await token.getCurrentVotes(await user2.getAddress());
//                         expect(currVotes).to.equal(0);
//                       });
        
//                   it("should return correct prior votes", async function(){
//                         const account ="0xF9da412Cc753e3E18E6428286b5677C0E301BE3d" ;
//                         const currentBlock = await ethers.provider.getBlockNumber();
//                         const priorVotes = await token.getPriorVotes(account, currentBlock - 1);
//                         // console.log(priorVotes);
//                         expect(priorVotes).to.equal(0);
        
//                       });
        
//                         //--> transfer from
//               it("should transfer tokens using transferFrom ", async function(){
//                 const amount = ethers.utils.parseUnits("100", 18);
            
//                     //approve user1 to spend tokens on behalf of admin
//                     await token.connect(admin).approve(await user1.getAddress(), amount);
            
//                     // u1 transfer from admin to u2
//                     await token.connect(user1).transferFrom(await admin.getAddress(), await user2.getAddress(), amount);
//                     // check u2 received
//                     expect(await token.balanceOf(await user2.getAddress()) ).to.equal(amount);
//                     // checking that both u1 and admin has 0 balance
//                     expect(await token.allowance(await admin.getAddress(), await user1.getAddress())).to.equal(0);
//                   });
        
//                             // revert if transfer more tokens than allowance
//                   it("should not allow transfer if allowance is exceeded", async function () {
//                     // Decrease the allowance to a smaller value that is within the valid range
//                      allowance = ethers.utils.parseUnits("999", 18);
                
//                     // Approve user1 to spend tokens on behalf of admin with the smaller allowance
//                     await token.connect(admin).approve( user1.getAddress(), allowance);
                
//                     // Try to transfer more tokens than the allowance
//                     await expect(
//                       token.connect(user1).transferFrom( admin.getAddress(),  user2.getAddress(), allowance+1)
//                     ).to.be.revertedWith("transfer amount exceeds spender allowance");
                
//                     // Check that user2 didn't receive any tokens
//                     expect(await token.balanceOf(await user2.getAddress())).to.equal(0);
//                   }); 
        
//                      //  Transfer Tokens
//                   it("should transfer tokens and updates balance", async function(){
//                     const adminInitBal = await token.balanceOf(await admin.getAddress());
//                     const user1InitBal = await token.balanceOf(await user1.getAddress());
//                     const amount = ethers.utils.parseUnits("1000", 18); // admin
        
//                     // transferFrom : admin  to user1
//                     await token.connect(admin).transferTokens(await admin.getAddress(), await user1.getAddress(), amount);
//                     // checking new balance
//                     expect(await token.balanceOf(await admin.getAddress())).to.equal(adminInitBal - amount);
//                     expect(await token.balanceOf(await user1.getAddress())).to.equal(user1InitBal + amount);
//                   });
        
//                      // not alloww transfer from and to zero address
        
//                   it("should not allow transfer from and to zero address", async function(){
//                     const amount = ethers.utils.parseUnits("1000", 18);
        
//                     // should not transfer from a 0 address to user1
//                     await expect(
//                       token.connect(admin).transferTokens(ethers.constants.AddressZero, await user1.getAddress(), amount)
//                     ).to.be.revertedWith("cannot transfer from 0 address");
        
//                     // not vice-versa
//                     await expect(
//                         token.connect(admin).transferTokens( await user1.getAddress(),ethers.constants.AddressZero, amount)
//                       ).to.be.revertedWith("cannot transfer to 0 address");
//                   });
        
                  
//         //           /// -----> CURRENT VOTES
        
//                   it("should return zero for an acc that has no checkPoint", async function(){
//                     const currVotes =  await token.getCurrentVotes(await user2.getAddress() );
//                     expect(currVotes).to.equal(0);
//                   });
        
//                   it("Should return 0 votes for an acc with no voting power", async function () {
//                          const currVotes = await token.getCurrentVotes(await user2.getAddress());
//                          expect(currVotes).to.equal(0);
//                       });
        
//                       it("Should return the latest checkpoint's votes for an account", async function () {
//                                     const amount = ethers.utils.parseUnits("1000", 18);
                                
//                         // Transfer tokens to user1 and delegate voting power
//                            await token.connect(admin).transferTokens(await admin.getAddress(), await user1.getAddress(), amount);
//                            await token.connect(user1).delegate(await user2.getAddress());
                                
//                               // Check the current votes for user1 (latest checkpoint)
//                             const currVotes1 = await token.getCurrentVotes(await user1.getAddress());
//                             expect(currVotes1).to.equal(0);
                        
//                             const currVotes2 = await token.getCurrentVotes(await user2.getAddress());
//                             expect(currVotes2).to.equal(amount);
//                            });
        
//                              // PRIOR VOTES
        
//                   it("Should return 0 votes for an account before any checkpoints", async function () {
//                     // Get the block number
//                     const blockNumber = await ethers.provider.getBlockNumber();
                
//                     // Check the prior votes for an account before any checkpoints
//                     const priorVotes = await token.getPriorVotes(await user1.getAddress(), blockNumber - 1);
//                     expect(priorVotes).to.equal(0);
//                   });
        
//             //   it("Should return the latest checkpoint's votes for a recent block", async function () {
//             //   const amount = ethers.utils.parseUnits("1000", 18);
        
//             //   // Transfer tokens to user1 and delegate voting power
//             //   await token.connect(admin).transferTokens(await admin.getAddress(), await user1.getAddress(), amount);
//             //   await token.connect(user1).delegate(await admin.getAddress());
        
//             //   // Get the block number
//             //   const blockNumber = await ethers.provider.getBlockNumber();
        
//             //   // Check the prior votes for user1 at the current block (latest checkpoint)
//             //   const priorVotes = await token.getPriorVotes(await user1.getAddress(), blockNumber);
//             //   expect(priorVotes).to.equal(amount);
//             // });
        
//             // it("Should return the latest checkpoint's votes for a recent block", async function () {
//             //   const amount = ethers.utils.parseUnits("1000", 18);
//             //   const checkpointsData = [
//             //     { blockNumber: 1000, votes: 100 },
//             //     { blockNumber: 1500, votes: 200 },
//             //     { blockNumber: 2000, votes: 300 },
//             //   ];
        
//             //   // Transfer tokens to user1 and delegate voting power
//             //   await token.connect(admin).transferTokens(await admin.getAddress(), await user1.getAddress(), amount);
//             //   await token.connect(user1).delegate(await admin.getAddress());
//             //   const currentBlock = await ethers.provider.getBlockNumber();
//             //   const historicalBlock = currentBlock - 1; // Use a block lower than the current block
            
//             //   // Check the prior votes for user1 at the specified historical block
//             //   const priorVotes = await token.getPriorVotes(await user1.getAddress(), historicalBlock);
//             //   const priorVotess = ethers.utils.parseEther(priorVotes);
//             //   expect(priorVotess).to.equal(amount);
//             // });
         
//             it("Should create demo checkpoints with specified votes", async function () {
//               // Specify the address for which you want to create checkpoints
//               const accountToCheckpoint = user1.address;
          
//               // Specify the historical block numbers and votes
//               const checkpointsData = [
//                 { blockNumber: 1000, votes: 100 },
//                 { blockNumber: 1500, votes: 200 },
//                 { blockNumber: 2000, votes: 300 },
//               ];
          
//               for (const { blockNumber, votes } of checkpointsData) {
//                 await token.writeCheckpoint(accountToCheckpoint, blockNumber, 0, votes); // You need to provide all four arguments here
//               }
//                     // 10 blocks
//               for (let i = 0; i < 10; i++) {
//                 await ethers.provider.send("evm_mine");
//               }
          
//               // Check the prior votes for user1 at different historical blocks
//               expect(await token.getPriorVotes(accountToCheckpoint, 900)).to.equal(0);
//               expect(await token.getPriorVotes(accountToCheckpoint, 1100)).to.equal(100);
//               expect(await token.getPriorVotes(accountToCheckpoint, 1600)).to.equal(200);
//               expect(await token.getPriorVotes(accountToCheckpoint, 2100)).to.equal(300);
//             });
        
//                       /// DELEGATE
        
//                 it("should delegate voting power and  update delegaates ", async function(){
//                         const amount = ethers.utils.parseUnits("1000", 18);
//                         await token.connect(admin).transferTokens(await admin.getAddress(), await user1.getAddress(), amount);
        
//                         // Delegate voting power from user1 to admin
//                         await token.connect(user1).delegate(await user2.getAddress());
        
//                         // Check the delegate of user1
//                         const user1Delegate = await token.delegates(await user1.getAddress());
//                         expect(user1Delegate).to.equal(await user2.getAddress());
        
//                         const user1Votes = await token.getCurrentVotes(await user1.getAddress() );
//                         const user2Votes = await token.getCurrentVotes(await user2.getAddress() );
        
//                         expect(user1Votes).to.equal(0);
//                         expect(user2Votes).to.equal(amount);                  
//                 });
        
                
//              /* it("should move Delegates", async function(){
//                     const amount = ethers.utils.parseUnits("1000", 18);
//                     await token.connect(admin).transferTokens(await admin.getAddress(), await user1.getAddress(), amount);
//                         // Move delegates and update voting power
//                   console.log(await token.balanceOf(user1.getAddress() ));
//                  await token.connect(user1).moveDelegates(await user1.getAddress(), await user2.getAddress(), amount);
//                   console.log(await token.balanceOf(user1.getAddress() ));
                
//                   // Check updated voting power of admin and user2
//                         // const user1V = await token.getCurrentVotes(await user1.getAddress());
//                         // const user2V = await token.getCurrentVotes(await user2.getAddress());
//                         // expect(user1V).to.equal(0);
//                         //  expect(user2V).to.equal(1000);
//                 }) ;  
//                   */
        
//                 it("Should emit DelegateChanged event and update delegates", async function () {
//                               const amount = ethers.utils.parseUnits("1000", 18);
//                               await token.connect(admin).transferTokens(await admin.getAddress(), await user1.getAddress(), amount);
                          
//                               // Delegate voting power from user1 to user2
//                               const tx = await token.connect(user1).delegate(await user2.getAddress());
                          
//                               // Expect DelegateChanged event to be emitted
//                               await expect(tx).to.emit(token, "DelegateChanged")
//                                 .withArgs(await user1.getAddress(), ethers.constants.AddressZero, await user2.getAddress());
//                               // Checking the delegate of user1
//                               const user1Delegate = await token.delegates(await user1.getAddress());
//                               expect(user1Delegate).to.equal(await user2.getAddress());
//                             });
        
//         });
                  
//         //                  //           /// CHECKPOINT
             
//         //   /* it("Should create an intermediate checkpoint if the last checkpoint is before the current block", async function () {
//         //     const amount = ethers.utils.parseUnits("1000", 18);
            
//         //     // Transfer tokens to user1 and delegate voting power
//         //     await token.connect(admin).transferTokens(await admin.getAddress(), await user1.getAddress(), amount);
//         //     await token.connect(user1).delegate(await admin.getAddress());
        
//         //     const blockNum  = await ethers.provider.getBlockNumber();
//         //     // Move forward to a new block
//         //     await ethers.provider.send("evm_mine");
        
//         //     // Write a new checkpoint for user1 after moving to a new block
//         //     await token.connect(admin).writeCheckpoint(await user1.getAddress(), 2, amount, amount * 2);
        
//         //     // Check the new checkpoint for use
        
//         //     const user1Checkpoints = await token.checkpoints(await user1.getAddress(), 1);
//         //     expect(user1Checkpoints.fromBlock).to.equal(blockNumber + 1);
//         //     expect(user1Checkpoints.votes).to.equal(amount);
        
//         //     });  */
        