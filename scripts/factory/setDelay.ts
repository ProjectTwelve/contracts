import { ethers } from 'hardhat';

async function main() {
  const [admin, user] = await ethers.getSigners();
  console.log('admin: ', admin.address, '\n user: ', user.address);

  const P12FACTORY = await ethers.getContractFactory('P12V0Factory');
  const P12Factory = P12FACTORY.attach('0xF7fd4112CFf5da535BBFa3811D40fE9Aa61FA722');
  await P12Factory.connect(admin).setDelayK(60);
  await P12Factory.connect(admin).setDelayB(60);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
