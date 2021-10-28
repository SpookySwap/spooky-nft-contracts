import { ethers, run } from "hardhat"

async function main() {
    const uri = 'ipfs://Qmch1E575xvg3HgZQ6vuAxhyvAi7pLpCw4cufmA6W6fGjF/'
    const Magicats = await ethers.getContractFactory("Magicats");
    const magicats = await Magicats.deploy(uri);
    await magicats.deployed();
  
    console.log("Magicats deployed to:", magicats.address);

    await run("verify:verify", {
        address: magicats.address,
        constructorArguments: [uri],
    })
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });