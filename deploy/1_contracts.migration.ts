import { poseidonContract } from "circomlibjs";
import { Deployer, Logger } from "@dlsl/hardhat-migrate";
import { artifacts } from "hardhat";
import { ethers } from "hardhat";

const CertIntegrator = artifacts.require("CertIntegrator");
const FeedbackRegistry = artifacts.require("FeedbackRegistry");
const Verifier = artifacts.require("Verifier");

const PoseidonUnit2L = artifacts.require("PoseidonUnit2L");
const PoseidonUnit3L = artifacts.require("PoseidonUnit3L");

require("dotenv").config();

async function getPoseidons() {
  const [deployer] = await ethers.getSigners();
  const PoseidonHasher2 = new ethers.ContractFactory(
    poseidonContract.generateABI(2),
    poseidonContract.createCode(2),
    deployer
  );
  console.log("Deploying Poseidon 2 hashing...");
  const poseidonHasher2 = await PoseidonHasher2.deploy();
  await poseidonHasher2.deployed();
  console.log("Poseidon 2 hashing address: ", poseidonHasher2.address);

  const PoseidonHasher3 = new ethers.ContractFactory(
    poseidonContract.generateABI(3),
    poseidonContract.createCode(3),
    deployer
  );
  console.log("Deploying Poseidon 3 hashing...");
  const poseidonHasher3 = await PoseidonHasher3.deploy();
  await poseidonHasher3.deployed();
  console.log("Poseidon 3 hashing address: ", poseidonHasher3.address);

  return { poseidonHasher2, poseidonHasher3 };
}

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
