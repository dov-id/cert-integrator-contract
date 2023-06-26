import { ethers } from "hardhat";

export async function initCertIntegrator(course: string) {
  const certIntegratorContract = await ethers.getContractFactory("CertIntegrator");
  const certIntegrator = await certIntegratorContract.deploy();

  const values = [
    "0x0000000000000000000000000000000000000000000000000000000000000001",
    "0x0000000000000000000000000000000000000000000000000000000000000002",
    "0x2018445dcff761ed409e5595ab55308a99828d7f803240a005d8bbb4d1c69924",
    "0xfff7d65808452f96d578a2c159315b487a4af2eda920ad9b2e572ff47309c714",
  ];

  for (let i = 0; i < values.length; i++) {
    await certIntegrator.updateCourseState([course], [values[i]]);
  }

  return certIntegrator;
}
