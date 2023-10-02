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

    // token contract
    const Token = await ethers.getContractFactory("samhitaToken");
    token = await Token.connect(admin).deploy("1000");

    // template nft contract
    const TemplateNFT = await ethers.getContractFactory("TemplateNFT");
    templateNFT = await TemplateNFT.deploy();
    templateNFT = await templateNFT.deployed();

    // samhita contract
    const Samhita = await ethers.getContractFactory("Samhita");
    samhita = await Samhita.connect(admin).deploy(
      timelock.address,
      token.address,
      templateNFT.address
    );

    await samhita.deployed();
    nftcontract = new ethers.Contract(
      templateNFT.address,
      ERC721abi.abi,
      admin
    );

    // tokenPrice = ethers.utils.parseUnits("0.001", 18); // Assuming tokenPrice is 0.001 ETH

  });

  it("should return correct quorumVotes value", async function () {
    console.log("admin ETH balance: ",await ethers.provider.getBalance(admin.address) );

    // console.log("Timelock: " + timelock.address);
    // console.log("samhitaToken: " + token.address);
    // console.log("Samhita: " + samhita.address);
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

    it("should add a member to the samhita DAO", async function () {
    const finalO = await ethers.provider.getBalance(proposer.address);
    console.log("ORIGINAL: ",finalO);
    const tokenPrice = await token.getTokenPrice();
    const initialContractBalance = await ethers.provider.getBalance(samhita.address);
    console.log("----- init contract balance: ",initialContractBalance);
    await token.connect(admin).approve(proposer.address, "100000000000000000000"); // 100 eth

    await expect(
      samhita.connect(proposer).addMember(10, {
        value: ethers.utils.parseEther(String((10 * tokenPrice) / 10 ** 18)),
      })
    ).to.be.revertedWith("Contract does not have enough samhitaTokens");

    // // transfer tokens to the contract  -- 100 
    const tx = await token
      .connect(admin)
      .transfer(samhita.address, "100");
    await tx.wait();
    console.log("contract tokens: ", await token.balanceOf(samhita.address));


    await expect(
        samhita.connect(proposer).addMember(6, {
          value: 6 * (tokenPrice),
        })
      ).to.be.revertedWith(
        "You must purchase at least 10 tokens to become a member" );

       const tx_ = await samhita.connect(proposer).addMember(20, {
            value: 20 * (tokenPrice),
          });
    console.log("proposer tokens: ", await token.balanceOf(proposer.address));

    
        // await samhita.connect(voter1).addMember(15, {
        //   value: ethers.utils.parseEther(String((15 * tokenPrice) / 10 ** 18)),
        // });
    
      // expect(await samhita.connect(proposer).addMember(22, {value: 22 * (tokenPrice), }) );
      
    // await expect(samhita.connect(voter1).addMember(15, {value: 15 * (tokenPrice), }) );
    // await token.writeCheckpoint(voter1.address, 0, 0, 15 ) ;

    // await expect(samhita.connect(voter2).addMember(20, {value: 20 * (tokenPrice), }) );
    // await token.writeCheckpoint(voter2.address, 0, 0, 20 ) ;

    // await expect(samhita.connect(voter3).addMember(18, {value: 18 * (tokenPrice), }) );
    // await token.writeCheckpoint(voter3.address, 0, 0, 18 ) ;

    // await expect(samhita.connect(voter4).addMember(22, {value: 22 * (tokenPrice), }) );
    // await token.writeCheckpoint(voter4.address, 0, 0, 22 ) ;


    //  expect( await token.balanceOf(voter1.address)).to.equal(
    //   "15000000000000000000" );

      // expect(await samhita.isMemberAdded(voter1.address)).to.equal(true);

   
    // expect(await token.balanceOf(voter2.address)).to.equal(
    //   "20000000000000000000"
    // );
    // expect(await token.balanceOf(voter3.address)).to.equal(
    //   "17000000000000000000"
    // );
    // expect(await token.balanceOf(voter4.address)).to.equal(
    //   "22000000000000000000"
    // );
 
    // expect(await samhita.isMemberAdded(proposer.address)).to.equal(true);
    // expect(await samhita.isMemberAdded(voter1.address)).to.equal(true);
    // expect(await samhita.isMemberAdded(voter2.address)).to.equal(true);
    // expect(await samhita.isMemberAdded(voter3.address)).to.equal(true);
    // expect(await samhita.isMemberAdded(voter4.address)).to.equal(true);
    // expect(await samhita.isMemberAdded(voter5.address)).to.equal(false);

    // await expect(samhita.addMember(20)).to.be.revertedWith("Not enough value");

    // const final = await ethers.provider.getBalance(samhita.address);
    // console.log("----- final c b: ",final);

    });

});
