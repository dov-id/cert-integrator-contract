import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { poseidonContract } from "circomlibjs";

import { Reverter } from "../helpers/reverter";

describe("SMTVerifierMock", async () => {
  const reverter = new Reverter();

  let smtVerifierMock: any;
  let poseidonHasher2: any;
  let poseidonHasher3: any;

  let USER1: SignerWithAddress;
  let USER2: SignerWithAddress;

  let ROOT: string;
  let KEY: string;
  let VAL: string;
  let PROOF: string[];

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

  before(async () => {
    [USER1, USER2] = await ethers.getSigners();

    ROOT = "0xFFF7D65808452F96D578A2C159315B487A4AF2EDA920AD9B2E572FF47309C714";
    KEY = "0x4e04f9e04f79fa38ce851d00a796711ba49d7452000000000000000000000000";
    VAL = "0x0700000000000000000000000000000000000000000000000000000000000000";
    PROOF = [
      "0x881f67d73a511142dec454a3740715d651757fa8253c472d34ad0d445675b81c",
      "0x0a2f9c391b35de90fd822faaf8bce96bc8bd07e351fbd7d30337be7296295628",
    ];

    let poseidons = await getPoseidons();
    poseidonHasher2 = poseidons.poseidonHasher2;
    poseidonHasher3 = poseidons.poseidonHasher3;

    const SMTVerifierMockContract = await ethers.getContractFactory("SMTVerifierMock");
    smtVerifierMock = await SMTVerifierMockContract.deploy();

    await reverter.snapshot();
  });

  afterEach("revert", reverter.revert);

  describe("#verify", () => {
    it("should verify", async () => {
      expect(
        await smtVerifierMock.verify(ROOT, KEY, VAL, PROOF, poseidonHasher2.address, poseidonHasher3.address)
      ).to.equal(true);
    });

    it("should not verify", async () => {
      let proof = [
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x9f341c74c45f6f3a785981307c1d07a060b936fe5f4d022c0f9b64546f590818",
      ];

      expect(
        await smtVerifierMock.verify(ROOT, KEY, VAL, proof, poseidonHasher2.address, poseidonHasher3.address)
      ).to.be.equal(false);
    });

    it("should revert empty merklee tree proof", async () => {
      await expect(
        smtVerifierMock.verify(ROOT, KEY, VAL, [], poseidonHasher2.address, poseidonHasher3.address)
      ).to.be.revertedWith("SMTVerifier: sparse merkle tree proof is empty");
    });
  });
});
