const { expect } = require("chai");
const { ethers } = require("hardhat");

/*
  https://etherscan.io/address/0xbd3531da5cf5857e7cfaa92426877b022e612cf8#code
*/
describe("PudgyPenguins fork contract", function() {
  describe("mint", function() {
    it("Should not allow minting when the contract is paused", async function() {
      const [owner] = await ethers.getSigners();
      const PudgyPenguins = await ethers.getContractFactory("PudgyPenguins");

      const baseURI = "https://google.com/";
      const pudgyPenguins = await PudgyPenguins.deploy(baseURI);
      await pudgyPenguins.deployed();

      try {
        const mintTx = await pudgyPenguins.mint(owner.address, 1, {
          value: (150 * 10 ** 18).toString(),
        });

        await mintTx.wait();
      } catch (err) {
        expect(err.message).to.equal(
          `Error: VM Exception while processing transaction: reverted with reason string 'ERC721Pausable: token transfer while paused'`
        );
      }
    });

    it("Should not allow minting when the value is lower than price", async function() {
      const [owner] = await ethers.getSigners();
      const PudgyPenguins = await ethers.getContractFactory("PudgyPenguins");

      const baseURI = "https://google.com/";
      const pudgyPenguins = await PudgyPenguins.deploy(baseURI);
      await pudgyPenguins.deployed();

      try {
        const mintTx = await pudgyPenguins.mint(owner.address, 1, {
          value: (140 * 10 ** 18).toString(),
        });

        await mintTx.wait();
      } catch (err) {
        expect(err.message).to.equal(
          `Error: VM Exception while processing transaction: reverted with reason string 'Value below price'`
        );
      }
    });

    it("Should allow minting when the contract is unpaused", async function() {
      const [owner] = await ethers.getSigners();
      const PudgyPenguins = await ethers.getContractFactory("PudgyPenguins");

      const baseURI = "https://google.com/";
      const pudgyPenguins = await PudgyPenguins.deploy(baseURI);
      await pudgyPenguins.deployed();

      const pauseTx = await pudgyPenguins.pause(false);
      await pauseTx.wait();

      const mintTx = await pudgyPenguins.mint(owner.address, 1, {
        value: (150 * 10 ** 18).toString(),
      });
      await mintTx.wait();
    });
  });

  describe("walletOfOwner", function() {
    it("walletOfOwner: Should return all tokens owned by address", async function() {
      const [owner] = await ethers.getSigners();
      const PudgyPenguins = await ethers.getContractFactory("PudgyPenguins");

      const baseURI = "https://google.com/";
      const pudgyPenguins = await PudgyPenguins.deploy(baseURI);
      await pudgyPenguins.deployed();

      const pauseTx = await pudgyPenguins.pause(false);
      await pauseTx.wait();

      const mintTx = await pudgyPenguins.mint(owner.address, 1, {
        value: (150 * 10 ** 18).toString(),
      });
      await mintTx.wait();

      const mintTx2 = await pudgyPenguins.mint(owner.address, 1, {
        value: (150 * 10 ** 18).toString(),
      });
      await mintTx2.wait();

      const walletOfOwnerTx = await pudgyPenguins.walletOfOwner(owner.address);
      const tokenIds = walletOfOwnerTx.map((bn) => bn.toNumber());
      expect(tokenIds[0]).to.equal(0);
      expect(tokenIds[1]).to.equal(1);
    });
  });

  describe("tokenURI", function() {
    it("tokenURI: Should return a token's id with baseURI", async function() {
      const [owner] = await ethers.getSigners();
      const PudgyPenguins = await ethers.getContractFactory("PudgyPenguins");

      const baseURI = "https://google.com/";
      const pudgyPenguins = await PudgyPenguins.deploy(baseURI);
      await pudgyPenguins.deployed();

      const pauseTx = await pudgyPenguins.pause(false);
      await pauseTx.wait();

      const mintTx = await pudgyPenguins.mint(owner.address, 1, {
        value: (150 * 10 ** 18).toString(),
      });
      await mintTx.wait();

      const tokenURI = await pudgyPenguins.tokenURI(0);
      expect(tokenURI).to.equal(`${baseURI}0`);
    });
  });
});
