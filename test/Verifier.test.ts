import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Reverter } from "./helpers/reverter";
import { getPoseidons } from "./helpers/poseidons";
import { initCertIntegrator } from "./helpers/utils";

describe("Verifier", async () => {
  const reverter = new Reverter();

  let verifier: Contract;
  let certIntegrator: Contract;
  let tokenContaract: Contract;

  let USER1: SignerWithAddress;
  let USER2: SignerWithAddress;

  let IPFS: string;
  let KEY: string;
  let VAL: string;
  let PROOF: string[];
  let URI: string;

  let COURSE: string;

  async function getTokenFactory(): Promise<Contract> {
    const TokenFactory = await ethers.getContractFactory("TokenFactory");
    const tokenFactoryImpl = await TokenFactory.deploy();

    const PublicERC1967Proxy = await ethers.getContractFactory("PublicERC1967Proxy");

    const _tokenFactoryProxy = await PublicERC1967Proxy.deploy(tokenFactoryImpl.address, "0x");

    const tokenFactory = TokenFactory.attach(_tokenFactoryProxy.address);

    await tokenFactory.__TokenFactory_init("base uri/");

    const TokenContract = await ethers.getContractFactory("TokenContract");
    const tokenContractImpl = await TokenContract.deploy();

    await tokenFactory.setNewImplementation(tokenContractImpl.address);

    expect(await tokenFactory.getTokenContractsImpl()).to.equal(tokenContractImpl.address);

    return tokenFactory;
  }

  async function getTokenContract(
    tokenFactory: Contract,
    tokenId: number,
    tokenName: string,
    tokenSymbol: string
  ): Promise<Contract> {
    await tokenFactory.connect(USER1).deployTokenContract([tokenId, tokenName, tokenSymbol]);

    const addr = await tokenFactory.tokenContractByIndex(tokenId);

    const TokenContract = await ethers.getContractFactory("TokenContract");

    return TokenContract.attach(addr);
  }

  before(async () => {
    [USER1, USER2] = await ethers.getSigners();

    IPFS = "0x7af6ecdae63aa6c4835fd2a146afb79d48610e5ae23769716543be21b6a11fed";
    KEY = "0x4e04f9e04f79fa38ce851d00a796711ba49d7452000000000000000000000000";
    VAL = "0x0700000000000000000000000000000000000000000000000000000000000000";
    PROOF = [
      "0x881f67d73a511142dec454a3740715d651757fa8253c472d34ad0d445675b81c",
      "0x0a2f9c391b35de90fd822faaf8bce96bc8bd07e351fbd7d30337be7296295628",
    ];
    URI = "ipfs/ uri";

    const tokenFactory = await getTokenFactory();

    tokenContaract = await getTokenContract(tokenFactory, 1, "TokenName", "TN");
    COURSE = tokenContaract.address;

    certIntegrator = await initCertIntegrator(COURSE);

    let { poseidonHasher2, poseidonHasher3 } = await getPoseidons();

    const verifierContract = await ethers.getContractFactory("Verifier", {
      libraries: {
        PoseidonUnit2L: poseidonHasher2.address,
        PoseidonUnit3L: poseidonHasher3.address,
      },
    });

    verifier = await verifierContract.deploy(certIntegrator.address);

    await tokenContaract.connect(USER1).setNewAdmin(verifier.address);

    await reverter.snapshot();
  });

  afterEach("revert", reverter.revert);

  describe("#verifyContract", () => {
    it("should mint token", async () => {
      const signature = await USER1.signMessage(ethers.utils.arrayify(IPFS));

      let transaction = await verifier.connect(USER1).verifyContract(COURSE, signature, PROOF, KEY, VAL, IPFS, URI);
      const tx = await transaction.wait();

      expect(parseInt(tx.events[0].topics[3], 16)).to.equal(0);
    });

    it("should revert merklee tree verification", async () => {
      const signature = await USER1.signMessage(ethers.utils.arrayify(IPFS));

      let proof = [
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x9f341c74c45f6f3a785981307c1d07a060b936fe5f4d022c0f9b64546f590818",
      ];

      await expect(
        verifier.connect(USER1).verifyContract(COURSE, signature, proof, KEY, VAL, IPFS, URI)
      ).to.be.revertedWith("Verifier: wrong merkle tree verification");
    });

    it("should revert wrong ecdsa signature", async () => {
      const signature = await USER1.signMessage(ethers.utils.arrayify(IPFS));

      await expect(
        verifier.connect(USER2).verifyContract(COURSE, signature, PROOF, KEY, VAL, IPFS, URI)
      ).to.be.revertedWith("Verifier: wrong signature");
    });
  });
});
