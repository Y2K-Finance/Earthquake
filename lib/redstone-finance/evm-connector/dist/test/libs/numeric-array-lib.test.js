"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const hardhat_1 = require("hardhat");
const chai_1 = require("chai");
const ethers_1 = require("ethers");
const test_utils_1 = require("../../src/helpers/test-utils");
describe("SampleNumericArrayLib", function () {
    let contract;
    const testArr = [3, 1, 4, 5, 2, 9, 8, 7, 4];
    const sortedTestArr = [...testArr].sort();
    const prepareRandomArray = (arrayLength) => {
        return (0, test_utils_1.getRange)({ start: 0, length: arrayLength }).map(() => Math.round(Math.random() * 10000));
    };
    beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleNumericArrayLib");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    it("Should store array in storage", async () => {
        const tx = await contract.testArrayUpdatingInStorage([
            3, 1, 4, 5, 2, 9, 8, 7, 4,
        ]);
        await tx.wait();
    });
    it("Should correctly sort values", async () => {
        const tx = await contract.testSortTx([3, 1, 4, 5, 2, 9, 8, 7, 4]);
        await tx.wait();
        const cachedArray = await contract.getCachedArray();
        (0, chai_1.expect)(cachedArray.map((bn) => bn.toNumber())).to.eql(sortedTestArr);
    });
    it("Should correctly pick the median value in an array with an odd length", async () => {
        const tx = await contract.testMedianSelection([3, 2, 5, 4, 1]);
        await tx.wait();
        const selectedMedian = await contract.cachedMedian();
        (0, chai_1.expect)(selectedMedian.toNumber()).to.eq(3);
    });
    it("Should correctly pick the median value in an array with an even length", async () => {
        const tx = await contract.testMedianSelection([300, 200, 500, 400]);
        await tx.wait();
        const selectedMedian = await contract.cachedMedian();
        (0, chai_1.expect)(selectedMedian.toNumber()).to.eq(350);
    });
    it("Should store array in storage", async () => {
        const tx = await contract.testArrayUpdatingInStorage([
            3, 1, 4, 5, 2, 9, 8, 7, 4,
        ]);
        await tx.wait();
    });
    it("Should store array in storage", async () => {
        const tx = await contract.testArrayUpdatingInStorage([
            3, 1, 4, 5, 2, 9, 8, 7, 4,
        ]);
        await tx.wait();
    });
    it("Should correctly sort an empty array", async () => {
        const sortTx = await contract.testSortTx([]);
        await sortTx.wait();
        const cachedArray = await contract.getCachedArray();
        (0, chai_1.expect)(cachedArray).to.eql([]);
    });
    it("Should revert trying to pick a median value from an empty array", async () => {
        await (0, chai_1.expect)(contract.testMedianSelection([])).to.be.revertedWith("CanNotPickMedianOfEmptyArray()");
    });
    it("Should properly sort 1-elem array", async () => {
        const sortTx = await contract.testSortTx([42]);
        await sortTx.wait();
        const cachedArray = await contract.getCachedArray();
        (0, chai_1.expect)(cachedArray).to.eql([ethers_1.BigNumber.from(42)]);
    });
    it("Should correctly pick median from 1-elem array", async () => {
        const tx = await contract.testMedianSelection([12]);
        await tx.wait();
        const selectedMedian = await contract.cachedMedian();
        (0, chai_1.expect)(selectedMedian.toNumber()).to.eq(12);
    });
    it("Should properly sort 2-elem array", async () => {
        const sortTx = await contract.testSortTx([42, 12]);
        await sortTx.wait();
        const cachedArray = await contract.getCachedArray();
        (0, chai_1.expect)(cachedArray).to.eql([ethers_1.BigNumber.from(12), ethers_1.BigNumber.from(42)]);
    });
    it("Should correctly pick median from 2-elem array", async () => {
        const tx = await contract.testMedianSelection([42, 12]);
        await tx.wait();
        const selectedMedian = await contract.cachedMedian();
        (0, chai_1.expect)(selectedMedian.toNumber()).to.eq(27);
    });
    it("Should properly sort 100-elem array", async () => {
        const arr = prepareRandomArray(100);
        const sortTx = await contract.testSortTx(arr);
        await sortTx.wait();
        const cachedArray = await contract.getCachedArray();
        arr.sort((a, b) => a - b);
        (0, chai_1.expect)(cachedArray.map((el) => el.toNumber())).to.eql(arr);
    });
    it("Should correctly pick median from 100-elem array", async () => {
        const arr = prepareRandomArray(101);
        const tx = await contract.testMedianSelection(arr);
        await tx.wait();
        const selectedMedian = await contract.cachedMedian();
        arr.sort((a, b) => a - b);
        (0, chai_1.expect)(selectedMedian.toNumber()).to.eq(arr[50]);
    });
});
//# sourceMappingURL=numeric-array-lib.test.js.map