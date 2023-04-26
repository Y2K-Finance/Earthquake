"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const hardhat_1 = require("hardhat");
const chai_1 = require("chai");
const src_1 = require("../../src");
const utils_1 = require("redstone-protocol/src/common/utils");
const tests_common_1 = require("../tests-common");
const test_utils_1 = require("../../src/helpers/test-utils");
describe("SampleProxyConnector", function () {
    let contract;
    const ethDataFeedId = (0, utils_1.convertStringToBytes32)("ETH");
    const testShouldRevertWith = async (mockPackages, revertMsg) => {
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockPackages);
        await (0, chai_1.expect)(wrappedContract.getOracleValueUsingProxy(ethDataFeedId)).to.be.revertedWith(revertMsg);
    };
    this.beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleProxyConnector");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    it("Should return correct oracle value for one asset", async () => {
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        const fetchedValue = await wrappedContract.getOracleValueUsingProxy(ethDataFeedId);
        (0, chai_1.expect)(fetchedValue).to.eq(tests_common_1.expectedNumericValues.ETH);
    });
    it("Should return correct oracle values for 10 assets", async () => {
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
        const mockNumericPackages = (0, test_utils_1.getRange)({
            start: 0,
            length: tests_common_1.NUMBER_OF_MOCK_NUMERIC_SIGNERS,
        }).map((i) => (0, test_utils_1.getMockNumericPackage)({
            dataPoints,
            mockSignerIndex: i,
        }));
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockNumericPackages);
        for (const dataPoint of dataPoints) {
            await (0, chai_1.expect)(wrappedContract.checkOracleValue((0, utils_1.convertStringToBytes32)(dataPoint.dataFeedId), Math.round(dataPoint.value * 10 ** 8))).not.to.be.reverted;
        }
    });
    it("Should forward msg.value", async () => {
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        await (0, chai_1.expect)(wrappedContract.requireValueForward({
            value: hardhat_1.ethers.utils.parseUnits("2137"),
        })).not.to.be.reverted;
    });
    it("Should work properly with long encoded functions", async () => {
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        await (0, chai_1.expect)(wrappedContract.checkOracleValueLongEncodedFunction(ethDataFeedId, tests_common_1.expectedNumericValues.ETH)).not.to.be.reverted;
        await (0, chai_1.expect)(wrappedContract.checkOracleValueLongEncodedFunction(ethDataFeedId, 9999)).to.be.revertedWith("WrongValue()");
    });
    it("Should fail with correct message (timestamp invalid)", async () => {
        const newMockPackages = [...tests_common_1.mockNumericPackages];
        newMockPackages[1] = (0, test_utils_1.getMockNumericPackage)({
            ...tests_common_1.mockNumericPackageConfigs[1],
            timestampMilliseconds: test_utils_1.DEFAULT_TIMESTAMP_FOR_TESTS - 1,
        });
        await testShouldRevertWith(newMockPackages, `errorArgs=["0x355b8743"], errorName="ProxyCalldataFailedWithCustomError"`);
    });
    it("Should fail with correct message (insufficient number of unique signers)", async () => {
        const newMockPackages = tests_common_1.mockNumericPackages.slice(0, tests_common_1.NUMBER_OF_MOCK_NUMERIC_SIGNERS - 1);
        await testShouldRevertWith(newMockPackages, `errorArgs=["0x2b13aef50000000000000000000000000000000000000000000000000000000000000009000000000000000000000000000000000000000000000000000000000000000a"], errorName="ProxyCalldataFailedWithCustomError"`);
    });
    it("Should fail with correct message (signer is not authorised)", async () => {
        const newMockPackages = [...tests_common_1.mockNumericPackages];
        newMockPackages[1] = (0, test_utils_1.getMockNumericPackage)({
            ...tests_common_1.mockNumericPackageConfigs[1],
            mockSignerIndex: tests_common_1.UNAUTHORISED_SIGNER_INDEX,
        });
        await testShouldRevertWith(newMockPackages, `errorArgs=["0xec459bc00000000000000000000000008626f6940e2eb28930efb4cef49b2d1f2c9c1199"], errorName="ProxyCalldataFailedWithCustomError"`);
    });
    it("Should fail with correct message (no error message)", async () => {
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        await (0, chai_1.expect)(wrappedContract.proxyEmptyError()).to.be.revertedWith(`errorName="ProxyCalldataFailedWithoutErrMsg"`);
    });
    it("Should fail with correct message (string test message)", async () => {
        const wrappedContract = src_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        await (0, chai_1.expect)(wrappedContract.proxyTestStringError()).to.be.revertedWith(`errorArgs=["Test message"], errorName="ProxyCalldataFailedWithStringMessage"`);
    });
});
//# sourceMappingURL=proxy-connector.test.js.map