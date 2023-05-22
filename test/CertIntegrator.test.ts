import { accounts } from "@/scripts/utils/utils";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("CertIntegrator", () => {
  let certIntegrator: any;

  before(async () => {
    const certIntegratorContract = await ethers.getContractFactory("CertIntegrator");
    certIntegrator = await certIntegratorContract.deploy(3);
  });

  describe("#constructor", () => {
    it("should set parameters correctly", async () => {
      expect(await certIntegrator.getRootsAmount()).to.eq(3);
    });
  });

  describe("#getLastBLock", async () => {
    it("should revert for empty queue", async () => {
      await expect(
        certIntegrator.getLastBlock("0x736f6d65636f757273656e616d65000000000000000000000000000000000000")
      ).to.be.revertedWith("getLastBlock: empty queue");
    });
  });

  describe("#getLastRoot", () => {
    it("should revert for empty queue", async () => {
      await expect(
        certIntegrator.getLastRoot("0x736f6d65636f757273656e616d65000000000000000000000000000000000000")
      ).to.be.revertedWith("getLastRoot: empty queue");
    });
  });

  describe("#updateCourseState", () => {
    it("should revert with different array sizes", async () => {
      await expect(
        certIntegrator.updateCourseState(
          ["0x736f6d65636f757273656e616d65000000000000000000000000000000000000"],
          [
            "0x0000000000000000000000000000000000000000000000000000000000000001",
            "0x0000000000000000000000000000000000000000000000000000000000000002",
          ]
        )
      ).to.be.revertedWith("updateCourseState: courses and states arrays must be the same size");
    });

    it("should revert for not owner caller", async () => {
      const notOwner = await accounts(2);

      await expect(
        certIntegrator
          .connect(notOwner)
          .updateCourseState(
            ["0x736f6d65636f757273656e616d65000000000000000000000000000000000000"],
            ["0x0000000000000000000000000000000000000000000000000000000000000001"]
          )
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should update course", async () => {
      await certIntegrator.updateCourseState(
        ["0x736f6d65636f757273656e616d65000000000000000000000000000000000000"],
        ["0x0000000000000000000000000000000000000000000000000000000000000001"]
      );
      const blockNumber = await ethers.provider.getBlockNumber();

      expect(
        await certIntegrator.getLastRoot("0x736f6d65636f757273656e616d65000000000000000000000000000000000000")
      ).to.equal("0x0000000000000000000000000000000000000000000000000000000000000001");

      expect(
        await certIntegrator.getLastBlock("0x736f6d65636f757273656e616d65000000000000000000000000000000000000")
      ).to.equal(blockNumber);
    });

    it("should update course with shift queue", async () => {
      await certIntegrator.updateCourseState(
        ["0x736f6d65636f757273656e616d65000000000000000000000000000000000000"],
        ["0x0000000000000000000000000000000000000000000000000000000000000001"]
      );

      await certIntegrator.updateCourseState(
        ["0x736f6d65636f757273656e616d65000000000000000000000000000000000000"],
        ["0x0000000000000000000000000000000000000000000000000000000000000002"]
      );

      await certIntegrator.updateCourseState(
        ["0x736f6d65636f757273656e616d65000000000000000000000000000000000000"],
        ["0x0000000000000000000000000000000000000000000000000000000000000003"]
      );

      await certIntegrator.updateCourseState(
        ["0x736f6d65636f757273656e616d65000000000000000000000000000000000000"],
        ["0x0000000000000000000000000000000000000000000000000000000000000004"]
      );

      const blockNumber = await ethers.provider.getBlockNumber();

      expect(
        await certIntegrator.getLastRoot("0x736f6d65636f757273656e616d65000000000000000000000000000000000000")
      ).to.equal("0x0000000000000000000000000000000000000000000000000000000000000004");

      expect(
        await certIntegrator.getLastBlock("0x736f6d65636f757273656e616d65000000000000000000000000000000000000")
      ).to.equal(blockNumber);
    });
  });
});
