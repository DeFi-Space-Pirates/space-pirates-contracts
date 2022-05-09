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
        it("Should revert if has no role", async () => {
          await expect(tokensContract.pause()).to.be.reverted;

          const pauseRole = await tokensContract.CAN_PAUSE_ROLE();
          await tokensContract.grantRole(pauseRole, ownerAddress);
          await tokensContract.pause();

          await expect(tokensContract.unpause()).to.be.reverted;
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
    describe("Roles:", () => {
      describe("grantMultiRole:", () => {
        it("Should grant more roles at ones", async () => {
          const numberOfRole = 5;
          const roles = [];
          const addresses = [];
          for (i = 0; i < numberOfRole; i++) {
            roles[i] = helperRoleContract.getMintRoleBytes(getRandomInteger());
            addresses[i] = ownerAddress;
          }
          await tokensContract.grantMultiRole(roles, addresses);

          for (i = 0; i < numberOfRole; i++) {
            expect(await tokensContract.hasRole(roles[i], ownerAddress)).to.be
              .true;
          }
        });
        it("Should revert if array differ in length", async () => {
          const numberOfRole = 5;
          const roles = [];
          const addresses = [];
          for (i = 0; i < numberOfRole; i++) {
            roles[i] = helperRoleContract.getMintRoleBytes(getRandomInteger());
            addresses[i] = ownerAddress;
          }
          addresses[numberOfRole] = ownerAddress;
          await expect(
            tokensContract.grantMultiRole(roles, addresses)
          ).to.be.revertedWith("AccessControl: array of different length");
        });
        it("Should revert if not roles admin", async () => {
          const numberOfRole = 5;
          const roles = [];
          const addresses = [];
          for (i = 0; i < numberOfRole; i++) {
            roles[i] = helperRoleContract.getMintRoleBytes(getRandomInteger());
            addresses[i] = ownerAddress;
          }
          await expect(
            tokensContract.connect(accounts[1]).grantMultiRole(roles, addresses)
          ).to.be.reverted;
        });
      });
      describe("revokeMultiRole:", () => {
        it("Should revoke more roles at ones", async () => {
          const numberOfRole = 5;
          const roles = [];
          const addresses = [];
          for (i = 0; i < numberOfRole; i++) {
            roles[i] = helperRoleContract.getMintRoleBytes(getRandomInteger());
            addresses[i] = ownerAddress;
          }
          await tokensContract.grantMultiRole(roles, addresses);
          await tokensContract.revokeMultiRole(roles, addresses);
          for (i = 0; i < numberOfRole; i++) {
            expect(await tokensContract.hasRole(roles[i], ownerAddress)).to.be
              .false;
          }
        });
        it("Should revert if array differ in length", async () => {
          const numberOfRole = 5;
          const roles = [];
          const addresses = [];
          for (i = 0; i < numberOfRole; i++) {
            roles[i] = helperRoleContract.getMintRoleBytes(getRandomInteger());
            addresses[i] = ownerAddress;
          }
          await tokensContract.grantMultiRole(roles, addresses);
          addresses[numberOfRole] = ownerAddress;
          await expect(
            tokensContract.revokeMultiRole(roles, addresses)
          ).to.be.revertedWith("AccessControl: array of different length");
        });
        it("Should revert if not roles admin", async () => {
          const numberOfRole = 5;
          const roles = [];
          const addresses = [];
          for (i = 0; i < numberOfRole; i++) {
            roles[i] = helperRoleContract.getMintRoleBytes(getRandomInteger());
            addresses[i] = ownerAddress;
          }
          await tokensContract.grantMultiRole(roles, addresses);
          await expect(
            tokensContract
              .connect(accounts[1])
              .revokeMultiRole(roles, addresses)
          ).to.be.reverted;
        });
      });
    });
    describe("Tokens:", () => {
      describe("mint:", () => {
        it("Should mint token if has token id mint role", async () => {
          const id = getRandomInteger();
          const amount = 100;
          const initialBalance = await tokensContract.balanceOf(
            ownerAddress,
            id
          );

          const role = helperRoleContract.getMintRoleBytes(id);
          await tokensContract.grantRole(role, ownerAddress);

          await tokensContract.mint(ownerAddress, amount, id);
          expect(await tokensContract.balanceOf(ownerAddress, id)).to.be.equal(
            initialBalance + amount
          );
        });
        it("Should revert if has not token id mint role", async () => {
          const id = getRandomInteger();
          const amount = 100;

          await expect(tokensContract.mint(ownerAddress, amount, id)).to.be
            .reverted;
        });
      });
      describe("burn:", () => {
        it("Should burn token if has token id mint role and it is owner", async () => {
          const id = getRandomInteger();
          const amount = 100;

          const mintRole = helperRoleContract.getMintRoleBytes(id);
          const burnRole = helperRoleContract.getBurnRoleBytes(id);
          await tokensContract.grantRole(mintRole, ownerAddress);
          await tokensContract.grantRole(burnRole, ownerAddress);
          await tokensContract.mint(ownerAddress, amount * 10, id);

          const initialBalance = await tokensContract.balanceOf(
            ownerAddress,
            id
          );

          await tokensContract.burn(ownerAddress, amount, id);

          expect(await tokensContract.balanceOf(ownerAddress, id)).to.be.equal(
            initialBalance - amount
          );
        });
        it("Should burn token if has token id mint role and it is approved", async () => {
          const id = getRandomInteger();
          const amount = 100;

          const mintRole = helperRoleContract.getMintRoleBytes(id);
          const burnRole = helperRoleContract.getBurnRoleBytes(id);
          await tokensContract.grantRole(mintRole, ownerAddress);
          await tokensContract.grantRole(burnRole, accounts[1].getAddress());
          await tokensContract.mint(ownerAddress, amount * 10, id);

          const initialBalance = await tokensContract.balanceOf(
            ownerAddress,
            id
          );

          tokensContract.setApprovalForAll(accounts[1].getAddress(), true);
          await tokensContract
            .connect(accounts[1])
            .burn(ownerAddress, amount, id);

          expect(await tokensContract.balanceOf(ownerAddress, id)).to.be.equal(
            initialBalance - amount
          );
        });
        it("Should revert if has not token id burn role", async () => {
          const id = getRandomInteger();
          const amount = 100;

          const role = helperRoleContract.getMintRoleBytes(id);
          await tokensContract.grantRole(role, ownerAddress);
          await tokensContract.mint(ownerAddress, amount, id);

          await expect(tokensContract.burn(ownerAddress, amount, id)).to.be
            .reverted;
        });
        it("Should revert if it is not owner nor approved", async () => {
          const id = getRandomInteger();
          const amount = 100;

          const mintRole = helperRoleContract.getMintRoleBytes(id);
          const burnRole = helperRoleContract.getBurnRoleBytes(id);
          await tokensContract.grantRole(mintRole, ownerAddress);
          await tokensContract.grantRole(burnRole, accounts[1].getAddress());
          await tokensContract.mint(ownerAddress, amount * 10, id);

          await expect(
            tokensContract.connect(accounts[1]).burn(ownerAddress, amount, id)
          ).to.be.revertedWith("ERC1155: caller is not owner nor approved");
        });
      });
    });
  });
});

const getRandomInteger = () => {
  return Math.floor(Math.random() * 100000);
};
