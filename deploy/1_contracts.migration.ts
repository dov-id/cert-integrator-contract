import { Deployer, Logger } from "@dlsl/hardhat-migrate";
import { artifacts } from "hardhat";
import { getPoseidons } from "@/test/helpers/poseidons";

const CertIntegrator = artifacts.require("CertIntegrator");
const FeedbackRegistry = artifacts.require("FeedbackRegistry");
const Verifier = artifacts.require("Verifier");

const PoseidonUnit2L = artifacts.require("PoseidonUnit2L");
const PoseidonUnit3L = artifacts.require("PoseidonUnit3L");

require("dotenv").config();

export = async (deployer: Deployer, logger: Logger) => {
  const { poseidonHasher2, poseidonHasher3 } = await getPoseidons();

  const certIntegrator = await deployer.deploy(CertIntegrator);

  const poseidonUnit2L = await PoseidonUnit2L.at(poseidonHasher2.address);
  const poseidonUnit3L = await PoseidonUnit3L.at(poseidonHasher3.address);

  await deployer.link(poseidonUnit2L, FeedbackRegistry);
  await deployer.link(poseidonUnit3L, FeedbackRegistry);

  const feedbackRegistry = await deployer.deploy(FeedbackRegistry, certIntegrator.address);

  await deployer.link(poseidonUnit2L, Verifier);
  await deployer.link(poseidonUnit3L, Verifier);

  const verifier = await deployer.deploy(Verifier, certIntegrator.address);

  logger.logContracts(
    ["CertIntegrator", certIntegrator.address],
    ["FeedbackRegistry", feedbackRegistry.address],
    ["Verifier", verifier.address]
  );
};
