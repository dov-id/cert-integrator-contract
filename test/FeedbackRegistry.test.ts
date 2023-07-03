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
  let KEYS: string[];
  let VALUES: string[];
  let PROOFS: string[][];

  let I: string;
  let C: string[];
  let R: string[];
  let PUBLIC_KEYS: string[];

  before(async () => {
    [USER1, USER2] = await ethers.getSigners();

    IPFS = "QmW3p7uFghJ9xVMf95h16jRjGjKX4TDgyGzbXuq4Uw33vj";
    KEYS = [
      "0x4e04f9e04f79fa38ce851d00a796711ba49d7452000000000000000000000000",
      "0x65419d8f9be1d47adf04c157dcf3e3405e50d8f1000000000000000000000000",
      "0x04da72da5d3b0208c2cb20d53ce8a16c49436150000000000000000000000000",
      "0x2cbff6fb6fe31586e9a2952b95daf86395a4ab53000000000000000000000000",
      "0x00593216e5b241ba85b9aa296d98b14a390a06c9000000000000000000000000",
    ];

    VALUES = [
      "0x0300000000000000000000000000000000000000000000000000000000000000",
      "0x0100000000000000000000000000000000000000000000000000000000000000",
      "0x0200000000000000000000000000000000000000000000000000000000000000",
      "0x0100000000000000000000000000000000000000000000000000000000000000",
      "0x0100000000000000000000000000000000000000000000000000000000000000",
    ];

    PROOFS = [
      [
        "0xd6d8b50f7b17156031b2c8eb2a9e91e808f3e096e2a7a445e4d98fceed675c01",
        "0xfba874f67a121eeea4d89cca02e55073f0f6caa78181aac177db3c0722c24f28",
      ],
      ["0x45fd4c32fb406759ff169fccaf8e041d73287f3e4dc156b6ab7e1a45cc6a051c"],
      [
        "0xd6d8b50f7b17156031b2c8eb2a9e91e808f3e096e2a7a445e4d98fceed675c01",
        "0xc1c7b47d980404e55fcadba46290561e362e89cbe3922de0ee69905f34484517",
        "0x0d9f9a5dbfce2728584c827f5140b28839d3666e71babbe7a31c0400db00ff0b",
        "0xf0bc35a3399bf316321939d9ea1d5ec8758df74bdf13c211a546ac0d20c9d510",
      ],
      [
        "0xd6d8b50f7b17156031b2c8eb2a9e91e808f3e096e2a7a445e4d98fceed675c01",
        "0xc1c7b47d980404e55fcadba46290561e362e89cbe3922de0ee69905f34484517",
        "0x0d9f9a5dbfce2728584c827f5140b28839d3666e71babbe7a31c0400db00ff0b",
        "0x4b0a5455ea47b24699ebfe1a26ed18d8a51ed0a03bdc44acf66cf48166152a2e",
      ],
      [
        "0xd6d8b50f7b17156031b2c8eb2a9e91e808f3e096e2a7a445e4d98fceed675c01",
        "0xc1c7b47d980404e55fcadba46290561e362e89cbe3922de0ee69905f34484517",
        "0x4badad9b8287758e9a83d68fb959b13454fd1c8cdf61727b74b0ef6ae5be9f20",
      ],
    ];

    C = [
      "0xca9cfd00f7a3564f02d6c0967f6309317fcc1d01f3fc2c8e9110f69ca5926da6",
      "0xeb1750210218ed8845aeb7c1a1f4fc61bcae0da3a8e51c0eb99cfb1ab802ddd9",
      "0x1f3bd911399958240fba4a4a281d1ce71eb7e21c789446ec16f211ee6bace8e0",
      "0xaaf4c0ef05ba8033933812971b5785cdd194cf4eb27ae5404863ca138867138f",
      "0xb424c189f21802155947a12b2f487c443abd3f369676036d347640c16d5a5519",
    ];
    I = "0x8d398dceaecdf2c8417c6367b32c7b10db03c861359206e5c94458c21ad2c94d";
    R = [
      "0x57c12b50828272346fb78829beeb62ce5ced11287d38cbf320496e452e99de80",
      "0xe7352f8723ba749724d805585d8651f94fdd78b8510811a6e6c68c28a0415007",
      "0x8a644d7ceeb815d3dab622e8ee8d593de1975f69f64c0f44891d8d20560488d9",
      "0x0916879ee718300e8c89d701374d360fddb95ed43a188e4d976d908ac105dcfc",
      "0xbb5e00367793aa9ca7b1dc60095c72841d6cb5ef813d43bdd3993d24f22fb9d4",
    ];

    PUBLIC_KEYS = [
      "0x042fa192fc93d2d20d6f24803465dd3f22e70d7a8a6917c134053c9dca05e7b2f9417575d42103afd5989a425f553706e277b709c2d736f864058b3a1a8c07ef18",
      "0x0421bf7f73e2e4e19a7b5a6b0e3521c72a4cc2b1a4b8c71484b5038ba5b8dad0d5f2aa3386c6f5cc99a5927f56ed423093600b8851bfa2700571df255be6c011e9",
      "0x048b74f602ea173a86b4ed7ee69333633fc9c52104721d2ecc85ce90addbef3e4bd4a26be13c569c872b6ffc0f5fbc9a220f64538b298f8c7c070baefa4386362e",
      "0x04f521fc7ea86b81a8b8eb4a635c7970ad4d9775a18d793c35c472ace32580e63e62643ed2cc87f9ab1ea934099d5c99bbf4719aab21d22cf5d528ce94b36bf4ee",
      "0x04a62b36cfcfdd7dde217542adcb7f353ac2276802d9d1ff5d346b6ac9616275adad1badd4e1f29b05927fc40db1de2ee4efdffe824e3d5768a475dfe557a4ea29",
    ];

    certIntegrator = await initCertIntegrator(COURSE, [
      "0x0000000000000000000000000000000000000000000000000000000000000001",
      "0x0000000000000000000000000000000000000000000000000000000000000002",
      "0x2018445dcff761ed409e5595ab55308a99828d7f803240a005d8bbb4d1c69924",
      "0xfff7d65808452f96d578a2c159315b487a4af2eda920ad9b2e572ff47309c714",
      "0x1236c7c84fbced418368c03b6d3ed20d40d10a24e2f140dab56a8bbf82aea80d",
    ]);

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
      await feedbackRegistry.connect(USER1).addFeedback(COURSE, I, C, R, PUBLIC_KEYS, PROOFS, KEYS, VALUES, IPFS);

      expect(await feedbackRegistry.contractFeedbacks(COURSE, 0)).to.equal(IPFS);
    });

    it("should revert merkle tree verification", async () => {
      let proof = [
        [
          "0x0000000000000000000000000000000000000000000000000000000000000000",
          "0x9f341c74c45f6f3a785981307c1d07a060b936fe5f4d022c0f9b64546f590818",
        ],
      ];

      await expect(
        feedbackRegistry.connect(USER1).addFeedback(COURSE, I, C, R, PUBLIC_KEYS, proof, KEYS, VALUES, IPFS)
      ).to.be.revertedWith("FeedbackRegistry: wrong merkle tree verification");
    });

    it("should revert empty merkle tree verification", async () => {
      await expect(
        feedbackRegistry.connect(USER1).addFeedback(COURSE, I, C, R, PUBLIC_KEYS, [[]], KEYS, VALUES, IPFS)
      ).to.be.revertedWith("SMTVerifier: sparse merkle tree proof is empty");
    });

    it("should revert wrong signature", async () => {
      let c = [
        "0x8ed015fd11e1a9a39e9846fc928d6dae0d1a5db77119dd3d799b7dc93e2b9201",
        "0x9de462503f24ae5878e58128bf90c98f6b274498873f084370c2cc323be9975b",
        "0x3932fbbbed7f4b6ba55f7de70e604f3aed5cb7a91312afb5ce26c2f2b5a23424",
        "0xff9fbb4d6360f9f95ec08aeda0ff1b8b6decc0202161ebeb9827fc798e52af06",
        "0x9c4504d65aaea495da384e9cab5988b742154acb9538cb9b8ff7fd8db3053793",
      ];

      await expect(
        feedbackRegistry.connect(USER2).addFeedback(COURSE, I, c, R, PUBLIC_KEYS, PROOFS, KEYS, VALUES, IPFS)
      ).to.be.revertedWith("FeedbackRegistry: wrong signature");
    });
  });

  // describe("#getFeedbacks", () => {
  //   it("should return feedback for course", async () => {
  //     const signature = await USER1.signMessage(ethers.utils.arrayify(IPFS));

  //     await feedbackRegistry.connect(USER1).addFeedback(COURSE, signature, PROOF, KEY, VAL, IPFS);

  //     expect(await feedbackRegistry.getFeedbacks(COURSE, 0, 3)).to.deep.equal([IPFS]);
  //   });
  // });
});
