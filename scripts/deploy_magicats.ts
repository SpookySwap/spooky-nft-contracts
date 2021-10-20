import { ethers, run } from "hardhat"

async function main() {
    const uri = ''
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