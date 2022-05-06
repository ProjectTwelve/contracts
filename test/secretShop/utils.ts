import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';

class Salt {
  value: BigNumber;
  constructor() {
    this.value = ethers.BigNumber.from(ethers.utils.randomBytes(32));
  }
}

export { Salt };
