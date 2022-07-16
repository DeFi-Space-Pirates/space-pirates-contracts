const { expect } = require("chai");
const { ethers } = require("hardhat");

let accounts;
let ownerAddress;
let tokensContract;
let helperRoleContract;

describe("SpacePiratesTokens: Tokens", () => {
  before(async () => {
    const HelperRoleContract = await ethers.getContractFactory(
      "HelperRoleContract"
    );
    helperRoleContract = await HelperRoleContract.deploy();
    accounts = await ethers.getSigners();
    ownerAddress = accounts[0].getAddress();
  });
  it("Contract deploy", async () => {
    const TokenContract = await ethers.getContractFactory("SpacePiratesTokens");
    const tokensContract = await TokenContract.deploy("testuri.com/token/");
  });
  describe("Methods:", () => {
    beforeEach(async () => {
      const TokenContract = await ethers.getContractFactory(
        "SpacePiratesTokens"
      );
      tokensContract = await TokenContract.deploy("testuri.com/token/");
    });
    describe("Metadata:", () => {
      describe("uri:", () => {
        it("Should return the URI if exist", async () => {
          const id = 1;
          const URI = "ipfs://wrappedEth/";
          const role = await tokensContract.URI_SETTER_ROLE();

          await tokensContract.grantRole(role, ownerAddress);
          await tokensContract.setURI(URI);

          expect(await tokensContract.uri(id)).to.be.equal(URI + id);
        });
        it("Should revert if the URI is absent", async () => {
          const id = 5;

          await expect(tokensContract.uri(id)).to.be.revertedWith(
            "ERC1155: URI query for nonexistent token"
          );
        });
      });
      describe("setURI:", () => {
        it("Should set the URI", async () => {
          const id = 1;
          const URI = "ipfs://wrappedEth/";
          const role = await tokensContract.URI_SETTER_ROLE();
          await tokensContract.grantRole(role, ownerAddress);
          await tokensContract.setURI(URI);
          expect(await tokensContract.uri(id)).to.be.equal(URI + id);
        });
        it("Should revert if don't has role", async () => {
          const id = 1;
          const URI = "ipfs://wrappedEth/";
          await expect(tokensContract.setURI(URI)).to.be.reverted;
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
          await tokensContract.mint(ownerAddress, id, 10);

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
          await tokensContract.mint(ownerAddress, id, amount);

          expect(await tokensContract.totalSupply(id)).to.be.equal(amount);
        });
      });
    });
    describe("Pausable:", () => {
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

          await tokensContract.mint(ownerAddress, id, amount);
          expect(await tokensContract.balanceOf(ownerAddress, id)).to.be.equal(
            initialBalance + amount
          );
        });
        it("Should revert if has not token id mint role", async () => {
          const id = getRandomInteger();
          const amount = 100;

          await expect(tokensContract.mint(ownerAddress, id, amount)).to.be
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
          await tokensContract.mint(ownerAddress, id, amount * 10);

          const initialBalance = await tokensContract.balanceOf(
            ownerAddress,
            id
          );

          await tokensContract.burn(ownerAddress, id, amount);

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
          await tokensContract.mint(ownerAddress, id, amount * 10);

          const initialBalance = await tokensContract.balanceOf(
            ownerAddress,
            id
          );

          tokensContract.setApprovalForAll(accounts[1].getAddress(), true);
          await tokensContract
            .connect(accounts[1])
            .burn(ownerAddress, id, amount);

          expect(await tokensContract.balanceOf(ownerAddress, id)).to.be.equal(
            initialBalance - amount
          );
        });
        it("Should revert if has not token id burn role", async () => {
          const id = getRandomInteger();
          const amount = 100;

          const role = helperRoleContract.getMintRoleBytes(id);
          await tokensContract.grantRole(role, ownerAddress);
          await tokensContract.mint(ownerAddress, id, amount * 10);

          await expect(tokensContract.burn(ownerAddress, id, amount * 10)).to.be
            .reverted;
        });
        it("Should revert if it is not owner nor approved", async () => {
          const id = getRandomInteger();
          const amount = 100;

          const mintRole = helperRoleContract.getMintRoleBytes(id);
          const burnRole = helperRoleContract.getBurnRoleBytes(id);
          await tokensContract.grantRole(mintRole, ownerAddress);
          await tokensContract.grantRole(burnRole, accounts[1].getAddress());
          await tokensContract.mint(ownerAddress, id, amount * 10);

          await expect(
            tokensContract.connect(accounts[1]).burn(ownerAddress, id, amount)
          ).to.be.revertedWith("ERC1155: caller is not owner nor approved");
        });
      });
      describe("mintBatch:", async () => {
        it("Should mint batch of tokens if has token ids mint roles", async () => {
          const ids = [
            getRandomInteger(),
            getRandomInteger(),
            getRandomInteger(),
          ];
          const addresses = [ownerAddress, ownerAddress, ownerAddress];
          const amounts = [100, 101, 102];

          const initialBalances = await tokensContract.balanceOfBatch(
            addresses,
            ids
          );

          const roles = await helperRoleContract.getMultiMintRoleBytes(ids);

          await tokensContract.grantMultiRole(roles, addresses);

          await tokensContract.mintBatch(ownerAddress, ids, amounts);

          const updatedBalances = initialBalances.map((initialBalance, index) =>
            initialBalance.add(amounts[index])
          );

          expect(
            await tokensContract.balanceOfBatch(addresses, ids)
          ).to.deep.have.same.members(updatedBalances);
        });
        it("Should revert if has not token ids mint roles", async () => {
          const ids = [
            getRandomInteger(),
            getRandomInteger(),
            getRandomInteger(),
          ];
          const addresses = [ownerAddress, ownerAddress, ownerAddress];
          const amounts = [100, 101, 102];

          await expect(tokensContract.mintBatch(ownerAddress, ids, amounts)).to
            .be.reverted;
        });
        it("Should revert if ids and amounts arrays length are not equal", async () => {
          const ids = [
            getRandomInteger(),
            getRandomInteger(),
            getRandomInteger(),
          ];
          const addresses = [ownerAddress, ownerAddress, ownerAddress];
          const amounts = [100, 101, 102];

          const roles = await helperRoleContract.getMultiMintRoleBytes(ids);

          await tokensContract.grantMultiRole(roles, addresses);

          await expect(
            tokensContract.mintBatch(ownerAddress, [ids[0]], amounts)
          ).to.be.revertedWith("ERC1155: ids and amounts length mismatch");
        });
      });
      describe("burnBatch:", async () => {
        it("Should burn batch of tokens if has token ids mint roles and it is owner", async () => {
          const ids = [
            getRandomInteger(),
            getRandomInteger(),
            getRandomInteger(),
          ];
          const addresses = [ownerAddress, ownerAddress, ownerAddress];
          const amounts = [100, 101, 102];

          const mintRoles = await helperRoleContract.getMultiMintRoleBytes(ids);
          const burnRoles = await helperRoleContract.getMultiBurnRoleBytes(ids);

          await tokensContract.grantMultiRole(mintRoles, addresses);
          await tokensContract.grantMultiRole(burnRoles, addresses);

          await tokensContract.mintBatch(ownerAddress, ids, amounts);

          const initialBalances = await tokensContract.balanceOfBatch(
            addresses,
            ids
          );

          await tokensContract.burnBatch(ownerAddress, ids, amounts);

          const updatedBalances = initialBalances.map((initialBalance, index) =>
            initialBalance.sub(amounts[index])
          );

          expect(
            await tokensContract.balanceOfBatch(addresses, ids)
          ).to.deep.have.same.members(updatedBalances);
        });
        it("Should burn batch of tokens if has token ids mint roles and it is approved", async () => {
          const ids = [
            getRandomInteger(),
            getRandomInteger(),
            getRandomInteger(),
          ];
          const addresses = [
            accounts[1].getAddress(),
            accounts[1].getAddress(),
            accounts[1].getAddress(),
          ];
          const ownerAddresses = [ownerAddress, ownerAddress, ownerAddress];
          const amounts = [100, 101, 102];

          const mintRoles = await helperRoleContract.getMultiMintRoleBytes(ids);
          const burnRoles = await helperRoleContract.getMultiBurnRoleBytes(ids);

          await tokensContract.grantMultiRole(mintRoles, ownerAddresses);
          await tokensContract.grantMultiRole(burnRoles, addresses);

          await tokensContract.mintBatch(ownerAddress, ids, amounts);

          const initialBalances = await tokensContract.balanceOfBatch(
            ownerAddresses,
            ids
          );

          await tokensContract.setApprovalForAll(
            accounts[1].getAddress(),
            true
          );

          await tokensContract
            .connect(accounts[1])
            .burnBatch(ownerAddress, ids, amounts);

          const updatedBalances = initialBalances.map((initialBalance, index) =>
            initialBalance.sub(amounts[index])
          );

          expect(
            await tokensContract.balanceOfBatch(ownerAddresses, ids)
          ).to.deep.have.same.members(updatedBalances);
        });
        it("Should revert if has not token ids burn roles", async () => {
          const ids = [
            getRandomInteger(),
            getRandomInteger(),
            getRandomInteger(),
          ];
          const addresses = [ownerAddress, ownerAddress, ownerAddress];
          const amounts = [100, 101, 102];

          const mintRoles = await helperRoleContract.getMultiMintRoleBytes(ids);
          await tokensContract.grantMultiRole(mintRoles, addresses);

          await tokensContract.mintBatch(ownerAddress, ids, amounts);

          await expect(tokensContract.burnBatch(ownerAddress, ids, amounts)).to
            .be.reverted;
        });
        it("Should revert if it is not owner nor approved", async () => {
          const ids = [
            getRandomInteger(),
            getRandomInteger(),
            getRandomInteger(),
          ];
          const addresses = [
            accounts[1].getAddress(),
            accounts[1].getAddress(),
            accounts[1].getAddress(),
          ];
          const ownerAddresses = [ownerAddress, ownerAddress, ownerAddress];
          const amounts = [100, 101, 102];

          const mintRoles = await helperRoleContract.getMultiMintRoleBytes(ids);
          const burnRoles = await helperRoleContract.getMultiBurnRoleBytes(ids);

          await tokensContract.grantMultiRole(mintRoles, ownerAddresses);
          await tokensContract.grantMultiRole(burnRoles, addresses);

          await tokensContract.mintBatch(ownerAddress, ids, amounts);

          await expect(
            tokensContract
              .connect(accounts[1])
              .burnBatch(ownerAddress, ids, amounts)
          ).to.be.reverted;
        });
        it("Should revert if ids and amounts arrays length are not equal", async () => {
          const ids = [
            getRandomInteger(),
            getRandomInteger(),
            getRandomInteger(),
          ];
          const addresses = [ownerAddress, ownerAddress, ownerAddress];
          const amounts = [100, 101, 102];

          const roles = await helperRoleContract.getMultiBurnRoleBytes(ids);

          await tokensContract.grantMultiRole(roles, addresses);

          await expect(
            tokensContract.burnBatch(ownerAddress, [ids[0]], amounts)
          ).to.be.revertedWith("ERC1155: ids and amounts length mismatch");
        });
      });
      describe("TransferBlock:", async () => {
        it("Should block the token transfer", async () => {
          const id = getRandomInteger();
          const amount = 100;
          const mintRole = helperRoleContract.getMintRoleBytes(id);
          await tokensContract.grantRole(mintRole, ownerAddress);

          await tokensContract.mint(ownerAddress, id, amount * 10);

          expect(await tokensContract.canBeTransferred(id)).to.be.true;
          await expect(tokensContract.lockTokenTransfer(id)).to.be.reverted;

          const role = tokensContract.TRANSFERABLE_SETTER_ROLE();
          await tokensContract.grantRole(role, ownerAddress);

          await tokensContract.lockTokenTransfer(id);
          expect(await tokensContract.canBeTransferred(id)).to.be.false;

          await tokensContract.unLockTokenTransfer(id);
          expect(await tokensContract.canBeTransferred(id)).to.be.true;
        });
        it("Should transfer the token if not blocked", async () => {
          const id = getRandomInteger();
          const amount = 100;

          const role = helperRoleContract.getMintRoleBytes(id);
          await tokensContract.grantRole(role, ownerAddress);

          await tokensContract.mint(ownerAddress, id, amount * 10);
          await tokensContract.safeTransferFrom(
            ownerAddress,
            accounts[1].getAddress(),
            id,
            amount,
            "0x00"
          );
        });
        it("Should revert on transfer if the token is blocked", async () => {
          const id = getRandomInteger();
          const amount = 100;

          const mintRole = helperRoleContract.getMintRoleBytes(id);
          await tokensContract.grantRole(mintRole, ownerAddress);

          const role = tokensContract.TRANSFERABLE_SETTER_ROLE();
          await tokensContract.grantRole(role, ownerAddress);
          await tokensContract.lockTokenTransfer(id);

          await tokensContract.mint(ownerAddress, id, amount * 10);
          await expect(
            tokensContract.safeTransferFrom(
              ownerAddress,
              accounts[1].getAddress(),
              id,
              amount,
              "0x00"
            )
          ).to.be.revertedWith("ERC1155: token not transferable");
        });
      });
    });
  });
});

const getRandomInteger = () => {
  return Math.floor(Math.random() * 100000);
};
