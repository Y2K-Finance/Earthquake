"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const redstone_protocol_1 = require("redstone-protocol");
const test_utils_1 = require("../../src/helpers/test-utils");
const index_1 = require("../../src/index");
const tests_common_1 = require("../tests-common");
describe("SampleRedstoneConsumerNumericMockManyDataFeeds", function () {
    let contract;
    const testShouldPass = async (mockNumericPackages, dataFeedIds) => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockNumericPackages);
        const tx = await wrappedContract.save2ValuesInStorage([
            redstone_protocol_1.utils.convertStringToBytes32(dataFeedIds[0]),
            redstone_protocol_1.utils.convertStringToBytes32(dataFeedIds[1]),
        ]);
        await tx.wait();
        const firstValueFromContract = await contract.firstValue();
        const secondValueFromContract = await contract.secondValue();
        (0, chai_1.expect)(firstValueFromContract.toNumber()).to.be.equal(tests_common_1.expectedNumericValues[dataFeedIds[0]]);
        (0, chai_1.expect)(secondValueFromContract.toNumber()).to.be.equal(tests_common_1.expectedNumericValues[dataFeedIds[1]]);
    };
    const testShouldRevertWith = async (mockNumericPackages, dataFeedIds, revertMsg) => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockNumericPackages);
        await (0, chai_1.expect)(wrappedContract.save2ValuesInStorage(dataFeedIds.map(redstone_protocol_1.utils.convertStringToBytes32))).to.be.revertedWith(revertMsg);
    };
    this.beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleRedstoneConsumerNumericMockManyDataFeeds");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    it("Should properly execute transaction on RedstoneConsumerBase contract (order: ETH, BTC)", async () => {
        await testShouldPass(tests_common_1.mockNumericPackages, ["ETH", "BTC"]);
    });
    it("Should properly execute transaction on RedstoneConsumerBase contract (order: BTC, ETH)", async () => {
        await testShouldPass(tests_common_1.mockNumericPackages, ["BTC", "ETH"]);
    });
    it("Should properly execute transaction with 20 single pacakages (10 for ETH and 10 for BTC)", async () => {
        const mockSinglePackageConfigs = [
            ...(0, test_utils_1.getRange)({ start: 0, length: tests_common_1.NUMBER_OF_MOCK_NUMERIC_SIGNERS }).map((mockSignerIndex) => ({
                mockSignerIndex,
                dataPoints: [
                    { dataFeedId: "BTC", value: 400 },
                    { dataFeedId: "SOME OTHER ID", value: 123 },
                ],
            })),
            ...(0, test_utils_1.getRange)({ start: 0, length: tests_common_1.NUMBER_OF_MOCK_NUMERIC_SIGNERS }).map((mockSignerIndex) => ({
                mockSignerIndex,
                dataPoints: [
                    { dataFeedId: "ETH", value: 42 },
                    { dataFeedId: "SOME OTHER ID", value: 345 },
                ],
            })),
        ];
        const mockSinglePackages = mockSinglePackageConfigs.map(test_utils_1.getMockNumericPackage);
        await testShouldPass(mockSinglePackages, ["BTC", "ETH"]);
    });
    it("Should work properly with the greater number of unique signers than required", async () => {
        const newMockPackages = [
            ...tests_common_1.mockNumericPackages,
            (0, test_utils_1.getMockNumericPackage)({
                ...tests_common_1.mockNumericPackageConfigs[0],
                mockSignerIndex: tests_common_1.NUMBER_OF_MOCK_NUMERIC_SIGNERS,
            }),
        ];
        await testShouldPass(newMockPackages, ["BTC", "ETH"]);
    });
    it("Should revert if data feed id not found", async () => {
        await testShouldRevertWith(tests_common_1.mockNumericPackages, ["BTC", "NOT_BTC_AND_NOT_ETH"], "InsufficientNumberOfUniqueSigners(0, 10)");
    });
    it("Should revert for enough data packages but insufficient number of one data feed id", async () => {
        const newMockPackages = [...tests_common_1.mockNumericPackages];
        newMockPackages[1] = (0, test_utils_1.getMockNumericPackage)({
            ...tests_common_1.mockNumericPackageConfigs[1],
            dataPoints: [tests_common_1.mockNumericPackageConfigs[1].dataPoints[0]],
        });
        await testShouldRevertWith(newMockPackages, ["BTC", "ETH"], "InsufficientNumberOfUniqueSigners(9, 10)");
    });
    it("Should revert for too old timestamp", async () => {
        const newMockPackages = [...tests_common_1.mockNumericPackages];
        newMockPackages[1] = (0, test_utils_1.getMockNumericPackage)({
            ...tests_common_1.mockNumericPackageConfigs[1],
            timestampMilliseconds: test_utils_1.DEFAULT_TIMESTAMP_FOR_TESTS - 1,
        });
        await testShouldRevertWith(newMockPackages, ["BTC", "ETH"], "TimestampIsNotValid()");
    });
    it("Should revert for an unauthorised signer", async () => {
        const newMockPackages = [...tests_common_1.mockNumericPackages];
        newMockPackages[1] = (0, test_utils_1.getMockNumericPackage)({
            ...tests_common_1.mockNumericPackageConfigs[1],
            mockSignerIndex: tests_common_1.UNAUTHORISED_SIGNER_INDEX,
        });
        await testShouldRevertWith(newMockPackages, ["BTC", "ETH"], `SignerNotAuthorised("0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199")`);
    });
    it("Should revert for insufficient number of signers", async () => {
        const newMockPackages = tests_common_1.mockNumericPackages.slice(0, tests_common_1.NUMBER_OF_MOCK_NUMERIC_SIGNERS - 1);
        await testShouldRevertWith(newMockPackages, ["BTC", "ETH"], "InsufficientNumberOfUniqueSigners(9, 10)");
    });
    it("Should revert for duplicated packages (not enough unique signers)", async () => {
        const newMockPackages = [...tests_common_1.mockNumericPackages];
        newMockPackages[1] = tests_common_1.mockNumericPackages[0];
        await testShouldRevertWith(newMockPackages, ["BTC", "ETH"], "InsufficientNumberOfUniqueSigners(9, 10)");
    });
});
//# sourceMappingURL=numbers-many-data-feeds.test.js.map