const { expect } = require("chai");
const { ethers } = require("hardhat");
const BigNumber = require("bignumber.js");

describe("ERC2981", async () => {
  let erc2981;
  let deployer;
  let royaltyReceiver;
  const testPrice = 100; // in wei
  const royaltyBasisPoints = 500; // 5 %
  const baseURI = "ipfs://QmTSbgfx6YTFZ4HXrKCwCRGqEJrRbGrP6eZhb3TNfjU11U/";
  beforeEach(async () => {
    [deployer, royaltyReceiver, newRoyaltyReceiver] = await hre.ethers.getSigners();
    const ERC2981 = await ethers.getContractFactory("ERC2981");

    erc2981 = await ERC2981.deploy(
      "RoyaltyToken", // Token name
      "ROYAL", // Token symbol
      baseURI, // Token baseURI
      royaltyReceiver.address, // Royalty receiver
      royaltyBasisPoints // Royalty basis points (1% = 100)
    );

    await erc2981.deployed();
  })
  context("royaltyInfo()", async () => {
    it("Should return the royalty receiver and royalty amount for a provided price", async function () {

      const result = await erc2981.royaltyInfo(1, testPrice);

      expect(result[0]).to.equal(royaltyReceiver.address);
      expect(result[1]).to.equal(new BigNumber(testPrice).multipliedBy(royaltyBasisPoints).dividedBy(10000).toNumber());
    });
  })
  context("supportsInterface()", async () => {
    it("Should signal support for the ERC2981 Interface", async function () {
    
      const result = await erc2981.supportsInterface("0x2a55205a");
      expect(result).to.equal(true);

    })

  })
  context("updateRoyaltyInfo()", async () => {
    it("Should allow the owner of the contract to update royalty info", async function () {

      let newBasisPoints = 1000; // 10 %
    
      await erc2981.updateRoyaltyInfo(newRoyaltyReceiver.address, newBasisPoints);
      
      const result = await erc2981.royaltyInfo(1, testPrice);

      expect(result[0]).to.equal(newRoyaltyReceiver.address);
      expect(result[1]).to.equal(new BigNumber(testPrice).multipliedBy(newBasisPoints).dividedBy(10000).toNumber());

    })
    it("Should *not* a non-owner of the contract to update royalty info", async function () {

      let newBasisPoints = 1000; // 10 %
    
      await expect(erc2981.connect(royaltyReceiver).updateRoyaltyInfo(newRoyaltyReceiver.address, newBasisPoints)).to.be.revertedWith("Ownable: caller is not the owner");

    })
  })
  context("tokenURI()", async () => {
    it("Should return the tokenURI for a provided tokenId", async function () {
    
      let tokenId = 1;

      const result = await erc2981.tokenURI(tokenId);
      expect(result).to.equal(`${baseURI}${tokenId}.json`);

    })
    it("Should revert if a non-existent tokenId is provided", async function () {
    
      await expect(erc2981.tokenURI(2)).to.be.revertedWith("ERC721Metadata: URI query for nonexistent token");

    })
  })
});
