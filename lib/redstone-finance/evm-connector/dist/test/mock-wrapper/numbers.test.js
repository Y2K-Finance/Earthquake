"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const redstone_protocol_1 = require("redstone-protocol");
const test_utils_1 = require("../../src/helpers/test-utils");
const index_1 = require("../../src/index");
const tests_common_1 = require("../tests-common");
describe("SampleRedstoneConsumerNumericMock", function () {
    let contract;
    const testShouldPass = async (mockNumericPackages, dataFeedId) => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockNumericPackages);
        const tx = await wrappedContract.saveOracleValueInContractStorage(redstone_protocol_1.utils.convertStringToBytes32(dataFeedId));
        await tx.wait();
        const valueFromContract = await contract.latestSavedValue();
        (0, chai_1.expect)(valueFromContract.toNumber()).to.be.equal(tests_common_1.expectedNumericValues[dataFeedId]);
    };
    const testShouldRevertWith = async (mockNumericPackages, dataFeedId, revertMsg) => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockNumericPackages);
        await (0, chai_1.expect)(wrappedContract.saveOracleValueInContractStorage(redstone_protocol_1.utils.convertStringToBytes32(dataFeedId))).to.be.revertedWith(revertMsg);
    };
    this.beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleRedstoneConsumerNumericMock");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    it("Should properly execute transaction on RedstoneConsumerBase contract (ETH)", async () => {
        await testShouldPass(tests_common_1.mockNumericPackages, "ETH");
    });
    it("Should properly execute transaction on RedstoneConsumerBase contract (BTC)", async () => {
        await testShouldPass(tests_common_1.mockNumericPackages, "BTC");
    });
    it("Should work properly with the greater number of unique signers than required", async () => {
        const newMockPackages = [
            ...tests_common_1.mockNumericPackages,
            (0, test_utils_1.getMockNumericPackage)({
                ...tests_common_1.mockNumericPackageConfigs[0],
                mockSignerIndex: tests_common_1.NUMBER_OF_MOCK_NUMERIC_SIGNERS,
            }),
        ];
        await testShouldPass(newMockPackages, "BTC");
    });
    it("Should revert if data feed id not found", async () => {
        await testShouldRevertWith(tests_common_1.mockNumericPackages, "NOT_BTC_AND_NOT_ETH", "InsufficientNumberOfUniqueSigners(0, 10)");
    });
    it("Should revert for too old timestamp", async () => {
        const newMockPackages = [...tests_common_1.mockNumericPackages];
        newMockPackages[1] = (0, test_utils_1.getMockNumericPackage)({
            ...tests_common_1.mockNumericPackageConfigs[1],
            timestampMilliseconds: test_utils_1.DEFAULT_TIMESTAMP_FOR_TESTS - 1,
        });
        await testShouldRevertWith(newMockPackages, "BTC", "TimestampIsNotValid()");
    });
    it("Should revert for an unauthorised signer", async () => {
        const newMockPackages = [...tests_common_1.mockNumericPackages];
        newMockPackages[1] = (0, test_utils_1.getMockNumericPackage)({
            ...tests_common_1.mockNumericPackageConfigs[1],
            mockSignerIndex: tests_common_1.UNAUTHORISED_SIGNER_INDEX,
        });
        await testShouldRevertWith(newMockPackages, "BTC", `SignerNotAuthorised("0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199")`);
    });
    it("Should revert for insufficient number of signers", async () => {
        const newMockPackages = tests_common_1.mockNumericPackages.slice(0, tests_common_1.NUMBER_OF_MOCK_NUMERIC_SIGNERS - 1);
        await testShouldRevertWith(newMockPackages, "BTC", "InsufficientNumberOfUniqueSigners(9, 10)");
    });
    it("Should revert for duplicated packages (not enough unique signers)", async () => {
        const newMockPackages = [...tests_common_1.mockNumericPackages];
        newMockPackages[1] = tests_common_1.mockNumericPackages[0];
        await testShouldRevertWith(newMockPackages, "BTC", "InsufficientNumberOfUniqueSigners(9, 10)");
    });
});
//# sourceMappingURL=numbers.test.js.map