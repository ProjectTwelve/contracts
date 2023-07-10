import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';

export function genSalt(): BigNumber {
  return ethers.BigNumber.from(ethers.utils.randomBytes(32));
}
