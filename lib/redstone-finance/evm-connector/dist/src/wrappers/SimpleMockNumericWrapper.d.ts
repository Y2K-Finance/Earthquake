import { INumericDataPoint } from "redstone-protocol";
import { MockWrapper } from "./MockWrapper";
export interface SimpleNumericMockConfig {
    mockSignersCount: number;
    timestampMilliseconds?: number;
    dataPoints: INumericDataPoint[];
}
export declare class SimpleNumericMockWrapper extends MockWrapper {
    constructor(simpleNumericMockConfig: SimpleNumericMockConfig);
    getUnsignedMetadata(): string;
}
//# sourceMappingURL=SimpleMockNumericWrapper.d.ts.map