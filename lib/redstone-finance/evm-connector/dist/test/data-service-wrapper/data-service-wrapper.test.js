"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = __importStar(require("chai"));
const chai_as_promised_1 = __importDefault(require("chai-as-promised"));
const hardhat_1 = require("hardhat");
const redstone_protocol_1 = require("redstone-protocol");
const index_1 = require("../../src/index");
const tests_common_1 = require("../tests-common");
const mock_server_1 = require("./mock-server");
chai_1.default.use(chai_as_promised_1.default);
describe("DataServiceWrapper", () => {
    let contract;
    const runTest = async (urls) => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingDataService({
            dataServiceId: "mock-data-service",
            uniqueSignersCount: 10,
            dataFeeds: ["ETH", "BTC"],
        }, urls);
        const tx = await wrappedContract.save2ValuesInStorage([
            redstone_protocol_1.utils.convertStringToBytes32("ETH"),
            redstone_protocol_1.utils.convertStringToBytes32("BTC"),
        ]);
        await tx.wait();
        const firstValueFromContract = await contract.firstValue();
        const secondValueFromContract = await contract.secondValue();
        (0, chai_1.expect)(firstValueFromContract.toNumber()).to.be.equal(tests_common_1.expectedNumericValues["ETH"]);
        (0, chai_1.expect)(secondValueFromContract.toNumber()).to.be.equal(tests_common_1.expectedNumericValues["BTC"]);
    };
    before(() => mock_server_1.server.listen());
    beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleRedstoneConsumerNumericMockManyDataFeeds");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    afterEach(() => mock_server_1.server.resetHandlers());
    after(() => mock_server_1.server.close());
    it("Should properly execute with one valid cache", async () => {
        await runTest(["http://valid-cache.com"]);
    });
    it("Should properly execute with one valid and one invalid cache", async () => {
        await runTest(["http://valid-cache.com", "http://invalid-cache.com"]);
    });
    it("Should properly execute with one valid and one slower cache", async () => {
        await runTest(["http://slower-cache.com", "http://valid-cache.com"]);
    });
    it("Should properly execute with one invalid and one slower cache", async () => {
        await runTest(["http://invalid-cache.com", "http://slower-cache.com"]);
    });
    it("Should throw error when multiple invalid caches", async () => {
        const expectedErrorMessage = `All redstone payloads do not pass dry run verification, aggregated errors: {
  "reason": null,
  "code": "CALL_EXCEPTION",
  "method": "save2ValuesInStorage(bytes32[])",
  "data": "0xec459bc000000000000000000000000041e13e6e0a8b13f8539b71f3c07d3f97f887f573",
  "errorArgs": [
    "0x41e13E6e0A8B13F8539B71f3c07d3f97F887F573"
  ],
  "errorName": "SignerNotAuthorised",
  "errorSignature": "SignerNotAuthorised(address)"
},{
  "reason": null,
  "code": "CALL_EXCEPTION",
  "method": "save2ValuesInStorage(bytes32[])",
  "data": "0xec459bc000000000000000000000000041e13e6e0a8b13f8539b71f3c07d3f97f887f573",
  "errorArgs": [
    "0x41e13E6e0A8B13F8539B71f3c07d3f97F887F573"
  ],
  "errorName": "SignerNotAuthorised",
  "errorSignature": "SignerNotAuthorised(address)"
}`;
        await (0, chai_1.expect)(runTest(["http://invalid-cache.com", "http://invalid-cache.com"])).to.be.rejectedWith(expectedErrorMessage);
    });
});
//# sourceMappingURL=data-service-wrapper.test.js.map