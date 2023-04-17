"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const redstone_protocol_1 = require("redstone-protocol");
describe("Not Wrapped Contract", function () {
    let contract;
    this.beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleRedstoneConsumerNumericMock");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    it("Should revert if contract was not wrapped", async () => {
        await (0, chai_1.expect)(contract.saveOracleValueInContractStorage(redstone_protocol_1.utils.convertStringToBytes32("BTC"))).to.be.revertedWith("CalldataMustHaveValidPayload()");
    });
});
//# sourceMappingURL=not-wrapped.test.js.map