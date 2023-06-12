import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { poseidonContract } from "circomlibjs";

import { Reverter } from "./helpers/reverter";

describe("FeedbackRegistry", async () => {
  const reverter = new Reverter();

  let feedbackRegistry: any;
  let certIntegrator: any;

  let USER1: SignerWithAddress;
  let USER2: SignerWithAddress;

  let IPFS: string;
  let KEY: string;
  let VAL: string;
  let PROOF: string[];

  let COURSE = "0x736f6d65636f757273656e616d65";

  async function getPoseidons() {
    const [deployer] = await ethers.getSigners();
    const PoseidonHasher2 = new ethers.ContractFactory(
      poseidonContract.generateABI(2),
      poseidonContract.createCode(2),
      deployer
    );
    const poseidonHasher2 = await PoseidonHasher2.deploy();
    await poseidonHasher2.deployed();

    const PoseidonHasher3 = new ethers.ContractFactory(
      poseidonContract.generateABI(3),
      poseidonContract.createCode(3),
      deployer
    );
    const poseidonHasher3 = await PoseidonHasher3.deploy();
    await poseidonHasher3.deployed();

    return { poseidonHasher2, poseidonHasher3 };
  }

  async function initCertIntegrator() {
    const certIntegratorContract = await ethers.getContractFactory("CertIntegrator");
    certIntegrator = await certIntegratorContract.deploy();

    const values = [
      "0x0000000000000000000000000000000000000000000000000000000000000001",
      "0x0000000000000000000000000000000000000000000000000000000000000002",
      "0x2018445dcff761ed409e5595ab55308a99828d7f803240a005d8bbb4d1c69924",
    ];

    for (let i = 0; i < values.length; i++) {
      await certIntegrator.updateCourseState([COURSE], [values[i]]);
    }

    return certIntegrator;
  }

  before(async () => {
    [USER1, USER2] = await ethers.getSigners();

    IPFS = "0x7af6ecdae63aa6c4835fd2a146afb79d48610e5ae23769716543be21b6a11fed";
    KEY = "0x00000000000000000000000052749da41b7196a7001d85ce38fa794fe0f9044e";
    VAL = "0x0000000000000000000000000000000000000000000000000000000000000002";
    PROOF = [
      "0x212aa7bcc2bb05ce87b473e078e9c949d56d6a720d14a7a28fe00e9e26d831d4",
      "0x15fe426825eee5fbb0b4f80e24a5a7742115c44ac909684ae21de6b1de3351d2",
    ];

    certIntegrator = await initCertIntegrator();

    let { poseidonHasher2, poseidonHasher3 } = await getPoseidons();

    const feedbackRegistryContract = await ethers.getContractFactory("FeedbackRegistry");
    feedbackRegistry = await feedbackRegistryContract.deploy(
      certIntegrator.address,
      poseidonHasher2.address,
      poseidonHasher3.address
    );

    await reverter.snapshot();
  });

  afterEach("revert", reverter.revert);

  describe("#addFeedback", () => {
    it("should add feedback correctly", async () => {
      const signature = await USER1.signMessage(ethers.utils.arrayify(IPFS));
      await feedbackRegistry.connect(USER1).addFeedback(COURSE, signature, PROOF, KEY, VAL, IPFS);

      expect(await feedbackRegistry.contractFeedbacks(COURSE, 0)).to.equal(IPFS);
    });

    it("should revert merklee tree verification", async () => {
      const signature = await USER1.signMessage(ethers.utils.arrayify(IPFS));

      await expect(
        feedbackRegistry.connect(USER1).addFeedback(COURSE, signature, [], KEY, VAL, IPFS)
      ).to.be.revertedWith("FeedbackRegistry: wrong merkle tree verification");
    });

    it("should revert wrong ecdsa signature", async () => {
      const signature = await USER1.signMessage(ethers.utils.arrayify(IPFS));

      await expect(
        feedbackRegistry.connect(USER2).addFeedback(COURSE, signature, PROOF, KEY, VAL, IPFS)
      ).to.be.revertedWith("FeedbackRegistry: wrong signature");
    });

    it("should revert wrong data length", async () => {
      const signature = await USER1.signMessage(ethers.utils.arrayify(IPFS));

      await expect(
        feedbackRegistry
          .connect(USER1)
          .addFeedback(
            COURSE,
            signature,
            PROOF,
            KEY,
            VAL,
            "0x7af6ecdae63aa6c4835fd2a146afb79d48610e5ae23769716543be21b6a1"
          )
      ).to.be.revertedWith("FeedbackRegistry: input data must be at least 32 bytes");
    });
  });

  describe("#getFeedbacks", () => {
    it("should return feedback for course", async () => {
      const signature = await USER1.signMessage(ethers.utils.arrayify(IPFS));
      await feedbackRegistry.connect(USER1).addFeedback(COURSE, signature, PROOF, KEY, VAL, IPFS);

      expect(await feedbackRegistry.getFeedbacks(COURSE, 0, 3)).to.deep.equal([IPFS]);
    });
  });
});
