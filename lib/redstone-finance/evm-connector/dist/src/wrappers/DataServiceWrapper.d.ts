import { DataPackagesRequestParams } from "redstone-sdk";
import { BaseWrapper, ParamsForDryRunVerification } from "./BaseWrapper";
interface DryRunParamsWithUnsignedMetadata extends ParamsForDryRunVerification {
    unsignedMetadataMsg: string;
}
export declare class DataServiceWrapper extends BaseWrapper {
    private dataPackagesRequestParams;
    private urls;
    constructor(dataPackagesRequestParams: DataPackagesRequestParams, urls: string[]);
    getUnsignedMetadata(): string;
    getBytesDataForAppending(params: ParamsForDryRunVerification): Promise<string>;
    requestPayloadWithDryRun({ unsignedMetadataMsg, ...params }: DryRunParamsWithUnsignedMetadata): Promise<string>;
    requestPayloadWithoutDryRun(urls: string[], unsignedMetadataMsg: string): Promise<string>;
}
export {};
//# sourceMappingURL=DataServiceWrapper.d.ts.map