"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DataPackagesWrapper = void 0;
const redstone_protocol_1 = require("redstone-protocol");
const BaseWrapper_1 = require("./BaseWrapper");
const package_json_1 = require("../../package.json");
class DataPackagesWrapper extends BaseWrapper_1.BaseWrapper {
    constructor(dataPackages) {
        super();
        this.dataPackages = dataPackages;
    }
    getUnsignedMetadata() {
        const currentTimestamp = Date.now();
        return `${currentTimestamp}#${package_json_1.version}#data-packages-wrapper`;
    }
    async getBytesDataForAppending() {
        return this.getRedstonePayload();
    }
    getRedstonePayload() {
        const unsignedMetadataMsg = this.getUnsignedMetadata();
        const signedDataPackages = Object.values(this.dataPackages).flat();
        return redstone_protocol_1.RedstonePayload.prepare(signedDataPackages, unsignedMetadataMsg || "");
    }
}
exports.DataPackagesWrapper = DataPackagesWrapper;
//# sourceMappingURL=DataPackagesWrapper.js.map