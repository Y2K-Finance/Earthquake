import { DataPackage } from "redstone-protocol";
import { MockSignerAddress } from "../helpers/test-utils";
import { BaseWrapper } from "./BaseWrapper";
export interface MockDataPackageConfig {
    signer: MockSignerAddress;
    dataPackage: DataPackage;
}
export declare class MockWrapper extends BaseWrapper {
    private mockDataPackages;
    constructor(mockDataPackages: MockDataPackageConfig[]);
    getUnsignedMetadata(): string;
    dryRunToVerifyPayload(payloads: string[]): Promise<string>;
    getBytesDataForAppending(): Promise<string>;
}
//# sourceMappingURL=MockWrapper.d.ts.map