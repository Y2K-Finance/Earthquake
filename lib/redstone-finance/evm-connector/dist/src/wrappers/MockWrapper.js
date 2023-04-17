"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MockWrapper = void 0;
const redstone_protocol_1 = require("redstone-protocol");
const test_utils_1 = require("../helpers/test-utils");
const BaseWrapper_1 = require("./BaseWrapper");
const package_json_1 = require("../../package.json");
class MockWrapper extends BaseWrapper_1.BaseWrapper {
    constructor(mockDataPackages) {
        super();
        this.mockDataPackages = mockDataPackages;
    }
    getUnsignedMetadata() {
        return `${package_json_1.version}#mock`;
    }
    async dryRunToVerifyPayload(payloads) {
        return payloads[0];
    }
    async getBytesDataForAppending() {
        const signedDataPackages = [];
        for (const mockDataPackage of this.mockDataPackages) {
            const privateKey = (0, test_utils_1.getMockSignerPrivateKey)(mockDataPackage.signer);
            const signedDataPackage = mockDataPackage.dataPackage.sign(privateKey);
            signedDataPackages.push(signedDataPackage);
        }
        const unsignedMetadata = this.getUnsignedMetadata();
        return redstone_protocol_1.RedstonePayload.prepare(signedDataPackages, unsignedMetadata);
    }
}
exports.MockWrapper = MockWrapper;
//# sourceMappingURL=MockWrapper.js.map