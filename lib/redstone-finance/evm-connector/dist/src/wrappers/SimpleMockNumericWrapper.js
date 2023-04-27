"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SimpleNumericMockWrapper = void 0;
const redstone_protocol_1 = require("redstone-protocol");
const test_utils_1 = require("../helpers/test-utils");
const package_json_1 = require("../../package.json");
const MockWrapper_1 = require("./MockWrapper");
class SimpleNumericMockWrapper extends MockWrapper_1.MockWrapper {
    constructor(simpleNumericMockConfig) {
        if (simpleNumericMockConfig.mockSignersCount > test_utils_1.MAX_MOCK_SIGNERS_COUNT) {
            throw new Error(`mockSignersCount should be <= ${test_utils_1.MAX_MOCK_SIGNERS_COUNT}`);
        }
        // Prepare mock data packages configs
        const mockDataPackages = [];
        for (let signerIndex = 0; signerIndex < simpleNumericMockConfig.mockSignersCount; signerIndex++) {
            for (const dataPointObj of simpleNumericMockConfig.dataPoints) {
                const dataPoint = new redstone_protocol_1.NumericDataPoint(dataPointObj);
                const timestampMilliseconds = simpleNumericMockConfig.timestampMilliseconds ||
                    test_utils_1.DEFAULT_TIMESTAMP_FOR_TESTS;
                const mockDataPackage = {
                    signer: (0, test_utils_1.getMockSignerAddress)(signerIndex),
                    dataPackage: new redstone_protocol_1.DataPackage([dataPoint], timestampMilliseconds),
                };
                mockDataPackages.push(mockDataPackage);
            }
        }
        super(mockDataPackages);
    }
    getUnsignedMetadata() {
        return `${package_json_1.version}#simple-numeric-mock`;
    }
}
exports.SimpleNumericMockWrapper = SimpleNumericMockWrapper;
//# sourceMappingURL=SimpleMockNumericWrapper.js.map