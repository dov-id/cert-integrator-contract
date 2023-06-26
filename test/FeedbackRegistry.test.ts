import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Reverter } from "./helpers/reverter";
import { getPoseidons } from "./helpers/poseidons";
import { initCertIntegrator } from "./helpers/utils";

describe("FeedbackRegistry", async () => {
  const reverter = new Reverter();

  let feedbackRegistry: Contract;
  let certIntegrator: Contract;

  let USER1: SignerWithAddress;
  let USER2: SignerWithAddress;

  let COURSE = "0x736f6d65636f757273656e616d65";

  let IPFS: string;
  let KEY: string;
  let VAL: string;
  let PROOF: string[];

  before(async () => {
    [USER1, USER2] = await ethers.getSigners();

    IPFS = "0x7af6ecdae63aa6c4835fd2a146afb79d48610e5ae23769716543be21b6a11fed";
    KEY = "0x4e04f9e04f79fa38ce851d00a796711ba49d7452000000000000000000000000";
    VAL = "0x0700000000000000000000000000000000000000000000000000000000000000";
    PROOF = [
      "0x881f67d73a511142dec454a3740715d651757fa8253c472d34ad0d445675b81c",
      "0x0a2f9c391b35de90fd822faaf8bce96bc8bd07e351fbd7d30337be7296295628",
    ];

    certIntegrator = await initCertIntegrator(COURSE);

    let { poseidonHasher2, poseidonHasher3 } = await getPoseidons();

    const feedbackRegistryContract = await ethers.getContractFactory("FeedbackRegistry", {
      libraries: {
        PoseidonUnit2L: poseidonHasher2.address,
        PoseidonUnit3L: poseidonHasher3.address,
      },
    });

    feedbackRegistry = await feedbackRegistryContract.deploy(certIntegrator.address);

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

      let proof = [
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x9f341c74c45f6f3a785981307c1d07a060b936fe5f4d022c0f9b64546f590818",
      ];

      await expect(
        feedbackRegistry.connect(USER1).addFeedback(COURSE, signature, proof, KEY, VAL, IPFS)
      ).to.be.revertedWith("FeedbackRegistry: wrong merkle tree verification");
    });

    it("should revert empty merklee tree verification", async () => {
      const signature = await USER1.signMessage(ethers.utils.arrayify(IPFS));

      await expect(
        feedbackRegistry.connect(USER1).addFeedback(COURSE, signature, [], KEY, VAL, IPFS)
      ).to.be.revertedWith("SMTVerifier: sparse merkle tree proof is empty");
    });

    it("should revert wrong ecdsa signature", async () => {
      const signature = await USER1.signMessage(ethers.utils.arrayify(IPFS));

      await expect(
        feedbackRegistry.connect(USER2).addFeedback(COURSE, signature, PROOF, KEY, VAL, IPFS)
      ).to.be.revertedWith("FeedbackRegistry: wrong signature");
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
