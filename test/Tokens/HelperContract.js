const { expect } = require("chai");
const { ethers } = require("hardhat");

const testCases = 10;
const mintString = "MINT_ROLE_FOR_ID";
const burnString = "BURN_ROLE_FOR_ID";

let accounts;
let helperRoleContract;

describe("HelperContracts: HelperRoleContract", () => {
  before(async () => {
    accounts = await ethers.getSigners();
  });
  it("Contract deploy", async () => {
    const HelperRoleContract = await ethers.getContractFactory(
      "HelperRoleContract"
    );
    const helperRoleContract = await HelperRoleContract.deploy();
  });
  describe("Methods:", () => {
    beforeEach(async () => {
      const HelperRoleContract = await ethers.getContractFactory(
        "HelperRoleContract"
      );
      helperRoleContract = await HelperRoleContract.deploy();
    });
    describe("getMintRoleBytes:", () => {
      it(`Should return keccak256 of ${mintString} + id (${testCases} test)`, async () => {
        for (i = 0; i < testCases; i++) {
          const id = getRandomInteger();
          const byteRole = await helperRoleContract.getMintRoleBytes(id);
          expect(byteRole).to.be.equal(
            ethers.utils.solidityKeccak256(
              ["string", "uint256"],
              [mintString, id]
            )
          );
        }
      });
    });

    describe("getMintRoleBytes:", () => {
      it(`Should return keccak256 of ${burnString} + id (${testCases} test)`, async () => {
        for (i = 0; i < testCases; i++) {
          const id = getRandomInteger();
          const byteRole = await helperRoleContract.getBurnRoleBytes(id);
          expect(byteRole).to.be.equal(
            ethers.utils.solidityKeccak256(
              ["string", "uint256"],
              [burnString, id]
            )
          );
        }
      });
    });

    describe("getMultiMintRoleBytes:", () => {
      it(`Should return keccak256 of ${mintString} + id array (${testCases} input)`, async () => {
        const input = [];
        const expectedOutput = [];

        for (i = 0; i < testCases; i++) {
          const random = getRandomInteger();
          input[i] = random;
          expectedOutput[i] = ethers.utils.solidityKeccak256(
            ["string", "uint256"],
            [mintString, random]
          );
        }

        bytesRoles = await helperRoleContract.getMultiMintRoleBytes(input);

        expect(bytesRoles).to.be.deep.equal(expectedOutput);
      });
    });

    describe("getMultiBurnRoleBytes:", () => {
      it(`Should return keccak256 of ${burnString} + id array (${testCases} input)`, async () => {
        const input = [];
        const expectedOutput = [];

        for (i = 0; i < testCases; i++) {
          const random = getRandomInteger();
          input[i] = random;
          expectedOutput[i] = ethers.utils.solidityKeccak256(
            ["string", "uint256"],
            [burnString, random]
          );
        }

        bytesRoles = await helperRoleContract.getMultiBurnRoleBytes(input);

        expect(bytesRoles).to.be.deep.equal(expectedOutput);
      });
    });

    describe("getRangeMintRoleBytes:", () => {
      it(`Should return keccak256 of ${mintString} + id from number to number (${testCases} number)`, async () => {
        const startIndex = getRandomInteger();
        const endIndex = startIndex + testCases - 1;
        const expectedOutput = [];

        for (i = 0; i < testCases; i++) {
          expectedOutput[i] = ethers.utils.solidityKeccak256(
            ["string", "uint256"],
            [mintString, i + startIndex]
          );
        }

        bytesRoles = await helperRoleContract.getRangeMintRoleBytes(
          startIndex,
          endIndex
        );

        expect(bytesRoles).to.be.deep.equal(expectedOutput);
      });
    });

    describe("getRangeBurnRoleBytes:", () => {
      it(`Should return keccak256 of ${burnString} + id from number to number (${testCases} number)`, async () => {
        const startIndex = getRandomInteger();
        const endIndex = startIndex + testCases - 1;
        const expectedOutput = [];

        for (i = 0; i < testCases; i++) {
          expectedOutput[i] = ethers.utils.solidityKeccak256(
            ["string", "uint256"],
            [burnString, i + startIndex]
          );
        }

        bytesRoles = await helperRoleContract.getRangeBurnRoleBytes(
          startIndex,
          endIndex
        );

        expect(bytesRoles).to.be.deep.equal(expectedOutput);
      });
    });
  });
});

const getRandomInteger = () => {
  return Math.floor(Math.random() * 100000);
};
