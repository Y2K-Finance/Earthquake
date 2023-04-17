"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getBlockTimestampMilliseconds = exports.UNAUTHORISED_SIGNER_INDEX = exports.expectedBytesValues = exports.mockBytesPackages = exports.mockBytesPackageConfigs = exports.bytesDataPoints = exports.expectedNumericValues = exports.mockSignedDataPackageObjects = exports.mockNumericPackages = exports.mockNumericPackageConfigs = exports.NUMBER_OF_MOCK_NUMERIC_SIGNERS = void 0;
const hardhat_1 = require("hardhat");
const test_utils_1 = require("../src/helpers/test-utils");
exports.NUMBER_OF_MOCK_NUMERIC_SIGNERS = 10;
exports.mockNumericPackageConfigs = [
    {
        mockSignerIndex: 0,
        dataPoints: [
            { dataFeedId: "BTC", value: 412 },
            { dataFeedId: "ETH", value: 41 },
            { dataFeedId: "SOME OTHER ID 0", value: 123 },
            { dataFeedId: "SOME OTHER ID 1", value: 123 },
        ],
    },
    {
        mockSignerIndex: 1,
        dataPoints: [
            { dataFeedId: "BTC", value: 390 },
            { dataFeedId: "ETH", value: 42 },
            { dataFeedId: "SOME OTHER ID 1", value: 123 },
        ],
    },
    {
        mockSignerIndex: 2,
        dataPoints: [
            { dataFeedId: "BTC", value: 400 },
            { dataFeedId: "ETH", value: 43 },
            { dataFeedId: "SOME OTHER ID 2", value: 123 },
        ],
    },
    ...(0, test_utils_1.getRange)({ start: 3, length: exports.NUMBER_OF_MOCK_NUMERIC_SIGNERS - 3 }).map((mockSignerIndex) => ({
        mockSignerIndex,
        dataPoints: [
            { dataFeedId: "ETH", value: 42 },
            { dataFeedId: "BTC", value: 400 },
            { dataFeedId: "SOME OTHER ID", value: 123 },
        ],
    })),
];
exports.mockNumericPackages = exports.mockNumericPackageConfigs.map(test_utils_1.getMockNumericPackage);
exports.mockSignedDataPackageObjects = exports.mockNumericPackageConfigs.map(test_utils_1.getMockSignedDataPackageObj);
exports.expectedNumericValues = {
    ETH: 42 * 10 ** 8,
    BTC: 400 * 10 ** 8,
};
exports.bytesDataPoints = [
    {
        dataFeedId: "ETH",
        value: "Ethereum",
    },
    {
        dataFeedId: "BTC",
        value: "Bitcoin_",
    },
    {
        dataFeedId: "SOME OTHER ID",
        value: "Hahahaha",
    },
];
exports.mockBytesPackageConfigs = (0, test_utils_1.getRange)({
    start: 0,
    length: 3,
}).map((i) => ({
    dataPoints: exports.bytesDataPoints,
    mockSignerIndex: i,
}));
exports.mockBytesPackages = exports.mockBytesPackageConfigs.map(test_utils_1.getMockStringPackage);
exports.expectedBytesValues = {
    ETH: "0x457468657265756d",
    BTC: "0x426974636f696e5f",
};
exports.UNAUTHORISED_SIGNER_INDEX = 19;
const getBlockTimestampMilliseconds = async () => {
    const blockNum = await hardhat_1.ethers.provider.getBlockNumber();
    const block = await hardhat_1.ethers.provider.getBlock(blockNum);
    return block.timestamp * 1000;
};
exports.getBlockTimestampMilliseconds = getBlockTimestampMilliseconds;
//# sourceMappingURL=tests-common.js.map