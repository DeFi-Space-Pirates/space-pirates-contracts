const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

const uri = "https://space-pirates-testnet.com/familiar/";

let accounts;
let ownerAddress;
let tokensContract;
let helperRoleContract;
let nftContract;

describe("SpacePiratesNFTContract", () => {
  before(async () => {
    const HelperRoleContract = await ethers.getContractFactory(
      "HelperRoleContract"
    );
    helperRoleContract = await HelperRoleContract.deploy();

    const TokenContract = await ethers.getContractFactory("SpacePiratesTokens");
    tokensContract = await TokenContract.deploy("");

    accounts = await ethers.getSigners();
    ownerAddress = accounts[0].getAddress();

    const NFTContract = await ethers.getContractFactory("SpacePiratesNFT");
    nftContract = await NFTContract.deploy(uri);
  });
  it("mint", async () => {
    expect(await nftContract.supply()).to.be.equal(0);
    await expect(nftContract.tokenURI(1)).to.be.revertedWith(
      "SpacePiratesNFT: URI query for nonexistent token"
    );
    await expect(nftContract.mint(ownerAddress, "Test collection", 2, false)).to
      .be.reverted;
    const mintRole = await nftContract.CAN_MINT();
    await nftContract.grantRole(mintRole, ownerAddress);

    await nftContract.mint(ownerAddress, "Test collection", 2, false);
    expect(await nftContract.supply()).to.be.equal(2);
    expect(await nftContract.tokenURI(1)).to.be.equal(uri + "1");
  });
  it("set uri", async () => {
    const newUri = "https://space-piraes-testnet.com/nft/test/";
    const uriRole = nftContract.URI_SETTER();

    await expect(nftContract.setBaseURI(newUri)).to.be.reverted;

    await nftContract.grantRole(uriRole, ownerAddress);

    await nftContract.setBaseURI(newUri);
    expect(await nftContract.tokenURI(1)).to.be.equal(newUri + "1");
  });
  it("walletOfOwner", async () => {
    await nftContract.mint(ownerAddress, "Second collection", 3, false);

    expect(await nftContract.walletOfOwner(ownerAddress)).to.be.deep.equal([
      BigNumber.from("1"),
      BigNumber.from("2"),
      BigNumber.from("3"),
      BigNumber.from("4"),
      BigNumber.from("5"),
    ]);
  });
  it("can be transferred if not locked", async () => {
    const destAddr = await accounts[1].getAddress();
    await nftContract.transferFrom(ownerAddress, destAddr, 2);
  });
  it("can not be transferred if locked", async () => {
    const destAddr = await accounts[1].getAddress();
    await nftContract.mint(ownerAddress, "Non transferable", 1, true);
    await expect(
      nftContract.transferFrom(ownerAddress, destAddr, 6)
    ).to.be.revertedWith("SpacePiratesNFT: NFT not transferable");
  });
});
