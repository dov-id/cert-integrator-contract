import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";

import { Reverter } from "../helpers/reverter";

describe("RingSignatureMock", async () => {
  const reverter = new Reverter();

  let ringSignatureMock: Contract;

  let m: string;
  let i: string;
  let c: string[];
  let r: string[];
  let pk: string[];

  before(async () => {
    m = "0x736f6d65636f757273656e616d65";
    i = "0x8d398dceaecdf2c8417c6367b32c7b10db03c861359206e5c94458c21ad2c94d";
    c = [
      "0x8ed015fd11e1a9a39e9846fc928d6dae0d1a5db77119dd3d799b7dc93e2b9200",
      "0x9de462503f24ae5878e58128bf90c98f6b274498873f084370c2cc323be9975a",
      "0x3932fbbbed7f4b6ba55f7de70e604f3aed5cb7a91312afb5ce26c2f2b5a23404",
      "0xff9fbb4d6360f9f95ec08aeda0ff1b8b6decc0202161ebeb9827fc798e52af06",
      "0x9c4504d65aaea495da384e9cab5988b742154acb9538cb9b8ff7fd8db3053783",
    ];
    r = [
      "0x1cbd066b0e747d7bbf4b8d0e7bacfa2b850e02a0570c1061802122157f6d85fe",
      "0xaf3713fe01b0fe7ab54ff8eb5f3e6a993a53a20073d9a0396d57850beb016899",
      "0xff14017994fecd568afcc9a615d61af25522b465a9735924cf6b4628782b70d5",
      "0xd4d9ee075b233f53f247af1ff634d7cf059cdbb5646fe35400ddeba1751dd767",
      "0x55d4eb55fe3ffe0de7ed207dd4bcdcb04034d4fcf7afe607bb07b52a252ca415",
    ];
    pk = [
      "0x042fa192fc93d2d20d6f24803465dd3f22e70d7a8a6917c134053c9dca05e7b2f9417575d42103afd5989a425f553706e277b709c2d736f864058b3a1a8c07ef18",
      "0x0421bf7f73e2e4e19a7b5a6b0e3521c72a4cc2b1a4b8c71484b5038ba5b8dad0d5f2aa3386c6f5cc99a5927f56ed423093600b8851bfa2700571df255be6c011e9",
      "0x048b74f602ea173a86b4ed7ee69333633fc9c52104721d2ecc85ce90addbef3e4bd4a26be13c569c872b6ffc0f5fbc9a220f64538b298f8c7c070baefa4386362e",
      "0x04f521fc7ea86b81a8b8eb4a635c7970ad4d9775a18d793c35c472ace32580e63e62643ed2cc87f9ab1ea934099d5c99bbf4719aab21d22cf5d528ce94b36bf4ee",
      "0x04a62b36cfcfdd7dde217542adcb7f353ac2276802d9d1ff5d346b6ac9616275adad1badd4e1f29b05927fc40db1de2ee4efdffe824e3d5768a475dfe557a4ea29",
    ];

    const ringSignatureMockContract = await ethers.getContractFactory("RingSignatureMock");

    ringSignatureMock = await ringSignatureMockContract.deploy();

    await reverter.snapshot();
  });

  afterEach("revert", reverter.revert);

  describe("#verify", () => {
    it("should verify", async () => {
      let utf8Encode = new TextEncoder();

      expect(await ringSignatureMock.verifyRingSignature(utf8Encode.encode(m), i, c, r, pk)).to.equal(true);
    });

    it("should verify", async () => {
      let utf8Encode = new TextEncoder();

      let C = [
        "0x7c183f837526cd0ed7428978d5fa7374d6d8d964f11f0e95a79f723d18e69e3a",
        "0xe71691ea7c3fbdd30e0c394ae77e447d72bf75f7352e8a69e274f6063a4f00d6",
        "0x481ccee6225a0af431fce263bebbf00d72923000b736ceff4bb252c0f0d4e52d",
        "0x440c60bec5390a6402e94166a2ca758616d5c55a8a78ecd926e75de282e24ac1",
        "0xccddef13de621f6d5bc845e0134849632f87e5d11bb2eea75c23f0aa6f7a1bbf",
      ];
      let I = "0x8d398dceaecdf2c8417c6367b32c7b10db03c861359206e5c94458c21ad2c94d";
      let R = [
        "0xc530cd40ca5a77b86bc1debcad7ee6db82d54e3c6af368cbf45eb74a6f40f979",
        "0x37f270caf7eefad1b5406d36e05f7ee4be32ca94ca0e3ad2b6ebb141bd7b83f9",
        "0x0c950b1a8c3a53cd4bbb5b80d1549b8e49cc602a1ff7df049ea39d5e073ecda5",
        "0x517f4819b11796c5c485d7d0992083375cfc8cdd968e624625c06d02bede50de",
        "0xa7af05c164a9d61d787d4c4bb96821524e122242a4f74bacf2da56a458a4492c",
      ];
      expect(await ringSignatureMock.verifyRingSignature(utf8Encode.encode(m), I, C, R, pk)).to.equal(true);
    });
  });
});
