const ethers = require('ethers');
require('dotenv').config();

async function main() {

  const url = process.env.MUMBAI_URL;

  let artifacts = await hre.artifacts.readArtifact("Samhita");

  const provider = new ethers.providers.JsonRpcProvider(url);

  let privateKey = process.env.MUMBAI_PRIVATE_KEY;

  let wallet = new ethers.Wallet(privateKey, provider);

  // Create an instance of a Faucet Factory
  let factory = new ethers.ContractFactory(artifacts.abi, artifacts.bytecode, wallet);
  
  const timelock = "";
  const token = "";

  let samhita = await factory.deploy(timelock, token);

  console.log("Samhita address: ", samhita.address);
  await samhita.deployed(); 
}
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});

