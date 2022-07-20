import env, { ethers } from 'hardhat';

async function main() {
  if (env.network.name === 'p12TestNet') {
    const p12Token = '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0';
    const VotingEscrow = await ethers.getContractFactory('VotingEscrow');
    const votingEscrow = await VotingEscrow.deploy(p12Token, 'Vote-escrowed P12', 'veP12');
    console.log('VotingEscrow contract', votingEscrow.address);
    // 0xd583619d365E150E81804DC9aa2276F1b2d44D11
  } else if (env.network.name === 'rinkeby') {
    const p12Token = '0x2844B158Bcffc0aD7d881a982D464c0ce38d8086';
    const VotingEscrow = await ethers.getContractFactory('VotingEscrow');
    const votingEscrow = await VotingEscrow.deploy(p12Token, 'Vote-escrowed P12', 'veP12');
    console.log('VotingEscrow contract', votingEscrow.address);
    // 0x427fbf5ae3b2684D6136a63D14BC7ABf963f6E7c
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
