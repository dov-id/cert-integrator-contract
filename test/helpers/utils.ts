import { ethers } from "hardhat";

export async function initCertIntegrator(course: string, values: string[]) {
  const certIntegratorContract = await ethers.getContractFactory("CertIntegrator");
  const certIntegrator = await certIntegratorContract.deploy();

  for (let i = 0; i < values.length; i++) {
    await certIntegrator.updateCourseState([course], [values[i]]);
  }

  return certIntegrator;
}
