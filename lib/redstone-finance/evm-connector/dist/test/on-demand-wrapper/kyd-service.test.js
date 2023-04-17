"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
const redstone_protocol_1 = require("redstone-protocol");
const index_1 = require("../../src/index");
const mock_server_1 = require("./mock-server");
describe("SampleKydServiceConsumer", () => {
    let contract;
    before(async () => {
        mock_server_1.server.listen();
        await hardhat_1.network.provider.send("hardhat_reset");
    });
    beforeEach(async () => {
        contract = await getContract();
    });
    afterEach(() => mock_server_1.server.resetHandlers());
    after(() => mock_server_1.server.close());
    it("Address should pass KYD", async () => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingOnDemandRequest([
            "http://first-node.com/score-by-address",
            "http://second-node.com/score-by-address",
        ], redstone_protocol_1.ScoreType.coinbaseKYD);
        const transaction = await wrappedContract.executeActionPassingKYD();
        await transaction.wait();
        const passedKydValue = await contract.getPassedKYDValue();
        (0, chai_1.expect)(passedKydValue).to.be.equal(true);
    });
    it("Address shouldn't pass KYD", async () => {
        contract = await getContract(false);
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingOnDemandRequest([
            "http://first-node.com/score-by-address",
            "http://second-node.com/score-by-address",
        ], redstone_protocol_1.ScoreType.coinbaseKYD);
        await (0, chai_1.expect)(wrappedContract.executeActionPassingKYD()).to.be.revertedWith(`UserDidNotPassKYD("0x70997970C51812dc3A010C7d01b50e0d17dc79C8")`);
    });
    it("Should revert if invalid response from one node", async () => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingOnDemandRequest([
            "http://first-node.com/score-by-address",
            "http://invalid-address-node.com/score-by-address",
        ], redstone_protocol_1.ScoreType.coinbaseKYD);
        await (0, chai_1.expect)(wrappedContract.executeActionPassingKYD()).to.be.revertedWith("InsufficientNumberOfUniqueSigners(1, 2)");
    });
    it("Should revert if one value from node is not equal", async () => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingOnDemandRequest([
            "http://first-node.com/score-by-address",
            "http://invalid-value-node.com/score-by-address",
        ], redstone_protocol_1.ScoreType.coinbaseKYD);
        await (0, chai_1.expect)(wrappedContract.executeActionPassingKYD()).to.be.revertedWith("AllValuesMustBeEqual()");
    });
    it("Should revert if two calls to the same node", async () => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingOnDemandRequest([
            "http://first-node.com/score-by-address",
            "http://first-node.com/score-by-address",
        ], redstone_protocol_1.ScoreType.coinbaseKYD);
        await (0, chai_1.expect)(wrappedContract.executeActionPassingKYD()).to.be.revertedWith("InsufficientNumberOfUniqueSigners(1, 2)");
    });
});
const getContract = async (isValidSigner = true) => {
    const signers = await hardhat_1.ethers.getSigners();
    const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleKydServiceConsumer", isValidSigner ? signers[0] : signers[1]);
    const contract = await ContractFactory.deploy();
    await contract.deployed();
    return contract;
};
//# sourceMappingURL=kyd-service.test.js.map