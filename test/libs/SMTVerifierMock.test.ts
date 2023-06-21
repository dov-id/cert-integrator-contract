import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Reverter } from "../helpers/reverter";
import { getPoseidons } from "../helpers/poseidons";

describe("SMTVerifierMock", async () => {
  const reverter = new Reverter();

  let smtVerifierMock: Contract;

  let USER1: SignerWithAddress;

  let ROOT: string;
  let KEY: string;
  let VAL: string;
  let PROOF: string[];

  before(async () => {
    [USER1] = await ethers.getSigners();

    ROOT = "0x98d13a98860abb4a27d2b45e34e131007ab8c292911af602fcdc946491400605";
    KEY = "0x4e04f9e04f79fa38ce851d00a796711ba49d7452000000000000000000000000";
    VAL = "0x0300000000000000000000000000000000000000000000000000000000000000";
    PROOF = [
      "0x4fdfb00028ec623ee450d9082c2325d3bae3ec428752c03bab46040064221413",
      "0x0792787955ec14921014044ef7ab48ff10ae31cd74b62e819c0097f3292c042c",
    ];

    let { poseidonHasher2, poseidonHasher3 } = await getPoseidons();

    const SMTVerifierMockContract = await ethers.getContractFactory("SMTVerifierMock", {
      libraries: {
        PoseidonUnit2L: poseidonHasher2.address,
        PoseidonUnit3L: poseidonHasher3.address,
      },
    });

    smtVerifierMock = await SMTVerifierMockContract.deploy();

    await reverter.snapshot();
  });

  afterEach("revert", reverter.revert);

  describe("#verify", () => {
    it("should verify", async () => {
      expect(await smtVerifierMock.verify(ROOT, KEY, VAL, PROOF)).to.equal(true);
    });

    it("should not verify", async () => {
      const proof = [
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x9f341c74c45f6f3a785981307c1d07a060b936fe5f4d022c0f9b64546f590818",
      ];

      expect(await smtVerifierMock.verify(ROOT, KEY, VAL, proof)).to.be.equal(false);
    });

    it("should revert empty merklee tree proof", async () => {
      await expect(smtVerifierMock.verify(ROOT, KEY, VAL, [])).to.be.revertedWith(
        "SMTVerifier: sparse merkle tree proof is empty"
      );
    });
  });
});
