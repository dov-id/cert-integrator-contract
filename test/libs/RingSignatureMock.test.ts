import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";

import { Reverter } from "../helpers/reverter";

describe("RingSignatureMock", async () => {
  const reverter = new Reverter();

  let ringSignatureMock: Contract;

  let m: string;
  let i: BigInt;
  let c: BigInt[];
  let r: BigInt[];
  let pkX: BigInt[];
  let pkY: BigInt[];

  before(async () => {
    m = "QmcafQDfq4LGzQ6CimzLVBt7rqEAFSwE4ya8uZt9zUSZJr";

    i = BigInt("50471588177842483870949591504891431469788067843245220753429247714802432717931");
    c = [
      BigInt("70041801939983713545541323538650867611888908572372755867640542626006700327007"),
      BigInt("11383195236235059450968274357691085014684782031145982541396720988477490355059"),
      BigInt("51457338063847717974933298524926316666611040906549651277498439048797732727515"),
      BigInt("83520285365944823477249362188943334196252479687517416825605418842699868933856"),
      BigInt("4440865536153965334656762989295988603297907172732379424317783759012410342008"),
    ];

    r = [
      BigInt("34681769164153180207730108951907248945808824653538588288572152602466724238167"),
      BigInt("38421218312886342217363291339022477464498983787463718180231007937762144399467"),
      BigInt("55694777476098176687069655949015141665418945773107005677892088091197214072682"),
      BigInt("77005503372202429945955839956465406013552055414574695047693968274216394517182"),
      BigInt("2895594570500927798135432795361534101459713373207995170134619553792849695557"),
    ];
    pkX = [
      BigInt("21544180725283665080737435029403945626738292305451098752032497668875188941561"),
      BigInt("15264671438695105554814157736171101693808132776909943100114660041813940424917"),
      BigInt("63078138120762156328738222228180148525554661293694095968990272456102849232459"),
      BigInt("110876696510807313718716669564696607303253365879927370640173820875503868896830"),
      BigInt("75160285585510138550546692233670343500621109774094027756314740373042193659309"),
    ];

    pkY = [
      BigInt("29607869487799476451128679839843791240101423214162884824978515269761488121624"),
      BigInt("109760428980812280723640160076609939028183677671160852284735976210464342282729"),
      BigInt("96177297683348046674660984212655186653942447147719072583799479170909174380078"),
      BigInt("44503777459039890091037753626975999547975490216181475985249318303451719660782"),
      BigInt("78299027417075857530472507339741312673696906924523594633968044219747971426857"),
    ];

    const ringSignatureMockContract = await ethers.getContractFactory("RingSignatureMock");

    ringSignatureMock = await ringSignatureMockContract.deploy();

    await reverter.snapshot();
  });

  afterEach("revert", reverter.revert);

  describe("#verify", () => {
    it("should verify", async () => {
      let utf8Encode = new TextEncoder();

      expect(await ringSignatureMock.verifyRingSignature(utf8Encode.encode(m), i, c, r, pkX, pkY)).to.equal(true);
    });

    it("should verify", async () => {
      let utf8Encode = new TextEncoder();

      let C = [
        BigInt("100461471471512544497211957917221003689153100940756530367170159370863859007756"),
        BigInt("79368820139618030919575795751112725374303676686128446556498338979104344752865"),
        BigInt("57126813262815529166904955791568139417833933287637172610326769506888740080505"),
        BigInt("25149844065458570272451914526172889470485737836824351077878503086660653556851"),
        BigInt("17376944065732060858095810883146726585543533420396431485232445007446995552631"),
      ];
      let I = BigInt("50471588177842483870949591504891431469788067843245220753429247714802432717931");
      let R = [
        BigInt("76233534939808424846161488980995081465914568424389768313577512021139872086009"),
        BigInt("102157684690988693235767998083144813358146932586772473041254799896926231720425"),
        BigInt("2891146402159395176144300920894964684001647985764833589089788627056911751368"),
        BigInt("37624853023407604488749256732448509790953410836956323985631952938829113678596"),
        BigInt("73308061163997033054825843155030822366039145214998240845161711045829894656505"),
      ];

      expect(await ringSignatureMock.verifyRingSignature(utf8Encode.encode(m), I, C, R, pkX, pkY)).to.equal(true);
    });

    it("should not verify", async () => {
      let utf8Encode = new TextEncoder();

      let C = [
        BigInt("100461471471512544497211957917221003689153100940756530367170159370863859007752"),
        BigInt("79368820139618030919575795751112725374303676686128446556498338979104344752863"),
        BigInt("57126813262815529166904955791568139417833933287637172610326769506888730080505"),
        BigInt("25149844065458570272451914526172889470485737836824351077878503086660653556851"),
        BigInt("17376944065732060858095810883146726585543533420396431485232445007446995552631"),
      ];

      expect(await ringSignatureMock.verifyRingSignature(utf8Encode.encode(m), i, C, r, pkX, pkY)).to.equal(false);
    });
  });
});