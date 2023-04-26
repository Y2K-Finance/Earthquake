"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@typechain/hardhat");
require("hardhat-gas-reporter");
// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
const config = {
    solidity: {
        version: "0.8.4",
        settings: {
            optimizer: {
                enabled: true,
                runs: 10000, // it slightly increases gas for contract deployment but decreases for user interactions
            },
        },
    },
    gasReporter: {
        enabled: true,
        currency: "USD",
    },
    mocha: {
        timeout: 300000, // 300 seconds
    },
    networks: {
        hardhat: {
            blockGasLimit: 30000000,
        },
    },
};
exports.default = config;
//# sourceMappingURL=hardhat.config.js.map