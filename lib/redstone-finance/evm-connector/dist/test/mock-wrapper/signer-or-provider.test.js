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
const hardhat_1 = require("hardhat");
const index_1 = require("../../src/index");
const redstone_protocol_1 = require("redstone-protocol");
const tests_common_1 = require("../tests-common");
const chai_as_promised_1 = __importDefault(require("chai-as-promised"));
chai_1.default.use(chai_as_promised_1.default);
const DATA_FEED_ID = redstone_protocol_1.utils.convertStringToBytes32("ETH");
const EXPECTED_DATA_FEED_VALUE = 4200000000;
describe("SignerOrProviderTest", function () {
    let deployedContract;
    this.beforeEach(async () => {
        const ContractFactory = await hardhat_1.ethers.getContractFactory("SampleRedstoneConsumerNumericMock");
        deployedContract = await ContractFactory.deploy();
        await deployedContract.deployed();
    });
    it("Should call static function without signer", async () => {
        const contract = deployedContract.connect(hardhat_1.ethers.provider);
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        const response = await wrappedContract.getValueForDataFeedId(DATA_FEED_ID);
        (0, chai_1.expect)(response.toNumber()).to.equal(EXPECTED_DATA_FEED_VALUE);
    });
    it("Should revert with non-static function without signer", async () => {
        const contract = deployedContract.connect(hardhat_1.ethers.provider);
        const wrappedContract = index_1.WrapperBuilder.wrap(contract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        await (0, chai_1.expect)(wrappedContract.saveOracleValueInContractStorage(DATA_FEED_ID)).to.be.rejectedWith("Cannot read properties of null (reading 'sendTransaction')");
    });
    it("Should call non-static function with signer", async () => {
        const wrappedContract = index_1.WrapperBuilder.wrap(deployedContract).usingMockDataPackages(tests_common_1.mockNumericPackages);
        const tx = await wrappedContract.saveOracleValueInContractStorage(DATA_FEED_ID);
        await tx.wait();
    });
});
//# sourceMappingURL=signer-or-provider.test.js.map