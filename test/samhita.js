const { ethers } = require("hardhat");
const { expect, assert } = require("chai");

const ERC20abi = require("../artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json");
const ERC721abi = require("../artifacts/@openzeppelin/contracts/token/ERC721/ERC721.sol/ERC721.json");
const { providers } = require("ethers");

describe("Samhita", function () {
  let samhita,
    timelock,
    token,
    templateNFT,
    contract,
    nftcontract,
    proposer,
    voter1,
    voter2,
    voter3,
    voter4,
    voter5,
    admin;

  const ProposalState = {
    Pending: 0,
    Active: 1,
    Canceled: 2,
    Defeated: 3,
    Succeeded: 4,
    Queued: 5,
    Expired: 6,
    Executed: 7,
  };

  beforeEach(async function () {
    [admin, proposer, voter1, voter2, voter3, voter4, voter5] =
      await ethers.getSigners();
    const MIN_DELAY = 600;

    // time lock contract
    const Timelock = await ethers.getContractFactory("Timelock");
    timelock = await Timelock.connect(admin).deploy(MIN_DELAY);
    await timelock.deployed();
    // token contract
    const Token = await ethers.getContractFactory("samhitaToken");
    token = await Token.connect(admin).deploy("1000");

    // template nft contract
    const TemplateNFT = await ethers.getContractFactory("TemplateNFT");
    templateNFT = await TemplateNFT.deploy();
    await templateNFT.deployed();

    // samhita contract
    const Samhita = await ethers.getContractFactory("Samhita");
    samhita = await Samhita.connect(admin).deploy(
      timelock.address,
      token.address,
      templateNFT.address,
      "ipfs uri link"
    );

    await samhita.deployed();
    nftcontract = new ethers.Contract(
      templateNFT.address,
      ERC721abi.abi,
      admin
    );
  });

  it("should return correct quorumVotes value", async function () {
    console.log(
      "admin ETH balance: ",
      await ethers.provider.getBalance(admin.address)
    );
    console.log("first test");
    console.log("Timelock: " + timelock.address);
    console.log("samhitaToken: " + token.address);
    console.log("Samhita: " + samhita.address);
    console.log("template nft: ", templateNFT.address);
    console.log(admin.address);
    const quorum = await samhita.quorumVotes();
    expect(quorum).to.equal(40);
  });

  it("should return correct proposalMaxOperations value", async function () {
    expect(await samhita.proposalMaxOperations()).to.equal(10);
  });

  it("should return correct proposalThreshold value", async function () {
    expect(await samhita.proposalThreshold()).to.equal(10);
  });

  it("transfer samhita tokens to the contract", async function () {
    console.log("admin:", await token.balanceOf(admin.address));

    // Capture the transaction receipt by assigning the result to `tx`
    const tx = await token.connect(admin).transfer(samhita.address, "100"); // 100
    await tx.wait();

    expect(await token.balanceOf(samhita.address)).to.equal("100");
  });

  // start
  it("should add a member to the samhita DAO", async function () {
    const propB = await ethers.provider.getBalance(proposer.address);
    console.log("proposer eth balance: ", propB);
    const tokenPrice = await token.getTokenPrice();
    const initialContractBalance = await ethers.provider.getBalance(
      samhita.address
    );
    console.log("-----> initial contract balance: ", initialContractBalance);

    await expect(
      samhita.connect(proposer).addMember(2000, {
        value: ethers.utils.parseEther(String((2000 * tokenPrice) / 10 ** 18)),
      })
    ).to.be.revertedWith("Contract does not have enough samhitaTokens");

    // transfer tokens to the contract  -- 1000
    const tx = await token.connect(admin).transfer(samhita.address, "1000");
    await tx.wait();
    console.log(
      "samhita contract tokens: ",
      await token.balanceOf(samhita.address)
    );

    await expect(
      samhita.connect(proposer).addMember(6, {
        value: 6 * tokenPrice,
      })
    ).to.be.revertedWith(
      "You must purchase at least 10 tokens to become a member"
    );

    const tx_ = await samhita.connect(proposer).addMember(20, {
      value: 20 * tokenPrice,
    });
    console.log("proposer tokens: ", await token.balanceOf(proposer.address));

    await samhita.connect(voter1).addMember(10, {
      value: 10 * tokenPrice,
    });
    await samhita.connect(voter2).addMember(21, {
      value: 21 * tokenPrice,
    });
    await samhita.connect(voter3).addMember(18, {
      value: 18 * tokenPrice,
    });
    await samhita.connect(voter4).addMember(15, {
      value: 15 * tokenPrice,
    });

    expect(await token.balanceOf(proposer.address)).to.equal("20");
    expect(await token.balanceOf(voter1.address)).to.equal("10");
    expect(await token.balanceOf(voter4.address)).to.equal("15");

    await token.writeCheckpoint(voter1.address, 0, 0, 10);
    await token.writeCheckpoint(voter2.address, 0, 0, 21);
    await token.writeCheckpoint(voter3.address, 0, 0, 18);
    await token.writeCheckpoint(voter4.address, 0, 0, 15);

    expect(await samhita.isMemberAdded(proposer.address)).to.equal(true);
    expect(await samhita.isMemberAdded(voter1.address)).to.equal(true);
    expect(await samhita.isMemberAdded(voter2.address)).to.equal(true);
    expect(await samhita.isMemberAdded(voter3.address)).to.equal(true);
    expect(await samhita.isMemberAdded(voter4.address)).to.equal(true);
    expect(await samhita.isMemberAdded(voter5.address)).to.equal(false);

    //------------------ create a proposal---------------------------------
    const stakeAmount = await samhita.proposalStake();
    // approve tokens
    await token.connect(proposer).approve(samhita.address, stakeAmount);
    // const title = "My Proposal Title";

    await expect(
      samhita
        .connect(proposer)
        .propose(
          [token.address],
          [0],
          ["execute(uint)"],
          [ethers.utils.defaultAbiCoder.encode(["uint256"], [42])],
          "My Proposal Title",
          "Proposal of samhita DAO",
          "bafybeifrwhe5h22blc33rgvcktxe3wedjq467caia23ce7toal4tym2doy",
          "template",
         
          { value: stakeAmount }
        )
    ).to.be.revertedWith("proposer votes below proposal threshold");

    // delegate votes
    await token.delegate(proposer.address);

    console.log(
      "Samhita contract balance after propose:",
      await ethers.provider.getBalance(samhita.address)
    );
    const propBalance = await ethers.provider.getBalance(proposer.address);
    console.log("proposer eth balance: ", propBalance);
    const transx = await samhita
      .connect(proposer)
      .propose(
        [token.address],
        [0],
        ["execute(uint)"],
        [ethers.utils.defaultAbiCoder.encode(["uint256"], [42])],
        "My Proposal Title",
        "Proposal of samhita DAO",
        "bafybeifrwhe5h22blc33rgvcktxe3wedjq467caia23ce7toal4tym2doy",
        "template",
      
        { value: stakeAmount }
      );

    await transx.wait();
    // console.log("3456: ",proposalId);
    console.log("proposal created...!");
    const propBalanceAfter = await ethers.provider.getBalance(proposer.address);
    console.log(
      "proposer eth balance after (stake deducted): ",
      propBalanceAfter
    );

    // Creator NFT
    const creatorNfts = await templateNFT.getCreatorNFTs(admin.address);
    console.log(await templateNFT.creatorIdTocreatorData(creatorNfts[0]));

    // create proposal with incorrect stake amount
    await expect(
      samhita
        .connect(proposer)
        .propose(
          [token.address],
          [0],
          ["execute(uint)"],
          [ethers.utils.defaultAbiCoder.encode(["uint256"], [42])],
          "My Proposal Title",
          "Proposal of samhita DAO",
          "bafybeifrwhe5h22blc33rgvcktxe3wedjq467caia23ce7toal4tym2doy",
          "template",
     
          { value: 0 }
        )
    ).to.be.revertedWith(
      "You must have valid stake amount to create a proposal"
    );

    // not a member of samhita DAO
    await expect(
      samhita
        .connect(voter5)
        .propose(
          [token.address],
          [0],
          ["execute(uint)"],
          [ethers.utils.defaultAbiCoder.encode(["uint256"], [42])],
          "My Proposal Title",
          "Proposal of samhita DAO",
          "bafybeifrwhe5h22blc33rgvcktxe3wedjq467caia23ce7toal4tym2doy",
          "template",
     
          { value: stakeAmount }
        )
    ).to.be.revertedWith("You are not the member of ths Samhita DAO");

    // arity mismatch
    await expect(
      samhita
        .connect(proposer)
        .propose(
          [token.address],
          [],
          ["execute(uint)"],
          [ethers.utils.defaultAbiCoder.encode(["uint256"], [42])],
          "My Proposal Title",
          "Proposal of samhita DAO",
          "bafybeifrwhe5h22blc33rgvcktxe3wedjq467caia23ce7toal4tym2doy",
          "template",
          { value: stakeAmount }
        )
    ).to.be.revertedWith("proposal function information arity mismatch");

    //some action must be there
    await expect(
      samhita
        .connect(proposer)
        .propose(
          [],
          [],
          [],
          [],
          "My Proposal Title",
          "Proposal of samhita DAO",
          "bafybeifrwhe5h22blc33rgvcktxe3wedjq467caia23ce7toal4tym2doy",
          "template",
        
          { value: stakeAmount }
        )
    ).to.be.revertedWith("some action must be there");

    // too many actions
    await expect(
      samhita.connect(proposer).propose(
        Array.from({ length: 11 }, (_, i) => token.address), // Array of addresses
        Array(11).fill(0), // Array of values
        Array.from({ length: 11 }, (_, i) => `execute(uint)`), // Array of signatures
        Array(11).fill(
          ethers.utils.defaultAbiCoder.encode(
            ["string"],
            ["Proposal to transfer tokens to an address"]
          )
        ),
        "My Proposal Title",
        "Proposal of samhita DAO",
        "bafybeifrwhe5h22blc33rgvcktxe3wedjq467caia23ce7toal4tym2doy",
        "template",
      
        { value: stakeAmount }
      )
    ).to.be.revertedWith("too many actions");

      // queue a proposal ------------------------------------------------------------------------------------
   
      const proposal = await samhita.proposals(1);
    const proposalId =  (await samhita.proposals(1)).id.toNumber() ;
    console.log("proposal ID: ", proposalId);
    console.log("state after creating prop- Active: ", await samhita.state(proposal.id));


      ///---------------queue------------------------------------------------
    // waiting for 1 block to pass before voting 
    await ethers.provider.send("evm_mine");

    //-------------------  voting start
    const currentTime = (await ethers.provider.getBlock("latest")).timestamp;
    const futureTime = currentTime + 600;
    await ethers.provider.send("evm_setNextBlockTimestamp", [futureTime]);
    await ethers.provider.send("evm_mine");

    try {    
          await samhita.connect(voter1).castVote(proposalId, true);
          await samhita.connect(voter2).castVote(proposalId, true);
          await samhita.connect(voter3).castVote(proposalId, true);
          await samhita.connect(voter4).castVote(proposalId, false);
          const forVotes_ = (await samhita.proposals(proposalId)).forVotes.toNumber();
          console.log(forVotes_);


    }

    catch(error) {
                console.error("An error occurred during voting:", error);
              }  


  });

});
  