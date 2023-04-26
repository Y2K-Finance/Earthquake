import { MockNumericPackageArgs, MockStringPackageArgs } from "../src/helpers/test-utils";
export declare const NUMBER_OF_MOCK_NUMERIC_SIGNERS = 10;
export declare const mockNumericPackageConfigs: MockNumericPackageArgs[];
export declare const mockNumericPackages: import("../src/wrappers/MockWrapper").MockDataPackageConfig[];
export declare const mockSignedDataPackageObjects: import("redstone-protocol").SignedDataPackagePlainObj[];
export declare const expectedNumericValues: any;
export declare const bytesDataPoints: {
    dataFeedId: string;
    value: string;
}[];
export declare const mockBytesPackageConfigs: MockStringPackageArgs[];
export declare const mockBytesPackages: import("../src/wrappers/MockWrapper").MockDataPackageConfig[];
export declare const expectedBytesValues: {
    ETH: string;
    BTC: string;
};
export declare const UNAUTHORISED_SIGNER_INDEX = 19;
export declare const getBlockTimestampMilliseconds: () => Promise<number>;
//# sourceMappingURL=tests-common.d.ts.map