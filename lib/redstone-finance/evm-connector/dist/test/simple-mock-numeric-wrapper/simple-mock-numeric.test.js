"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const redstone_protocol_1 = require("redstone-protocol");
const test_utils_1 = require("../../src/helpers/test-utils");
const index_1 = require("../../src/index");
const dataPoints = [
    { dataFeedId: "ETH", value: 42 },
    { dataFeedId: "BTC", value: 400 },
];
describe("Simple Mock Numeric Wrapper", function () {
    let contract;
    this.beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleRedstoneConsumerNumericMockManyDataFeeds");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    it("Should properly execute on contract wrapped using simple numeric mock", async () => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingSimpleNumericMock({
            mockSignersCount: 10,
            dataPoints,
        });
        const tx = await wrappedContract.save2ValuesInStorage([
            redstone_protocol_1.utils.convertStringToBytes32(dataPoints[0].dataFeedId),
            redstone_protocol_1.utils.convertStringToBytes32(dataPoints[1].dataFeedId),
        ]);
        await tx.wait();
        const firstValueFromContract = await contract.firstValue();
        const secondValueFromContract = await contract.secondValue();
        (0, chai_1.expect)(firstValueFromContract.toNumber()).to.be.equal(dataPoints[0].value * 10 ** 8);
        (0, chai_1.expect)(secondValueFromContract.toNumber()).to.be.equal(dataPoints[1].value * 10 ** 8);
    });
    it("Should revert for too few signers", async () => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingSimpleNumericMock({
            mockSignersCount: 9,
            dataPoints,
        });
        await (0, chai_1.expect)(wrappedContract.save2ValuesInStorage([
            redstone_protocol_1.utils.convertStringToBytes32(dataPoints[0].dataFeedId),
            redstone_protocol_1.utils.convertStringToBytes32(dataPoints[1].dataFeedId),
        ])).to.be.revertedWith("InsufficientNumberOfUniqueSigners(9, 10)");
    });
    it("Should revert for too old timestamp", async () => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingSimpleNumericMock({
            mockSignersCount: 10,
            dataPoints,
            timestampMilliseconds: test_utils_1.DEFAULT_TIMESTAMP_FOR_TESTS - 1,
        });
        await (0, chai_1.expect)(wrappedContract.save2ValuesInStorage([
            redstone_protocol_1.utils.convertStringToBytes32(dataPoints[0].dataFeedId),
            redstone_protocol_1.utils.convertStringToBytes32(dataPoints[1].dataFeedId),
        ])).to.be.revertedWith("TimestampIsNotValid()");
    });
});
//# sourceMappingURL=simple-mock-numeric.test.js.map