import { poseidonContract } from "circomlibjs";
import { ethers } from "hardhat";
import { Contract } from "ethers";

export async function getPoseidons(): Promise<{ poseidonHasher2: Contract; poseidonHasher3: Contract }> {
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
