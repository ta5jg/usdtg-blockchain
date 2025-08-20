
import { expect } from "chai";
import { ethers } from "hardhat";
describe("USDTg", function () {
  it("mints & burns", async function () {
    const [owner, u] = await ethers.getSigners();
    const C = await ethers.getContractFactory("USDTg");
    const c = await C.deploy(owner.address);
    await c.waitForDeployment();
    await (await c.mint(u.address, 1000n)).wait();
    expect(await c.balanceOf(u.address)).to.equal(1000n);
    await (await c.connect(u).burn(400n)).wait();
    expect(await c.balanceOf(u.address)).to.equal(600n);
  });
});
