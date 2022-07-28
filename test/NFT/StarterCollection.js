const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

const uri = "https://space-pirates-testnet.com/familiar/";

let accounts;
let ownerAddress;
let tokensContract;
let nftContract;
let helperRoleContract;
let nftStarterBanner;
let uintMax112;

describe("NFTStarterBannerContract", () => {
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

    const NFTStarterBanner = await ethers.getContractFactory(
      "NFTStarterBanner"
    );
    nftStarterBanner = await NFTStarterBanner.deploy(
      tokensContract.address,
      nftContract.address
    );
    let role = helperRoleContract.getBurnRoleBytes(1000);
    tokensContract.grantRole(role, nftStarterBanner.address);

    role = await nftContract.CAN_MINT();
    nftContract.grantRole(role, nftStarterBanner.address);

    tokensContract.setApprovalForAll(nftStarterBanner.address, true);
  });
  it("mint NFT", async () => {
    const balance = await tokensContract.balanceOf(ownerAddress, 1000);
    const dest = await accounts[1].getAddress();

    const role = await helperRoleContract.getMintRoleBytes(1000);
    await tokensContract.grantRole(role, ownerAddress);
    await tokensContract.mint(ownerAddress, 1000, 2);

    await nftStarterBanner.mintCollectionItem(2);

    expect(await nftContract.walletOfOwner(ownerAddress)).to.be.deep.equal([
      BigNumber.from("1"),
      BigNumber.from("2"),
    ]);
    expect(await tokensContract.balanceOf(ownerAddress, 1000)).to.be.equal(
      balance
    );

    await expect(
      nftContract.transferFrom(ownerAddress, dest, 1)
    ).to.be.revertedWith("SpacePiratesNFT: NFT not transferable");
  });
});
