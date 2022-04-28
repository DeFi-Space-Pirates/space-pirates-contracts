const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking", function () {
    let tokens;
    let staking;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    beforeEach(async function () {
        const Tokens = await ethers.getContractFactory("Tokens");
        const Staking = await ethers.getContractFactory("Staking");

        [owner, add1, addr2, ...addrs] = await ethers.getSigners();

        tokens = await Tokens.deploy();
        staking = await Staking.deploy(tokens.address);
    })

    it("should create a new staking pair", async function () {
        const doubloons = await tokens.DOUBLOONS();

        await staking.createStakingPair(doubloons, doubloons, 10, 100);

        const [exists, rewardTokenId, rewardRate, depositFee] =
            await staking.stakingPairs(doubloons);

        expect(exists).to.equal(true);
        expect(rewardTokenId).to.equal(doubloons);
        expect(rewardRate).to.be.equal(10);
        expect(depositFee).to.be.equal(100);
    });


    it("should update a new staking pair", async function () {
        const doubloons = await tokens.DOUBLOONS();
        const asteroids = await tokens.ASTEROIDS();

        await staking.createStakingPair(doubloons, doubloons, 10, 100);
        await staking.updateStakingPair(doubloons, asteroids, true, 10, 100);

        let [exists, rewardTokenId, rewardRate, depositFee] =
            await staking.stakingPairs(doubloons);

        expect(exists).to.equal(true);
        expect(rewardTokenId).to.equal(asteroids);
        expect(rewardRate).to.be.equal(10);
        expect(depositFee).to.be.equal(100);
    });


})