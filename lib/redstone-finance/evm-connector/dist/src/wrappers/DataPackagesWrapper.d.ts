import { DataPackagesResponse } from "redstone-sdk";
import { BaseWrapper } from "./BaseWrapper";
export declare class DataPackagesWrapper extends BaseWrapper {
    private dataPackages;
    constructor(dataPackages: DataPackagesResponse);
    getUnsignedMetadata(): string;
    getBytesDataForAppending(): Promise<string>;
    getRedstonePayload(): string;
}
//# sourceMappingURL=DataPackagesWrapper.d.ts.map