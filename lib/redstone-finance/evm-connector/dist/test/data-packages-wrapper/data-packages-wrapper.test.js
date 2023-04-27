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
const helpers_1 = require("./helpers");
chai_1.default.use(chai_as_promised_1.default);
describe("DataPackagesWrapper", () => {
    let contract;
    const runTest = async (dataPackagesResponse) => {
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingDataPackages(dataPackagesResponse);
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
    beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleRedstoneConsumerNumericMockManyDataFeeds");
        contract = await ContractFactory.deploy();
        await contract.deployed();
    });
    it("Should properly execute", async () => {
        const dataPackagesResponse = (0, helpers_1.getValidDataPackagesResponse)();
        await runTest(dataPackagesResponse);
    });
});
//# sourceMappingURL=data-packages-wrapper.test.js.map