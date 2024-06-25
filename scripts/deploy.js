/* global ethers */
/* eslint prefer-const: "off" */

async function deployStarknet() {
  const gasPrice = (await ethers.provider.getFeeData()).gasPrice;
  console.log('gasPrice:', gasPrice);
  const accounts = await ethers.getSigners();
  console.log('accounts:', accounts);
  const contractOwner = accounts[0];
  const deployGasParams = {
    gasLimit: 4200000,
    maxFeePerGas: (gasPrice * 12n) / 10n,
  };

  // deploy Starknet
  const Starknet = await ethers.getContractFactory('Starknet');
  const starknet = await Starknet.deploy(deployGasParams);
  console.log('Deploy Starknet Transaction hash:', starknet.deploymentTransaction().hash);
  await starknet.waitForDeployment();
  console.log('Starknet deployed:', starknet.target);

  // deploy Proxy
  const Proxy = await ethers.getContractFactory('Proxy');
  const proxy = await Proxy.deploy(1000, deployGasParams);
  console.log('Deploy Proxy Transaction hash:', proxy.deploymentTransaction().hash);
  await proxy.waitForDeployment();
  console.log('Proxy deployed:', proxy.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployStarknet()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

exports.deployStarknet = deployStarknet;
