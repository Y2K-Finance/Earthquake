"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const hardhat_1 = require("hardhat");
const index_1 = require("../../src/index");
const chai_1 = require("chai");
const tests_common_1 = require("../tests-common");
const utils_1 = require("redstone-protocol/src/common/utils");
const test_utils_1 = require("../../src/helpers/test-utils");
// TODO audit: measure how many bytes do we add to the consumer contracts
describe("SampleSyntheticToken", function () {
    let sampleContract, wrappedContract, signer, address;
    const toEth = function (val) {
        return hardhat_1.ethers.utils.parseEther(val.toString());
    };
    const toVal = function (val) {
        return hardhat_1.ethers.utils.parseUnits(val.toString(), 26);
    };
    beforeEach(async () => {
        const SampleSyntheticToken = await hardhat_1.ethers.getContractFactory("SampleSyntheticToken");
        sampleContract = await SampleSyntheticToken.deploy();
        await sampleContract.initialize((0, utils_1.convertStringToBytes32)("REDSTONE"), "SYNTH-REDSTONE", "SREDSTONE");
        await sampleContract.deployed();
        [signer] = await hardhat_1.ethers.getSigners();
        address = await signer.getAddress();
        const mockDataPackages = (0, test_utils_1.getRange)({
            start: 0,
            length: tests_common_1.NUMBER_OF_MOCK_NUMERIC_SIGNERS,
        }).map((i) => (0, test_utils_1.getMockNumericPackage)({
            dataPoints: [
                {
                    dataFeedId: "ETH",
                    value: 2000,
                },
                {
                    dataFeedId: "REDSTONE",
                    value: 200,
                },
            ],
            mockSignerIndex: i,
        }));
        wrappedContract =
            index_1.WrapperBuilder.wrap(sampleContract).usingMockDataPackages(mockDataPackages);
    });
    it("Maker balance should be 0", async () => {
        (0, chai_1.expect)(await wrappedContract.balanceOf(address)).to.equal(0);
    });
    it("Should mint", async () => {
        const tx = await wrappedContract.mint(toEth(100), { value: toEth(20) });
        await tx.wait();
        (0, chai_1.expect)(await wrappedContract.balanceOf(address)).to.equal(toEth(100));
        (0, chai_1.expect)(await wrappedContract.balanceValueOf(address)).to.equal(toVal(20000));
        (0, chai_1.expect)(await wrappedContract.totalValue()).to.equal(toVal(20000));
        (0, chai_1.expect)(await wrappedContract.collateralOf(address)).to.equal(toEth(20));
        (0, chai_1.expect)(await wrappedContract.collateralValueOf(address)).to.equal(toVal(40000));
        (0, chai_1.expect)(await wrappedContract.debtOf(address)).to.equal(toEth(100));
        (0, chai_1.expect)(await wrappedContract.debtValueOf(address)).to.equal(toVal(20000));
        (0, chai_1.expect)(await wrappedContract.solvencyOf(address)).to.equal(2000);
    });
});
//# sourceMappingURL=synthetic-token.test.js.map