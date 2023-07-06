import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Reverter } from "./helpers/reverter";

describe("CertIntegrator", () => {
  const reverter = new Reverter();

  let certIntegrator: Contract;

  let OWNER: SignerWithAddress;
  let USER: SignerWithAddress;

  let COURSE: string;
  let VALUE1: string;
  let VALUE2: string;
  let VALUE3: string;

  before(async () => {
    [OWNER, USER] = await ethers.getSigners();

    COURSE = "0x63223538169D7228b37C9182eD6d2b9B2CfD8F26";
    VALUE1 = "0x0000000000000000000000000000000000000000000000000000000000000001";
    VALUE2 = "0x0000000000000000000000000000000000000000000000000000000000000002";
    VALUE3 = "0x0000000000000000000000000000000000000000000000000000000000000003";

    const certIntegratorContract = await ethers.getContractFactory("CertIntegrator");
    certIntegrator = await certIntegratorContract.deploy();

    await reverter.snapshot();
  });

  afterEach("revert", reverter.revert);

  describe("#updateCourseState", () => {
    it("should revert with different array sizes", async () => {
      await expect(certIntegrator.updateCourseState([COURSE], [VALUE1, VALUE2])).to.be.revertedWith(
        "CertIntegrator: courses and states arrays must be the same size"
      );
    });

    it("should revert for not owner caller", async () => {
      await expect(certIntegrator.connect(USER).updateCourseState([COURSE], [VALUE1])).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("should add statements to the course", async () => {
      const values = [VALUE1, VALUE2, VALUE3];

      for (let i = 0; i < values.length; i++) {
        await certIntegrator.updateCourseState([COURSE], [values[i]]);
        const blockNumber = await ethers.provider.getBlockNumber();

        expect(await certIntegrator.contractData(COURSE, i)).to.deep.equal([blockNumber, values[i]]);
      }
    });
  });

  describe("#getData", () => {
    it("should return data of the course", async () => {
      const values = [VALUE1, VALUE2, VALUE3];
      let results = [];

      for (let i = 0; i < values.length; i++) {
        await certIntegrator.updateCourseState([COURSE], [values[i]]);

        const blockNumber = await ethers.provider.getBlockNumber();
        results.push([blockNumber, values[i]]);
      }

      expect(await certIntegrator.getData(COURSE)).to.deep.equal(results);
    });
  });

  describe("#getLastData", () => {
    it("should revert for empty course", async () => {
      await expect(certIntegrator.getLastData(COURSE)).to.be.revertedWith("CertIntegrator: course info is empty");
    });

    it("should return last inserted data of the course", async () => {
      const values = [VALUE1, VALUE2, VALUE3];

      for (let i = 0; i < values.length; i++) {
        await certIntegrator.updateCourseState([COURSE], [values[i]]);
      }

      const blockNumber = await ethers.provider.getBlockNumber();

      expect(await certIntegrator.getLastData(COURSE)).to.deep.equal([blockNumber, VALUE3]);
    });
  });

  describe("#getDataLength", () => {
    it("should return inserted data length of the course", async () => {
      const values = [VALUE1, VALUE2, VALUE3];

      for (let i = 0; i < values.length; i++) {
        await certIntegrator.updateCourseState([COURSE], [values[i]]);
      }

      expect(await certIntegrator.getDataLength(COURSE)).to.deep.equal(3);
    });
  });
});
