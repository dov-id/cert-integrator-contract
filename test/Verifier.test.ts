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
  let tokenContract: Contract;

  let USER1: SignerWithAddress;

  let KEYS: string[];
  let VALUES: string[];
  let PROOFS: string[][];

  let I: BigInt;
  let C: BigInt[];
  let R: BigInt[];
  let PUBLIC_KEYS_X: BigInt[];
  let PUBLIC_KEYS_Y: BigInt[];

  let URI: string;

  let CONTRACT: string;

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

  async function getVerifierMock(): Promise<Contract> {
    const verifierMockContract = await ethers.getContractFactory("VerifierMock");

    return verifierMockContract.deploy();
  }

  async function getVerifier(certIntegratorAddr: string): Promise<Contract> {
    let { poseidonHasher2, poseidonHasher3 } = await getPoseidons();

    const verifierContract = await ethers.getContractFactory("Verifier", {
      libraries: {
        PoseidonUnit2L: poseidonHasher2.address,
        PoseidonUnit3L: poseidonHasher3.address,
      },
    });

    return verifierContract.deploy(certIntegratorAddr);
  }

  before(async () => {
    [USER1] = await ethers.getSigners();

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
      BigInt("107397809107310196060030710954320924779702083870846401520435738242590846961198"),
      BigInt("97831644264874414005381060528331222319659330406926406437591143806471802027924"),
      BigInt("20467046445153493284165647059883598994244068321873200641084298303191958101409"),
      BigInt("5423273685162435787159281512267272761575409356635347084792650981353350099915"),
      BigInt("17169925619562534369445307191870144872459259493982093727162599238055049084325"),
    ];
    I = BigInt("50471588177842483870949591504891431469788067843245220753429247714802432717931");
    R = [
      BigInt("48204451163790042899589753776456703447658349270202514267252561455464781830954"),
      BigInt("10554703633299477981625830347475993441068039523563775678799750101892919294925"),
      BigInt("54502740070791029632282223507386307904007786350289005444482353317083761893011"),
      BigInt("61608107954025615266483461687839313284702984012129592691449727911982490720507"),
      BigInt("51689077108441190317954595723020362765501528266249724670980436404170927952640"),
    ];

    PUBLIC_KEYS_X = [
      BigInt("21544180725283665080737435029403945626738292305451098752032497668875188941561"),
      BigInt("15264671438695105554814157736171101693808132776909943100114660041813940424917"),
      BigInt("63078138120762156328738222228180148525554661293694095968990272456102849232459"),
      BigInt("110876696510807313718716669564696607303253365879927370640173820875503868896830"),
      BigInt("75160285585510138550546692233670343500621109774094027756314740373042193659309"),
    ];

    PUBLIC_KEYS_Y = [
      BigInt("29607869487799476451128679839843791240101423214162884824978515269761488121624"),
      BigInt("109760428980812280723640160076609939028183677671160852284735976210464342282729"),
      BigInt("96177297683348046674660984212655186653942447147719072583799479170909174380078"),
      BigInt("44503777459039890091037753626975999547975490216181475985249318303451719660782"),
      BigInt("78299027417075857530472507339741312673696906924523594633968044219747971426857"),
    ];

    URI = "ipfs/uri";

    const tokenFactory = await getTokenFactory();

    tokenContract = await getTokenContract(tokenFactory, 1, "TokenName", "TN");
    CONTRACT = tokenContract.address;

    certIntegrator = await initCertIntegrator(CONTRACT, [
      "0x0000000000000000000000000000000000000000000000000000000000000001",
      "0x0000000000000000000000000000000000000000000000000000000000000002",
      "0x2018445dcff761ed409e5595ab55308a99828d7f803240a005d8bbb4d1c69924",
      "0xfff7d65808452f96d578a2c159315b487a4af2eda920ad9b2e572ff47309c714",
      "0x1236c7c84fbced418368c03b6d3ed20d40d10a24e2f140dab56a8bbf82aea80d",
    ]);

    verifier = await getVerifier(certIntegrator.address);

    await tokenContract.connect(USER1).setNewAdmin(verifier.address);

    await reverter.snapshot();
  });

  afterEach("revert", reverter.revert);

  describe("#verifyContract", () => {
    it("should mint token", async () => {
      let transaction = await verifier.verifyContract(
        CONTRACT,
        I,
        C,
        R,
        PUBLIC_KEYS_X,
        PUBLIC_KEYS_Y,
        PROOFS,
        KEYS,
        VALUES,
        URI
      );
      const tx = await transaction.wait();

      expect(parseInt(tx.events[0].topics[3], 16)).to.equal(0);
    });

    it("should revert merkle tree verification", async () => {
      let proof = [
        [
          "0x0000000000000000000000000000000000000000000000000000000000000000",
          "0x9f341c74c45f6f3a785981307c1d07a060b936fe5f4d022c0f9b64546f590818",
        ],
      ];

      await expect(
        verifier.verifyContract(CONTRACT, I, C, R, PUBLIC_KEYS_X, PUBLIC_KEYS_Y, proof, KEYS, VALUES, URI)
      ).to.be.revertedWith("Verifier: wrong merkle tree verification");
    });

    it("should revert wrong signature", async () => {
      let c = [
        BigInt("70041801939983713545541323538650867611888908572372755867640542626006700327005"),
        BigInt("11383195236235059450968274357691085014684782031145982541396720988477490355059"),
        BigInt("51457338063847717974933298524926316666611040906549651277498439048797732727515"),
        BigInt("83520285365944823477249362188943334196252479687517416825605418842699868933856"),
        BigInt("4440865536153965334656762989295988603297907172732379424317783759012410342008"),
      ];

      await expect(
        verifier.verifyContract(CONTRACT, I, c, R, PUBLIC_KEYS_X, PUBLIC_KEYS_Y, PROOFS, KEYS, VALUES, URI)
      ).to.be.revertedWith("Verifier: wrong signature");
    });

    it("should revert getting last data", async () => {
      const verifierMock = await getVerifierMock();

      let newVerifier = await getVerifier(verifierMock.address);

      await expect(
        newVerifier
          .connect(USER1)
          .verifyContract(CONTRACT, I, C, R, PUBLIC_KEYS_X, PUBLIC_KEYS_Y, PROOFS, KEYS, VALUES, URI)
      ).to.be.revertedWith("Verifier: failed to get last data");
    });

    it("should revert ", async () => {
      const verifierMock = await getVerifierMock();

      await certIntegrator.updateCourseState(
        [verifierMock.address],
        ["0x1236c7c84fbced418368c03b6d3ed20d40d10a24e2f140dab56a8bbf82aea80d"]
      );

      await expect(
        verifier
          .connect(USER1)
          .verifyContract(verifierMock.address, I, C, R, PUBLIC_KEYS_X, PUBLIC_KEYS_Y, PROOFS, KEYS, VALUES, URI)
      ).to.be.revertedWith("Verifier: failed to mint token");
    });
  });
});
