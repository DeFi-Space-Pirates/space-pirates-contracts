const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ChainId Contract", () => {
  it("Should read Chain Id from contract", async () => {
    const signer = await ethers.getSigner(0);
    const ChainId = await ethers.getContractFactory("ChainId");
    const chainId = await ChainId.deploy();

    const network = await signer.provider.getNetwork();
    expect(network.chainId).to.be.equal(await chainId.CHAIN_ID());
  });
});
