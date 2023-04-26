import { ParamsForDryRunVerification } from "../wrappers/BaseWrapper";
export interface RequestPayloadWithDryRunParams extends ParamsForDryRunVerification {
    redstonePayload: string;
}
export declare const runDryRun: ({ functionName, contract, transaction, redstonePayload, }: RequestPayloadWithDryRunParams) => Promise<void>;
//# sourceMappingURL=run-dry-run.d.ts.map