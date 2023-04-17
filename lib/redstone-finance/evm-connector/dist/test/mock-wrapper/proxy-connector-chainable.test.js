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
describe("SampleChainableProxyConnector", function () {
    let contract;
    let consumerContract;
    const ethDataFeedId = (0, utils_1.convertStringToBytes32)("ETH");
    this.beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleChainableProxyConnector");
        contract = await ContractFactory.deploy();
        await contract.deployed();
        const contractB = await ContractFactory.deploy();
        await contractB.deployed();
        await contract.registerNextConnector(contractB.address);
        const ConsumerContractFactory = await hardhat_1.ethers.getContractFactory("SampleProxyConnectorConsumer");
        consumerContract = await ConsumerContractFactory.deploy();
        await consumerContract.deployed();
        await contractB.registerConsumer(consumerContract.address);
    });
    it("Should process oracle value for one asset", async () => {
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        await wrappedContract.processOracleValue(ethDataFeedId);
        const fetchedValue = await consumerContract.getComputationResult();
        (0, chai_1.expect)(fetchedValue).to.eq(tests_common_1.expectedNumericValues.ETH * 42);
    });
    it("Should process oracle values for 10 assets", async () => {
        const mockNumericPackages = (0, test_utils_1.getRange)({
            start: 0,
            length: tests_common_1.NUMBER_OF_MOCK_NUMERIC_SIGNERS,
        }).map((i) => (0, test_utils_1.getMockNumericPackage)({
            dataPoints,
            mockSignerIndex: i,
        }));
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockNumericPackages);
        const dataValues = dataPoints.map((dataPoint) => Math.round(dataPoint.value * 10 ** 8));
        for (const dataPoint of dataPoints) {
            await wrappedContract.processOracleValue((0, utils_1.convertStringToBytes32)(dataPoint.dataFeedId));
        }
        const computationResult = await consumerContract.getComputationResult();
        (0, chai_1.expect)(computationResult).to.eq(dataValues.reduce((a, b) => a + b, 0) * 42);
    });
    it("Should process oracle values for 10 assets simultaneously", async () => {
        const mockNumericPackages = (0, test_utils_1.getRange)({
            start: 0,
            length: tests_common_1.NUMBER_OF_MOCK_NUMERIC_SIGNERS,
        }).map((i) => (0, test_utils_1.getMockNumericPackage)({
            dataPoints,
            mockSignerIndex: i,
        }));
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockNumericPackages);
        const dataFeedIds = dataPoints.map((dataPoint) => dataPoint.dataFeedId);
        const dataFeedIdsBytes = dataFeedIds.map(utils_1.convertStringToBytes32);
        const dataValues = dataPoints.map((dataPoint) => Math.round(dataPoint.value * 10 ** 8));
        await wrappedContract.processOracleValues(dataFeedIdsBytes);
        const computationResult = await consumerContract.getComputationResult();
        (0, chai_1.expect)(computationResult).to.eq(dataValues.reduce((a, b) => a + b, 0) * 42);
    });
});
//# sourceMappingURL=proxy-connector-chainable.test.js.map