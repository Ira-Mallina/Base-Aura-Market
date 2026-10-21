const hre = require("hardhat");
async function main() {
  const MarketFactory = await hre.ethers.getContractFactory("AuraMarketHub");
  const market = await MarketFactory.deploy();
  await market.deployed();
  console.log("-> Aura Market Hub active at:", market.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
