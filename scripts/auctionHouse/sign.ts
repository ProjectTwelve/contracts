// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from 'hardhat';
import { utils } from 'ethers';
import { TypedDataEncoder } from '@ethersproject/hash/src.ts/typed-data';

import { recoverTypedSignature, SignTypedDataVersion, signTypedData } from '@metamask/eth-sig-util';
async function main() {
  const domain = {
    name: 'P12 Exchange',
    version: '1.0.0',
    chainId: 44010,
    verifyingContract: '0x2B1525d4BaBC614A4F309b1256650aB7602d780A',
  };
  const msg = {
    salt: '1646991641652',
    user: '0x850Fe27f63de12b601C0203b62d7995462D1D1Bc',
    network: 44010,
    intent: 1,
    delegateType: 1,
    deadline: 1647596430,
    currency: '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0',
    dataMask: '0x0000000000000000000000000000000000000000000000000000000000000000',
    length: 1,
    items: [
      {
        price: '100000000000000000000',
        data: '0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000004944655508a93a6be7fff9e6ef82cfb36630052f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000017f785a0c34',
      },
    ],
  };
  const types = {
    Order: [
      { name: 'salt', type: 'uint256' },
      { name: 'user', type: 'address' },
      { name: 'network', type: 'uint256' },
      { name: 'intent', type: 'uint256' },
      { name: 'delegateType', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
      { name: 'currency', type: 'address' },
      { name: 'dataMask', type: 'bytes' },
      { name: 'length', type: 'uint256' },
      { name: 'items', type: 'OrderItem[]' },
    ],
    OrderItem: [
      { name: 'price', type: 'uint256' },
      { name: 'data', type: 'bytes' },
    ],
  };

  const simpleType = {
    Simple: [{ name: 'k', type: 'uint256' }],
  };

  const simpleMsg = {
    k: 1,
  };

  const user3 = (await ethers.getSigners())[2];
  console.log(user3.address);

  // const ec = TypedDataEncoder.from(types);

  // console.log(ec.primaryType);

  // const signature = await user3._signTypedData(domain, types, msg);

  // console.log(signature);

  const sSignature = await user3._signTypedData(domain, simpleType, simpleMsg);
  console.log('S1: ', sSignature);

  const signData = {
    types: {
      ...simpleType,
      EIP712Domain: [
        { name: 'name', type: 'string' },
        { name: 'version', type: 'string' },
        { name: 'chainId', type: 'uint256' },
        { name: 'verifyingContract', type: 'address' },
      ],
    },
    domain,
    primaryType: 'Simple',
    message: simpleMsg,
  };

  const S2 = signTypedData<SignTypedDataVersion.V4, any>({
    data: signData,
    privateKey: Buffer.from('12f360fc01c5f9c4ede5eb96c4c0f1859a881d1428135d8c3b6ead19894214e0', 'hex'),
    version: SignTypedDataVersion.V4,
  });

  console.log('s2: ', S2);

  // const recovered = recoverTypedSignature<SignTypedDataVersion.V4, any>({
  //   data: signData,
  //   signature: sSignature,
  //   version: SignTypedDataVersion.V4,
  // });

  // console.log("recover: ", recovered);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
