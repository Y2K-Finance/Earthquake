"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const hardhat_1 = require("hardhat");
const chai_1 = require("chai");
const test_utils_1 = require("../../src/helpers/test-utils");
const src_1 = require("../../src");
describe("Long Inputs", function () {
    let contract;
    const prepareMockBytesPackages = (hexValue) => {
        return (0, test_utils_1.getRange)({
            start: 0,
            length: 3,
        }).map((mockSignerIndex) => (0, test_utils_1.getMockPackageWithOneBytesDataPoint)({
            mockSignerIndex,
            hexValue,
        }));
    };
    this.beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleRedstoneConsumerBytesMockStrings");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    it("Should pass long bytes oracle value", async () => {
        const hexValue = "0x" + "f".repeat(30000);
        const mockPackages = prepareMockBytesPackages(hexValue);
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockPackages);
        await wrappedContract.saveLatestValueInStorage(test_utils_1.DEFAULT_DATA_FEED_ID_BYTES_32);
        (0, chai_1.expect)(await contract.latestString()).to.be.equal(hexValue);
    });
});
//# sourceMappingURL=long-inputs.test.js.map