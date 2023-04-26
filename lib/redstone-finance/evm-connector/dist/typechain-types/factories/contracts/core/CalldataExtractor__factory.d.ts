import { Signer, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type { CalldataExtractor, CalldataExtractorInterface } from "../../../contracts/core/CalldataExtractor";
declare type CalldataExtractorConstructorParams = [signer?: Signer] | ConstructorParameters<typeof ContractFactory>;
export declare class CalldataExtractor__factory extends ContractFactory {
    constructor(...args: CalldataExtractorConstructorParams);
    deploy(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<CalldataExtractor>;
    getDeployTransaction(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): TransactionRequest;
    attach(address: string): CalldataExtractor;
    connect(signer: Signer): CalldataExtractor__factory;
    static readonly bytecode = "0x6080604052348015600f57600080fd5b50603f80601d6000396000f3fe6080604052600080fdfea2646970667358221220c8607b1c6c1bc59b48b6314f8f17a811bb982a9d2c005dc4b7c1058c94acda1664736f6c63430008040033";
    static readonly abi: {
        inputs: {
            internalType: string;
            name: string;
            type: string;
        }[];
        name: string;
        type: string;
    }[];
    static createInterface(): CalldataExtractorInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): CalldataExtractor;
}
export {};
//# sourceMappingURL=CalldataExtractor__factory.d.ts.map