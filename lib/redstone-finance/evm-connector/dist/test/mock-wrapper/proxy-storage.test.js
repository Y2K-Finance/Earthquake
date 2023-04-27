"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const hardhat_1 = require("hardhat");
const chai_1 = require("chai");
const src_1 = require("../../src");
const utils_1 = require("redstone-protocol/src/common/utils");
const tests_common_1 = require("../tests-common");
const test_utils_1 = require("../../src/helpers/test-utils");
const dataPoints = [
    { dataFeedId: "ETH", value: 4000 },
    { dataFeedId: "AVAX", value: 5 },
    { dataFeedId: "BTC", value: 100000 },
    { dataFeedId: "LINK", value: 2 },
    { dataFeedId: "UNI", value: 200 },
    { dataFeedId: "FRAX", value: 1 },
    { dataFeedId: "OMG", value: 0.00003 },
    { dataFeedId: "DOGE", value: 2 },
    { dataFeedId: "SOL", value: 11 },
    { dataFeedId: "BNB", value: 31 },
];
const dataFeedIdsBytes = dataPoints.map((dataPoint) => {
    return (0, utils_1.convertStringToBytes32)(dataPoint.dataFeedId);
});
const prepareMockPackagesForManyAssets = () => {
    const mockNumericPackages = (0, test_utils_1.getRange)({
        start: 0,
        length: tests_common_1.NUMBER_OF_MOCK_NUMERIC_SIGNERS,
    }).map((i) => (0, test_utils_1.getMockNumericPackage)({
        dataPoints,
        mockSignerIndex: i,
    }));
    return mockNumericPackages;
};
describe("SampleStorageProxy", function () {
    let contract;
    let consumerContract;
    const ethDataFeedId = (0, utils_1.convertStringToBytes32)("ETH");
    this.beforeEach(async () => {
        const SampleStorageFactory = await hardhat_1.ethers.getContractFactory("SampleStorageProxy");
        contract = await SampleStorageFactory.deploy();
        await contract.deployed();
        const SampleStorageProxyConsumer = await hardhat_1.ethers.getContractFactory("SampleStorageProxyConsumer");
        consumerContract = await SampleStorageProxyConsumer.deploy(contract.address);
        await consumerContract.deployed();
        await contract.register(consumerContract.address);
    });
    it("Should return correct oracle value for one asset using dry run", async () => {
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        const fetchedValue = await wrappedContract.fetchValueUsingProxyDryRun(ethDataFeedId);
        (0, chai_1.expect)(fetchedValue).to.eq(tests_common_1.expectedNumericValues.ETH);
    });
    it("Should return correct structure containing oracle value using dry run", async () => {
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        const fetchedValue = await wrappedContract.fetchStructUsingProxyDryRun(ethDataFeedId);
        const expectedValue = [
            "sample",
            hardhat_1.ethers.BigNumber.from(tests_common_1.expectedNumericValues.ETH),
        ];
        (0, chai_1.expect)(fetchedValue).to.deep.equal(expectedValue);
    });
    it("Should return correct oracle values for array of values using dry run", async () => {
        const mockNumericPackages = prepareMockPackagesForManyAssets();
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockNumericPackages);
        const dataValues = dataPoints.map((dataPoint) => hardhat_1.ethers.BigNumber.from(dataPoint.value * 10 ** 8));
        const fetchedValues = await wrappedContract.fetchValuesUsingProxyDryRun(dataFeedIdsBytes);
        (0, chai_1.expect)(dataValues).to.deep.eq(fetchedValues);
    });
    it("Should return correct array of structures containing oracle values using dry run", async () => {
        const mockNumericPackages = prepareMockPackagesForManyAssets();
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockNumericPackages);
        const fetchedValues = await wrappedContract.fetchArrayOfStructsUsingProxyDryRun(dataFeedIdsBytes);
        const dataValues = dataPoints.map((dataPoint) => [
            "sample",
            hardhat_1.ethers.BigNumber.from(dataPoint.value * 10 ** 8),
        ]);
        (0, chai_1.expect)(dataValues).to.deep.eq(fetchedValues);
    });
    it("Should return correct structure of arrays containing oracle values using dry run", async () => {
        const mockNumericPackages = prepareMockPackagesForManyAssets();
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockNumericPackages);
        const fetchedValues = await wrappedContract.fetchStructOfArraysUsingProxyDryRun(dataFeedIdsBytes);
        const names = dataPoints.map((dataPoint) => "sample");
        const values = dataPoints.map((dataPoint) => hardhat_1.ethers.BigNumber.from(dataPoint.value * 10 ** 8));
        const dataValuesArray = [names, values];
        (0, chai_1.expect)(dataValuesArray).to.deep.eq(fetchedValues);
    });
    it("Should return correct oracle value for one asset", async () => {
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        await wrappedContract.saveOracleValueInContractStorage(ethDataFeedId);
        const fetchedValue = await consumerContract.getOracleValue(ethDataFeedId);
        (0, chai_1.expect)(fetchedValue).to.eq(tests_common_1.expectedNumericValues.ETH);
    });
    it("Should return correct oracle values for 10 assets", async () => {
        const mockNumericPackages = prepareMockPackagesForManyAssets();
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockNumericPackages);
        for (const dataPoint of dataPoints) {
            await wrappedContract.saveOracleValueInContractStorage((0, utils_1.convertStringToBytes32)(dataPoint.dataFeedId));
            await (0, chai_1.expect)(consumerContract.checkOracleValue((0, utils_1.convertStringToBytes32)(dataPoint.dataFeedId), Math.round(dataPoint.value * 10 ** 8))).not.to.be.reverted;
        }
    });
    it("Should return correct oracle values for 10 assets simultaneously", async () => {
        const mockNumericPackages = prepareMockPackagesForManyAssets();
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockNumericPackages);
        const dataValues = dataPoints.map((dataPoint) => Math.round(dataPoint.value * 10 ** 8));
        await wrappedContract.saveOracleValuesInContractStorage(dataFeedIdsBytes);
        await (0, chai_1.expect)(consumerContract.checkOracleValues(dataFeedIdsBytes, dataValues)).not.to.be.reverted;
    });
});
//# sourceMappingURL=proxy-storage.test.js.map