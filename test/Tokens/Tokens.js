const { expect } = require("chai");
const { ethers } = require("hardhat");

let accounts;
let ownerAddress;
let tokensContract;
let helperRoleContract;

describe("Tokens: Tokens", () => {
  before(async () => {
    const HelperRoleContract = await ethers.getContractFactory(
      "HelperRoleContract"
    );
    helperRoleContract = await HelperRoleContract.deploy();
    accounts = await ethers.getSigners();
    ownerAddress = accounts[0].getAddress();
  });
  it("Contract deploy", async () => {
    const TokenContract = await ethers.getContractFactory("Tokens");
    const tokensContract = await TokenContract.deploy();
  });
  describe("Methods:", () => {
    beforeEach(async () => {
      const TokenContract = await ethers.getContractFactory("Tokens");
      tokensContract = await TokenContract.deploy();
    });
    describe("Metadata:", () => {
      describe("uri:", () => {
        it("Should return the URI if exist", async () => {
          const id = 0;
          const URI = "ipfs://wrappedEth/";
          const role = await tokensContract.URI_SETTER_ROLE();
          await tokensContract.grantRole(role, ownerAddress);
          await tokensContract.setURI(URI, id);
          expect(await tokensContract.uri(id)).to.be.equal(URI);
        });
        it("Should revert if the URI is absent", async () => {
          const id = 5;
          await expect(tokensContract.uri(id)).to.be.revertedWith(
            "ERC1155: missing URI"
          );
        });
      });
      describe("setURI:", () => {
        it("Should set the URI", async () => {
          const id = 0;
          const URI = "ipfs://wrappedEth/";
          const role = await tokensContract.URI_SETTER_ROLE();
          await tokensContract.grantRole(role, ownerAddress);
          await tokensContract.setURI(URI, id);
          expect(await tokensContract.uri(id)).to.be.equal(URI);
        });
        it("Should revert if don't has role", async () => {
          const id = 0;
          const URI = "ipfs://wrappedEth/";
          await expect(tokensContract.setURI(URI, id)).to.be.reverted;
        });
      });
    });
    describe("Total Supply:", () => {
      describe("exist:", () => {
        it("Should return true if a token exist otherwise false", async () => {
          const id = 5;
          expect(await tokensContract.exists(id)).to.be.false;

          const role = helperRoleContract.getMintRoleBytes(id);
          await tokensContract.grantRole(role, ownerAddress);
          await tokensContract.mint(ownerAddress, 10, id);

          expect(await tokensContract.exists(id)).to.be.true;
        });
      });
      describe("totalSupply:", () => {
        it("Should return 0 if a token doesn't exist otherwise the value", async () => {
          const id = 5;
          const amount = 100;
          expect(await tokensContract.totalSupply(id)).to.be.equal(0);

          const role = helperRoleContract.getMintRoleBytes(id);
          await tokensContract.grantRole(role, ownerAddress);
          await tokensContract.mint(ownerAddress, amount, id);

          expect(await tokensContract.totalSupply(id)).to.be.equal(amount);
        });
      });
    });
    describe("Pauseable:", () => {
      describe("pause/unpause:", () => {
        it("Should pause and unpause the contract", async () => {
          expect(await tokensContract.paused()).to.be.false;
          const pauseRole = await tokensContract.CAN_PAUSE_ROLE();
          await tokensContract.grantRole(pauseRole, ownerAddress);
          await tokensContract.pause();
          expect(await tokensContract.paused()).to.be.true;
          const unpauseRole = await tokensContract.CAN_UNPAUSE_ROLE();
          await tokensContract.grantRole(unpauseRole, ownerAddress);
          await tokensContract.unpause();
          expect(await tokensContract.paused()).to.be.false;
        });
        it("Should revert transfer if paused", async () => {
          const pauseRole = await tokensContract.CAN_PAUSE_ROLE();
          await tokensContract.grantRole(pauseRole, ownerAddress);
          await tokensContract.pause();
          await expect(
            tokensContract.safeTransferFrom(
              ownerAddress,
              accounts[1].getAddress(),
              1,
              10,
              "0x00"
            )
          ).to.revertedWith("ERC1155Pausable: token transfer while paused");
        });
      });
    });
    describe("Roles:", () => {});
  });
});
