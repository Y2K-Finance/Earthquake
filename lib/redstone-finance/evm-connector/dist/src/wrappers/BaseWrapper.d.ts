import { Contract, PopulatedTransaction } from "ethers";
export interface ParamsForDryRunVerification {
    functionName: string;
    contract: Contract;
    transaction: PopulatedTransaction;
}
export declare abstract class BaseWrapper {
    abstract getBytesDataForAppending(params?: ParamsForDryRunVerification): Promise<string>;
    overwriteEthersContract(contract: Contract): Contract;
    private overwritePopulateTranasction;
    private overwriteFunction;
}
//# sourceMappingURL=BaseWrapper.d.ts.map