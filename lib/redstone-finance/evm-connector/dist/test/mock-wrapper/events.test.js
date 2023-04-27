"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const hardhat_1 = require("hardhat");
const index_1 = require("../../src/index");
const chai_1 = require("chai");
const tests_common_1 = require("../tests-common");
describe("SampleWithEvents", function () {
    let sampleContract;
    beforeEach(async () => {
        const SampleWithEvents = await hardhat_1.ethers.getContractFactory("SampleWithEvents");
        sampleContract = await SampleWithEvents.deploy();
    });
    it("Test events with contract wrapping", async function () {
        // Wrapping the contract instnace
        const wrappedContract = index_1.WrapperBuilder.wrap(sampleContract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        // Sending tx
        const tx = await wrappedContract.emitEventWithLatestOracleValue();
        const receipt = await tx.wait();
        const event = receipt.events[0];
        // Receipt should have parsed events
        (0, chai_1.expect)(receipt.events.length).to.be.equal(1);
        (0, chai_1.expect)(event.args._updatedValue.toNumber()).to.be.gt(0);
        (0, chai_1.expect)(event.event).to.be.equal("ValueUpdated");
    });
});
//# sourceMappingURL=events.test.js.map