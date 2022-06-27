const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

let accounts;
let ownerAddress;
let tokensContract;
let helperRoleContract;
let wrapperContract;
let erc20Contract;
let spaceETH;

describe("SpacePiratesWrapper", () => {
  before(async () => {
    const HelperRoleContract = await ethers.getContractFactory(
      "HelperRoleContract"
    );
    helperRoleContract = await HelperRoleContract.deploy();

    const TokenContract = await ethers.getContractFactory("SpacePiratesTokens");
    tokensContract = await TokenContract.deploy("");

    accounts = await ethers.getSigners();
    ownerAddress = accounts[0].getAddress();

    const WrapperContract = await ethers.getContractFactory(
      "SpacePiratesWrapper"
    );
    wrapperContract = await WrapperContract.deploy(tokensContract.address);

    const ERC20Contract = await ethers.getContractFactory("TestToken");
    erc20Contract = await ERC20Contract.deploy(10000);

    spaceETH = await wrapperContract.spaceETH();

    await tokensContract.setApprovalForAll(wrapperContract.address, true);
  });
  it("addERC20", async () => {
    const lastId = await wrapperContract.lastId();

    await wrapperContract.addERC20(erc20Contract.address);

    expect(await wrapperContract.erc20ToId(erc20Contract.address)).to.equal(
      BigNumber.from(lastId).add(1)
    );
  });
  it("erc20Deposit", async () => {
    const id = await wrapperContract.erc20ToId(erc20Contract.address);
    const prev1155Balance = await tokensContract.balanceOf(ownerAddress, id);
    const prev20Balance = await erc20Contract.balanceOf(ownerAddress);

    const mintRole = await helperRoleContract.getMintRoleBytes(id);
    await tokensContract.grantRole(mintRole, wrapperContract.address);

    const amount = 10;

    await erc20Contract.approve(wrapperContract.address, amount);
    await wrapperContract.erc20Deposit(erc20Contract.address, amount);

    expect(await tokensContract.balanceOf(ownerAddress, id)).to.equal(
      BigNumber.from(prev1155Balance).add(amount)
    );
    expect(await erc20Contract.balanceOf(ownerAddress)).to.equal(
      BigNumber.from(prev20Balance).sub(amount)
    );
  });
  it("erc20DepositTo", async () => {
    const id = await wrapperContract.erc20ToId(erc20Contract.address);
    const prev1155Balance = await tokensContract.balanceOf(ownerAddress, id);
    const prev20Balance = await erc20Contract.balanceOf(ownerAddress);

    const amount = 10;

    await erc20Contract.approve(wrapperContract.address, amount);
    await wrapperContract.erc20DepositTo(
      erc20Contract.address,
      amount,
      ownerAddress
    );

    expect(await tokensContract.balanceOf(ownerAddress, id)).to.equal(
      BigNumber.from(prev1155Balance).add(amount)
    );
    expect(await erc20Contract.balanceOf(ownerAddress)).to.equal(
      BigNumber.from(prev20Balance).sub(amount)
    );
  });
  it("erc20Withdraw", async () => {
    const id = await wrapperContract.erc20ToId(erc20Contract.address);
    const prev1155Balance = await tokensContract.balanceOf(ownerAddress, id);
    const prev20Balance = await erc20Contract.balanceOf(ownerAddress);

    const burnRole = await helperRoleContract.getBurnRoleBytes(id);
    await tokensContract.grantRole(burnRole, wrapperContract.address);

    const amount = 10;

    await wrapperContract.erc20Withdraw(erc20Contract.address, amount);

    expect(await tokensContract.balanceOf(ownerAddress, id)).to.equal(
      BigNumber.from(prev1155Balance).sub(amount)
    );
    expect(await erc20Contract.balanceOf(ownerAddress)).to.equal(
      BigNumber.from(prev20Balance).add(amount)
    );
  });
  it("erc20WithdrawTo", async () => {
    const id = await wrapperContract.erc20ToId(erc20Contract.address);
    const prev1155Balance = await tokensContract.balanceOf(ownerAddress, id);
    const prev20Balance = await erc20Contract.balanceOf(ownerAddress);

    const amount = 10;

    await wrapperContract.erc20WithdrawTo(
      erc20Contract.address,
      amount,
      ownerAddress
    );

    expect(await tokensContract.balanceOf(ownerAddress, id)).to.equal(
      BigNumber.from(prev1155Balance).sub(amount)
    );
    expect(await erc20Contract.balanceOf(ownerAddress)).to.equal(
      BigNumber.from(prev20Balance).add(amount)
    );
  });
  it("ethDeposit", async () => {
    const mintRole = await helperRoleContract.getMintRoleBytes(spaceETH);
    await tokensContract.grantRole(mintRole, wrapperContract.address);

    const prevBalance = await tokensContract.balanceOf(ownerAddress, spaceETH);

    await accounts[0].sendTransaction({
      to: wrapperContract.address,
      value: 1,
    });

    expect(
      await tokensContract.balanceOf(accounts[0].address, spaceETH)
    ).to.equal(BigNumber.from(prevBalance).add(1));
  });
  it("ethDepositTo", async () => {
    const prevBalance = await tokensContract.balanceOf(ownerAddress, spaceETH);

    await wrapperContract.ethDepositTo(ownerAddress, { value: 1 });

    expect(await tokensContract.balanceOf(ownerAddress, spaceETH)).to.equal(
      BigNumber.from(prevBalance).add(1)
    );
  });
  it("ethWithdraw", async () => {
    const burnRole = await helperRoleContract.getBurnRoleBytes(spaceETH);
    await tokensContract.grantRole(burnRole, wrapperContract.address);

    const prevBalance = await tokensContract.balanceOf(ownerAddress, spaceETH);

    await wrapperContract.ethWithdraw(1);

    expect(await tokensContract.balanceOf(ownerAddress, spaceETH)).to.equal(
      BigNumber.from(prevBalance).sub(1)
    );
  });
  it("ethWithdrawTo", async () => {
    const prevBalance = await tokensContract.balanceOf(ownerAddress, spaceETH);

    await wrapperContract.ethWithdrawTo(1, ownerAddress);

    expect(await tokensContract.balanceOf(ownerAddress, spaceETH)).to.equal(
      BigNumber.from(prevBalance).sub(1)
    );
  });
});
