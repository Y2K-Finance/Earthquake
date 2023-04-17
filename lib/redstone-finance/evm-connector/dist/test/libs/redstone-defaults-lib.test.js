"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const hardhat_1 = require("hardhat");
const chai_1 = require("chai");
const ethers_1 = require("ethers");
const tests_common_1 = require("../tests-common");
const MILLISECONDS_IN_MINUTE = 60 * 1000;
describe("SampleRedstoneDefaultsLib", function () {
    let contract;
    beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleRedstoneDefaultsLib");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    it("Should properly validate valid timestamps", async () => {
        const timestamp = await (0, tests_common_1.getBlockTimestampMilliseconds)();
        await contract.validateTimestamp(timestamp);
        await contract.validateTimestamp(timestamp + 0.5 * MILLISECONDS_IN_MINUTE);
        await contract.validateTimestamp(timestamp - 2.5 * MILLISECONDS_IN_MINUTE);
    });
    it("Should revert for too old timestamp", async () => {
        const timestamp = await (0, tests_common_1.getBlockTimestampMilliseconds)();
        await (0, chai_1.expect)(contract.validateTimestamp(timestamp - 4 * MILLISECONDS_IN_MINUTE)).to.be.revertedWith("TimestampIsTooOld");
    });
    it("Should revert for timestamp from too long future", async () => {
        const timestamp = await (0, tests_common_1.getBlockTimestampMilliseconds)();
        await (0, chai_1.expect)(contract.validateTimestamp(timestamp + 2 * MILLISECONDS_IN_MINUTE)).to.be.revertedWith("TimestampFromTooLongFuture");
    });
    it("Should properly aggregate an array with 1 value", async () => {
        const aggregatedValue = await contract.aggregateValues([42]);
        (0, chai_1.expect)(aggregatedValue.toNumber()).to.eql(42);
    });
    it("Should properly aggregate an array with 3 values", async () => {
        const aggregatedValue = await contract.aggregateValues([41, 43, 42]);
        (0, chai_1.expect)(aggregatedValue.toNumber()).to.eql(42);
    });
    it("Should properly aggregate an array with 4 values", async () => {
        const aggregatedValue = await contract.aggregateValues([38, 44, 40, 100]);
        (0, chai_1.expect)(aggregatedValue.toNumber()).to.eql(42);
    });
    it("Should properly aggregate an array with values, which include a very big number", async () => {
        const aggregatedValue = await contract.aggregateValues([
            44,
            ethers_1.BigNumber.from("1000000000000000000000000000000000000"),
            40,
            10,
        ]);
        (0, chai_1.expect)(aggregatedValue.toNumber()).to.eql(42);
    });
    it("Should properly aggregate an array with values, which include zeros", async () => {
        const aggregatedValue = await contract.aggregateValues([
            44, 0, 68, 0, 100, 0, 42,
        ]);
        (0, chai_1.expect)(aggregatedValue.toNumber()).to.eql(42);
    });
    it("Should revert trying to aggregate an empty array", async () => {
        await (0, chai_1.expect)(contract.aggregateValues([])).to.be.revertedWith("CanNotPickMedianOfEmptyArray");
    });
});
//# sourceMappingURL=redstone-defaults-lib.test.js.map