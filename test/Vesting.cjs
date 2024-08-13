const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Vesting Contract", function () {
  let Vesting, vesting;
  let owner, addr1, addr2;
  const vestingEndDay = 100; // 100 days
  const claimEndDay = 200; // 200 days
  const adminComm = 100; // 1% fee

  beforeEach(async function () {
    Vesting = await ethers.getContractFactory("Vesting");
    [owner, addr1, addr2] = await ethers.getSigners();
    vesting = await Vesting.deploy(adminComm, vestingEndDay, claimEndDay);
    await vesting.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await vesting.owner()).to.equal(owner.address);
    });

    it("Should set the correct admin commission, vesting end day, and claim end day", async function () {
      expect(await vesting.adminComm()).to.equal(adminComm);
      expect(await vesting.vestingEndDay()).to.equal(vestingEndDay * 86400);
      expect(await vesting.claimEndDay()).to.equal(claimEndDay * 86400);
    });
  });

  describe("Ownership Transfer", function () {
    it("Should transfer ownership to a new owner", async function () {
      await vesting.transferOwnership(addr1.address);
      await vesting.connect(addr1).acceptOwnership();
      expect(await vesting.owner()).to.equal(addr1.address);
    });

    it("Should prevent non-owner from transferring ownership", async function () {
      await expect(
        vesting.connect(addr1).transferOwnership(addr2.address)
      ).to.be.revertedWith("Caller is not the owner");
    });

    it("Should revert if new owner is the zero address", async function () {
      await expect(
         vesting.transferOwnership(ethers.constants.AddressZero)
      ).to.be.revertedWith("New owner is 0");
    });
  });

  describe("Vesting Allocation and Claims", function () {
    it("Should allocate funds for vesting", async function () {
      await vesting.allocateForVesting(addr1.address, { value: ethers.utils.parseEther("10") });
      const userInfo = await vesting.userInfo(addr1.address);
      expect(userInfo.totalAllocatedAmount).to.equal(ethers.utils.parseEther("10"));
      expect(userInfo.wallet).to.equal(addr1.address);
    });

    it("Should not allow claiming before the vesting start", async function () {
      await vesting.allocateForVesting(addr1.address, { value: ethers.utils.parseEther("10") });
      expect(vesting.claimTokens(addr1.address, 0)).to.be.reverted;
    });

    it("Should allow claiming after the vesting period starts", async function () {
      await vesting.allocateForVesting(addr1.address, { value: ethers.utils.parseEther("10") });

      // Fast forward time
      await ethers.provider.send("evm_increaseTime", [vestingEndDay * 86400]);
      await ethers.provider.send("evm_mine");

      await vesting.claimTokens(addr1.address, 0);
      const userInfo = await vesting.userInfo(addr1.address);
      expect(userInfo.totalClaimedAmount).to.be.gt(0);
    });
  });

  describe("Admin Commission", function () {
    it("Should allow the owner to update the admin commission", async function () {
      await vesting.updateAdminCommission(200);
      expect(await vesting.adminComm()).to.equal(200);
    });

    it("Should prevent non-owners from updating the admin commission", async function () {
      await expect(
        vesting.connect(addr1).updateAdminCommission(200)
      ).to.be.revertedWith("Caller is not the owner");
    });

    it("Should revert if the new admin commission is the same as the old one", async function () {
      await expect(
        vesting.updateAdminCommission(adminComm)
      ).to.be.revertedWith("New value same as old");
    });
  });

  describe("Withdrawals", function () {
    it("Should allow the owner to withdraw funds", async function () {
      await vesting.allocateForVesting(addr1.address, { value: ethers.utils.parseEther("10") });
      await expect(() => vesting.withdraw()).to.changeEtherBalance(owner, ethers.utils.parseEther("10"));
    });

    it("Should prevent non-owners from withdrawing funds", async function () {
      await expect(vesting.connect(addr1).withdraw()).to.be.revertedWith("Caller is not the owner");
    });
  });

  describe("Vesting Day Updates", function () {
    it("Should allow the owner to update vesting and claim end days", async function () {
      await vesting.updateVestingDays(150, 300);
      expect(await vesting.vestingEndDay()).to.equal(150 * 86400);
      expect(await vesting.claimEndDay()).to.equal(300 * 86400);
    });

    it("Should revert if the new vesting end day is the same as the old one", async function () {
      expect(
        vesting.updateVestingDays(150 * 86400, 350 * 86400)
      ).to.be.revertedWith("Vesting end value is same as old");
    });

    it("Should revert if the new claim end day is the same as the old one", async function () {
      expect(
        vesting.updateVestingDays(300 * 86400, 350 * 86400)
      ).to.be.revertedWith("Claim end value is same as old");
    });
  });
});
