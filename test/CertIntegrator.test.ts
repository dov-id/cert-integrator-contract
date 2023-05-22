import { accounts } from "@/scripts/utils/utils";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("CertIntegrator", () => {
  let certIntegrator: any;

  before(async () => {
    const certIntegratorContract = await ethers.getContractFactory("CertIntegrator");
    certIntegrator = await certIntegratorContract.deploy();
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

    it("should be empty result", async () => {
      expect(
        await certIntegrator.contractData(
          "0x736f6d65636f757273656e616d65000000000000000000000000000000000000",
          "0x0000000000000000000000000000000000000000000000000000000000000001"
        )
      ).to.equal(0);
    });

    it("should add statement to the course", async () => {
      await certIntegrator.updateCourseState(
        ["0x736f6d65636f757273656e616d65000000000000000000000000000000000000"],
        ["0x0000000000000000000000000000000000000000000000000000000000000001"]
      );
      const blockNumber = await ethers.provider.getBlockNumber();

      expect(
        await certIntegrator.contractData(
          "0x736f6d65636f757273656e616d65000000000000000000000000000000000000",
          "0x0000000000000000000000000000000000000000000000000000000000000001"
        )
      ).to.equal(blockNumber);
    });

    it("should add statements to the course", async () => {
      await certIntegrator.updateCourseState(
        ["0x736f6d65636f757273656e616d65000000000000000000000000000000000000"],
        ["0x0000000000000000000000000000000000000000000000000000000000000001"]
      );
      const blockNumber1 = await ethers.provider.getBlockNumber();

      await certIntegrator.updateCourseState(
        ["0x736f6d65636f757273656e616d65000000000000000000000000000000000000"],
        ["0x0000000000000000000000000000000000000000000000000000000000000002"]
      );
      const blockNumber2 = await ethers.provider.getBlockNumber();

      await certIntegrator.updateCourseState(
        ["0x736f6d65636f757273656e616d65000000000000000000000000000000000000"],
        ["0x0000000000000000000000000000000000000000000000000000000000000003"]
      );
      const blockNumber3 = await ethers.provider.getBlockNumber();

      expect(
        await certIntegrator.contractData(
          "0x736f6d65636f757273656e616d65000000000000000000000000000000000000",
          "0x0000000000000000000000000000000000000000000000000000000000000001"
        )
      ).to.equal(blockNumber1);

      expect(
        await certIntegrator.contractData(
          "0x736f6d65636f757273656e616d65000000000000000000000000000000000000",
          "0x0000000000000000000000000000000000000000000000000000000000000002"
        )
      ).to.equal(blockNumber2);

      expect(
        await certIntegrator.contractData(
          "0x736f6d65636f757273656e616d65000000000000000000000000000000000000",
          "0x0000000000000000000000000000000000000000000000000000000000000003"
        )
      ).to.equal(blockNumber3);

      expect(
        await certIntegrator.contractData(
          "0x736f6d65636f757273656e616d65000000000000000000000000000000000000",
          "0x0000000000000000000000000000000000000000000000000000000000000004"
        )
      ).to.equal(0);
    });
  });
});
