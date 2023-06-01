import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Reverter } from "./helpers/reverter";

describe("CertIntegrator", () => {
  const reverter = new Reverter();

  let certIntegrator: any;

  let OWNER: SignerWithAddress;
  let USER: SignerWithAddress;

  let COURSE: string;
  let VALUE1: string;
  let VALUE2: string;
  let VALUE3: string;

  before(async () => {
    const certIntegratorContract = await ethers.getContractFactory("CertIntegrator");
    certIntegrator = await certIntegratorContract.deploy();
    [OWNER, USER] = await ethers.getSigners();

    COURSE = "0x736f6d65636f757273656e616d65";
    VALUE1 = "0x0000000000000000000000000000000000000000000000000000000000000001";
    VALUE2 = "0x0000000000000000000000000000000000000000000000000000000000000002";
    VALUE3 = "0x0000000000000000000000000000000000000000000000000000000000000003";

    await reverter.snapshot();
  });

  afterEach("revert", reverter.revert);

  describe("#updateCourseState", () => {
    it("should revert with different array sizes", async () => {
      const err = "CertIntegrator: courses and states arrays must be the same size";
      await expect(certIntegrator.updateCourseState([COURSE], [VALUE1, VALUE2])).to.be.revertedWith(err);
    });

    it("should revert for not owner caller", async () => {
      const err = "Ownable: caller is not the owner";
      await expect(certIntegrator.connect(USER).updateCourseState([COURSE], [VALUE1])).to.be.revertedWith(err);
    });

    it("should add statements to the course", async () => {
      const values = [VALUE1, VALUE2, VALUE3];

      for (let i = 0; i < values.length; i++) {
        await certIntegrator.updateCourseState([COURSE], [values[i]]);
        const blockNumber = await ethers.provider.getBlockNumber();
        const bigBlockNumber = ethers.BigNumber.from(blockNumber);

        expect(await certIntegrator.contractData(COURSE, i)).to.deep.equal([bigBlockNumber, values[i]]);
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
        const bigBlockNumber = ethers.BigNumber.from(blockNumber);
        results.push([bigBlockNumber, values[i]]);
      }

      expect(await certIntegrator.getData(COURSE)).to.deep.equal(results);
    });
  });

  describe("#getLastData", () => {
    it("should revert for empty course", async () => {
      const err = "CertIntegrator: course info is empty";
      await expect(certIntegrator.getLastData(COURSE)).to.be.revertedWith(err);
    });

    it("should return last inserted data of the course", async () => {
      const values = [VALUE1, VALUE2, VALUE3];
      let bigBlockNumber;

      for (let i = 0; i < values.length; i++) {
        await certIntegrator.updateCourseState([COURSE], [values[i]]);
        const blockNumber = await ethers.provider.getBlockNumber();
        bigBlockNumber = ethers.BigNumber.from(blockNumber);
      }

      expect(await certIntegrator.getLastData(COURSE)).to.deep.equal([bigBlockNumber, VALUE3]);
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
