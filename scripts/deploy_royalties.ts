import { ethers, run } from "hardhat"

async function main() {
    const devCut = '5000'
    const Royalty = await ethers.getContractFactory("MagicatRoyalties");
    const royalty = await Royalty.deploy(devCut);
    await royalty.deployed();
  
    console.log("Magicats deployed to:", royalty.address);

    await run("verify:verify", {
        address: royalty.address,
        constructorArguments: [devCut],
    })
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });