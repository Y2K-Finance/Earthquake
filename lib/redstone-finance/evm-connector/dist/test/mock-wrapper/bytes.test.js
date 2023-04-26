"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const utils_1 = require("redstone-protocol/src/common/utils");
const test_utils_1 = require("../../src/helpers/test-utils");
const index_1 = require("../../src/index");
const tests_common_1 = require("../tests-common");
describe("SampleRedstoneConsumerBytesMock", function () {
    let contract;
    const mockBytesPackageConfigs = [
        {
            mockSignerIndex: 0,
            hexValue: "0xf4610900", // hex(41 * 10 ** 8)
        },
        {
            mockSignerIndex: 1,
            hexValue: "0x01004ccb00", // hex(43 * 10 ** 8)
        },
        {
            mockSignerIndex: 2,
            hexValue: "0xfa56ea00", // hex(42 * 10 ** 8)
        },
    ];
    const mockBytesPackages = mockBytesPackageConfigs.map(test_utils_1.getMockPackageWithOneBytesDataPoint);
    const expectedBytesValueConvertedToNumber = 42 * 10 ** 8;
    const testShouldPass = async (mockPackages) => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockPackages);
        const tx = await wrappedContract.saveOracleValueInContractStorage(test_utils_1.DEFAULT_DATA_FEED_ID_BYTES_32);
        await tx.wait();
        const latestEthPriceFromContract = await contract.latestSavedValue();
        (0, chai_1.expect)(latestEthPriceFromContract.toNumber()).to.be.equal(expectedBytesValueConvertedToNumber);
    };
    const testShouldRevertWith = async (mockPackages, revertMsg) => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockPackages);
        await (0, chai_1.expect)(wrappedContract.saveOracleValueInContractStorage(test_utils_1.DEFAULT_DATA_FEED_ID_BYTES_32)).to.be.revertedWith(revertMsg);
    };
    this.beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleRedstoneConsumerBytesMock");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    it("Should properly execute transaction on RedstoneConsumerBase contract", async () => {
        await testShouldPass(mockBytesPackages);
    });
    it("Should properly execute if there are redundant packages", async () => {
        await testShouldPass([...mockBytesPackages, mockBytesPackages[0]]);
    });
    it("Should properly execute if there are more unique signers than needed", async () => {
        await testShouldPass([
            ...mockBytesPackages,
            (0, test_utils_1.getMockPackageWithOneBytesDataPoint)({
                ...mockBytesPackageConfigs[0],
                mockSignerIndex: 11, // another authorised signer
            }),
        ]);
    });
    it("Should revert if there are too few signers", async () => {
        await testShouldRevertWith([mockBytesPackages[0], mockBytesPackages[1]], "InsufficientNumberOfUniqueSigners(2, 3)");
    });
    it("Should revert if there are too few unique signers", async () => {
        await testShouldRevertWith([mockBytesPackages[0], mockBytesPackages[1], mockBytesPackages[1]], "InsufficientNumberOfUniqueSigners(2, 3)");
    });
    it("Should revert for unauthorised signer", async () => {
        const newMockPackages = [
            mockBytesPackages[0],
            mockBytesPackages[1],
            (0, test_utils_1.getMockPackageWithOneBytesDataPoint)({
                ...mockBytesPackageConfigs[1],
                mockSignerIndex: tests_common_1.UNAUTHORISED_SIGNER_INDEX,
            }),
        ];
        await testShouldRevertWith(newMockPackages, `SignerNotAuthorised("0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199")`);
    });
    it("Should revert for too old timestamp", async () => {
        const newMockPackages = [
            mockBytesPackages[0],
            mockBytesPackages[1],
            (0, test_utils_1.getMockPackageWithOneBytesDataPoint)({
                ...mockBytesPackageConfigs[2],
                timestampMilliseconds: test_utils_1.DEFAULT_TIMESTAMP_FOR_TESTS - 1,
            }),
        ];
        await testShouldRevertWith(newMockPackages, "TimestampIsNotValid()");
    });
    it("Should revert is data feed id not found", async () => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockBytesPackages);
        await (0, chai_1.expect)(wrappedContract.saveOracleValueInContractStorage((0, utils_1.convertStringToBytes32)("ANOTHER_DATA_FEED_ID"))).to.be.revertedWith("InsufficientNumberOfUniqueSigners(0, 3)");
    });
});
//# sourceMappingURL=bytes.test.js.map