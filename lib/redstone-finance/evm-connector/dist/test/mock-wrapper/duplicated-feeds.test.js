"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const redstone_protocol_1 = require("redstone-protocol");
const test_utils_1 = require("../../src/helpers/test-utils");
const index_1 = require("../../src/index");
const tests_common_1 = require("../tests-common");
describe("DuplicatedDataFeeds", function () {
    let contract;
    this.beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleDuplicatedDataFeeds");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    const runTestForArrayOfDataFeeds = async (dataFeedIds) => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        const tx = await wrappedContract.saveOracleValuesInStorage(dataFeedIds.map(redstone_protocol_1.utils.convertStringToBytes32));
        await tx.wait();
        const values = await contract.getValuesFromStorage();
        for (let symbolIndex = 0; symbolIndex < dataFeedIds.length; symbolIndex++) {
            const symbol = dataFeedIds[symbolIndex];
            (0, chai_1.expect)(values[symbolIndex].toNumber()).to.eql(tests_common_1.expectedNumericValues[symbol]);
        }
    };
    it("Should get oracle values for empty array", async () => {
        await runTestForArrayOfDataFeeds([]);
    });
    it("Should get oracle values for an array with one symbol", async () => {
        await runTestForArrayOfDataFeeds(["ETH"]);
    });
    it("Should get oracle values for feeds with duplicates", async () => {
        await runTestForArrayOfDataFeeds([
            "ETH",
            "BTC",
            "ETH",
            "ETH",
            "BTC",
            "ETH",
            "BTC",
        ]);
    });
    it("Should get oracle values for feeds with duplicates (100 times BTC)", async () => {
        const dataFeedIds = (0, test_utils_1.getRange)({ start: 0, length: 100 }).map(() => "BTC");
        await runTestForArrayOfDataFeeds(dataFeedIds);
    });
    it("Should get oracle values for feeds with duplicates (1000 times ETH)", async () => {
        const dataFeedIds = (0, test_utils_1.getRange)({ start: 0, length: 1000 }).map(() => "ETH");
        await runTestForArrayOfDataFeeds(dataFeedIds);
    });
    it("Should get oracle values for feeds with duplicates (1 x ETH, 100 x BTC)", async () => {
        const dataFeedIds = (0, test_utils_1.getRange)({ start: 0, length: 100 }).map(() => "BTC");
        await runTestForArrayOfDataFeeds(["ETH", ...dataFeedIds]);
    });
    it("Should get oracle values for feeds with duplicates (100 x BTC, 1 x ETH)", async () => {
        const dataFeedIds = (0, test_utils_1.getRange)({ start: 0, length: 100 }).map(() => "BTC");
        await runTestForArrayOfDataFeeds([...dataFeedIds, "ETH"]);
    });
    it("Should get oracle values for feeds with duplicates (100 x ETH, 1 x BTC)", async () => {
        const dataFeedIds = (0, test_utils_1.getRange)({ start: 0, length: 100 }).map(() => "ETH");
        await runTestForArrayOfDataFeeds([...dataFeedIds, "BTC"]);
    });
    it("Should get oracle values for feeds with duplicates (100 x ETH, 100 x BTC)", async () => {
        const dataFeedIdsETH = (0, test_utils_1.getRange)({ start: 0, length: 100 }).map(() => "ETH");
        const dataFeedIdsBTC = (0, test_utils_1.getRange)({ start: 0, length: 100 }).map(() => "BTC");
        await runTestForArrayOfDataFeeds([...dataFeedIdsETH, ...dataFeedIdsBTC]);
    });
});
//# sourceMappingURL=duplicated-feeds.test.js.map