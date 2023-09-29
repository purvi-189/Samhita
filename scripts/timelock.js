const ethers = require('ethers');
require('dotenv').config();

async function main() {
  const url = process.env.MUMBAI_URL;
    console.log(url);
  let artifacts = await hre.artifacts.readArtifact("Timelock");

  const provider = new ethers.providers.JsonRpcProvider("https://polygon-mumbai.g.alchemy.com/v2/5wFAZT05FkKJbuRGUsiKtqnCZwVmorTQ");
    // console.log(provider);
  let privateKey = process.env.MUMBAI_PRIVATE_KEY;

  let wallet = new ethers.Wallet(privateKey, provider);

  // Create an instance of a Faucet Factory
  let factory = new ethers.ContractFactory(artifacts.abi, artifacts.bytecode, wallet);
    const delayInSec = 600;
  let timelock = await factory.deploy( delayInSec );
  console.log("Timelock address: ", timelock.address);
  await timelock.deployed();
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});

