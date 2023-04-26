import { Signer } from "ethers";
import { ScoreType } from "redstone-protocol";
import { BaseWrapper } from "./BaseWrapper";
export interface OnDemandRequestParams {
    signer: Signer;
    scoreType: ScoreType;
}
export declare class OnDemandRequestWrapper extends BaseWrapper {
    private readonly requestParams;
    private readonly nodeUrls;
    constructor(requestParams: OnDemandRequestParams, nodeUrls: string[]);
    getUnsignedMetadata(): string;
    dryRunToVerifyPayload(payloads: string[]): Promise<string>;
    getBytesDataForAppending(): Promise<string>;
}
//# sourceMappingURL=OnDemandRequestWrapper.d.ts.map