"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const index_1 = require("../../src/index");
const redstone_protocol_1 = require("redstone-protocol");
const tests_common_1 = require("../tests-common");
const redstone_constants_1 = require("redstone-protocol/src/common/redstone-constants");
describe("PopulateTransactionTest", function () {
    it("Should overwrite populateTransaction", async () => {
        // Deploying the contract
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleRedstoneConsumerNumericMock");
        const contract = await ContractFactory.deploy();
        await contract.deployed();
        // Wrapping the contract
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        // Prepare calldata for original and wrapped contracts
        const dataFeedId = redstone_protocol_1.utils.convertStringToBytes32("ETH");
        const originalTxPopulated = await contract.populateTransaction["getValueForDataFeedId"](dataFeedId);
        const wrappedTxPopulated = await wrappedContract.populateTransaction["getValueForDataFeedId"](dataFeedId);
        // Checking the calldata
        const redstoneMarker = redstone_constants_1.REDSTONE_MARKER_HEX.replace("0x", "");
        (0, chai_1.expect)(originalTxPopulated.data)
            .to.be.a("string")
            .and.satisfy((str) => !str.endsWith(redstoneMarker));
        (0, chai_1.expect)(wrappedTxPopulated.data)
            .to.be.a("string")
            .and.satisfy((str) => str.endsWith(redstoneMarker));
    });
});
//# sourceMappingURL=populate-transaction.test.js.map