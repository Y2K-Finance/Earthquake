"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OnDemandRequestWrapper = void 0;
const axios_1 = __importDefault(require("axios"));
const redstone_protocol_1 = require("redstone-protocol");
const BaseWrapper_1 = require("./BaseWrapper");
const package_json_1 = require("../../package.json");
class OnDemandRequestWrapper extends BaseWrapper_1.BaseWrapper {
    constructor(requestParams, nodeUrls) {
        super();
        this.requestParams = requestParams;
        this.nodeUrls = nodeUrls;
    }
    getUnsignedMetadata() {
        return `${package_json_1.version}#on-demand-request`;
    }
    async dryRunToVerifyPayload(payloads) {
        return payloads[0];
    }
    async getBytesDataForAppending() {
        const timestamp = Date.now();
        const message = (0, redstone_protocol_1.prepareMessageToSign)(timestamp);
        const { signer, scoreType } = this.requestParams;
        const signature = await redstone_protocol_1.UniversalSigner.signWithEthereumHashMessage(signer, message);
        const promises = this.nodeUrls.map((url) => axios_1.default.get(url, {
            params: { timestamp, signature, scoreType },
        }));
        const responses = await Promise.all(promises);
        const signedDataPackages = responses.map((response) => redstone_protocol_1.SignedDataPackage.fromObj(response.data));
        const unsignedMetadata = this.getUnsignedMetadata();
        return redstone_protocol_1.RedstonePayload.prepare(signedDataPackages, unsignedMetadata);
    }
}
exports.OnDemandRequestWrapper = OnDemandRequestWrapper;
//# sourceMappingURL=OnDemandRequestWrapper.js.map