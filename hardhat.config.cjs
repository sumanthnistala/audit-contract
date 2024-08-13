/** @type import('hardhat/config').HardhatUserConfig */
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-waffle");

module.exports = {
  solidity: "0.8.24",
  gasReporter: {
    enabled: true
  }
};
