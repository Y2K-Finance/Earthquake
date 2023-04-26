import { Contract } from "ethers";
import { DataPackagesRequestParams, DataPackagesResponse } from "redstone-sdk";
import { ScoreType } from "redstone-protocol";
import { MockDataPackageConfig } from "./wrappers/MockWrapper";
import { SimpleNumericMockConfig } from "./wrappers/SimpleMockNumericWrapper";
export declare class WrapperBuilder {
    private baseContract;
    constructor(baseContract: Contract);
    static wrap(contract: Contract): WrapperBuilder;
    usingDataService(dataPackagesRequestParams: DataPackagesRequestParams, urls: string[]): Contract;
    usingMockDataPackages(mockDataPackages: MockDataPackageConfig[]): Contract;
    usingSimpleNumericMock(simpleNumericMockConfig: SimpleNumericMockConfig): Contract;
    usingOnDemandRequest(nodeUrls: string[], scoreType: ScoreType): Contract;
    usingDataPackages(dataPackages: DataPackagesResponse): Contract;
}
//# sourceMappingURL=WrapperBuilder.d.ts.map