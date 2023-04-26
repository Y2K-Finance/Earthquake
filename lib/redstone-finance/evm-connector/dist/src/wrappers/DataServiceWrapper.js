"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DataServiceWrapper = void 0;
const redstone_sdk_1 = require("redstone-sdk");
const BaseWrapper_1 = require("./BaseWrapper");
const parse_aggregated_errors_1 = require("../helpers/parse-aggregated-errors");
const run_dry_run_1 = require("../helpers/run-dry-run");
const package_json_1 = require("../../package.json");
class DataServiceWrapper extends BaseWrapper_1.BaseWrapper {
    constructor(dataPackagesRequestParams, urls) {
        super();
        this.dataPackagesRequestParams = dataPackagesRequestParams;
        this.urls = urls;
    }
    getUnsignedMetadata() {
        const currentTimestamp = Date.now();
        return `${currentTimestamp}#${package_json_1.version}#${this.dataPackagesRequestParams.dataServiceId}`;
    }
    async getBytesDataForAppending(params) {
        const unsignedMetadataMsg = this.getUnsignedMetadata();
        const disablePayloadsDryRun = Boolean(this.dataPackagesRequestParams.disablePayloadsDryRun);
        if (disablePayloadsDryRun) {
            return this.requestPayloadWithoutDryRun(this.urls, unsignedMetadataMsg);
        }
        return this.requestPayloadWithDryRun({ ...params, unsignedMetadataMsg });
    }
    /*
      Call function on provider always returns some result and doesn't throw an error.
      Later we need to decode the result from the call (decodeFunctionResult) and
      this function will throw an error if the call was reverted.
    */
    async requestPayloadWithDryRun({ unsignedMetadataMsg, ...params }) {
        const promises = this.urls.map(async (url) => {
            const redstonePayload = await this.requestPayloadWithoutDryRun([url], unsignedMetadataMsg);
            await (0, run_dry_run_1.runDryRun)({ ...params, redstonePayload });
            return redstonePayload;
        });
        return Promise.any(promises).catch((error) => {
            const parsedErrors = (0, parse_aggregated_errors_1.parseAggregatedErrors)(error);
            throw new Error(`All redstone payloads do not pass dry run verification, aggregated errors: ${parsedErrors}`);
        });
    }
    async requestPayloadWithoutDryRun(urls, unsignedMetadataMsg) {
        return (0, redstone_sdk_1.requestRedstonePayload)(this.dataPackagesRequestParams, urls, unsignedMetadataMsg);
    }
}
exports.DataServiceWrapper = DataServiceWrapper;
//# sourceMappingURL=DataServiceWrapper.js.map