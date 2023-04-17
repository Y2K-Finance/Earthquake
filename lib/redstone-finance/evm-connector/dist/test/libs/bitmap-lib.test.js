"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const ethers_1 = require("ethers");
const hardhat_1 = require("hardhat");
describe("SampleBitmapLib", function () {
    let contract, expectedBitmap = {}, bitmapNumber = ethers_1.BigNumber.from(0);
    const setBit = async (bitIndex) => {
        expectedBitmap[bitIndex] = 1;
        bitmapNumber = await contract.setBitInBitmap(bitmapNumber, bitIndex);
    };
    const validateBitmap = async () => {
        for (let bitIndex = 0; bitIndex < 256; bitIndex++) {
            const expectedBit = !!expectedBitmap[bitIndex];
            const receivedBit = await contract.getBitFromBitmap(bitmapNumber, bitIndex);
            const customErrMsg = "Bitmap invalid: " + JSON.stringify({ bitIndex });
            (0, chai_1.expect)(receivedBit).to.eq(expectedBit, customErrMsg);
        }
    };
    this.beforeAll(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleBitmapLib");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    it("Bitmap should be empty in the beginning", async () => {
        validateBitmap();
    });
    for (const bitIndexToSet of [0, 1, 42, 235, 255]) {
        it("Should correctly set bit: " + bitIndexToSet, async () => {
            await setBit(bitIndexToSet);
            await validateBitmap();
        });
    }
});
//# sourceMappingURL=bitmap-lib.test.js.map