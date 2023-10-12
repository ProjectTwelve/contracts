import { randomBytes, computeAddress } from 'ethers/lib/utils';
export function randomAddress() {
  return computeAddress(randomBytes(32));
}
