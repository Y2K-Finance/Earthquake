"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const test_utils_1 = require("../../src/helpers/test-utils");
const index_1 = require("../../src/index");
const tests_common_1 = require("../tests-common");
describe("SampleRedstoneConsumerBytesMockStrings", function () {
    let contract;
    const someLongHexValue = "0x" + "f".repeat(1984) + "ee42"; // some long value
    const mockBytesPackages = (0, test_utils_1.getRange)({
        start: 0,
        length: 3,
    }).map((mockSignerIndex) => (0, test_utils_1.getMockPackageWithOneBytesDataPoint)({
        mockSignerIndex,
        hexValue: someLongHexValue,
    }));
    const testShouldPass = async (mockPackages) => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockPackages);
        const tx = await wrappedContract.saveLatestValueInStorage(test_utils_1.DEFAULT_DATA_FEED_ID_BYTES_32);
        await tx.wait();
        const latestString = await contract.latestString();
        (0, chai_1.expect)(latestString).to.be.equal(someLongHexValue);
    };
    const testShouldRevertWith = async (mockPackages, revertMsg) => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(mockPackages);
        await (0, chai_1.expect)(wrappedContract.saveLatestValueInStorage(test_utils_1.DEFAULT_DATA_FEED_ID_BYTES_32)).to.be.revertedWith(revertMsg);
    };
    this.beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleRedstoneConsumerBytesMockStrings");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    it("Should properly execute transaction on RedstoneConsumerBase contract", async () => {
        await testShouldPass(mockBytesPackages);
    });
    it("Should pass even if there are redundant packages", async () => {
        await testShouldPass([...mockBytesPackages, mockBytesPackages[0]]);
    });
    it("Should revert if values from different signers are different", async () => {
        const newPackages = [
            mockBytesPackages[0],
            mockBytesPackages[1],
            (0, test_utils_1.getMockPackageWithOneBytesDataPoint)({
                mockSignerIndex: 2,
                hexValue: someLongHexValue.replace("ee42", "ff42"),
            }),
        ];
        await testShouldRevertWith(newPackages, "EachSignerMustProvideTheSameValue()");
    });
    it("Should revert if there are too few signers", async () => {
        await testShouldRevertWith([mockBytesPackages[0], mockBytesPackages[1]], "InsufficientNumberOfUniqueSigners(2, 3)");
    });
    it("Should revert if there are too few unique signers", async () => {
        await testShouldRevertWith([mockBytesPackages[0], mockBytesPackages[1], mockBytesPackages[1]], "InsufficientNumberOfUniqueSigners(2, 3)");
    });
    it("Should revert if there is an unauthorised signer", async () => {
        await testShouldRevertWith([
            ...mockBytesPackages,
            (0, test_utils_1.getMockPackageWithOneBytesDataPoint)({
                hexValue: someLongHexValue,
                mockSignerIndex: tests_common_1.UNAUTHORISED_SIGNER_INDEX,
            }),
        ], `SignerNotAuthorised("0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199")`);
    });
});
//# sourceMappingURL=bytes-string.test.js.map