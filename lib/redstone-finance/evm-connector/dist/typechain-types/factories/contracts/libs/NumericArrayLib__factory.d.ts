import { Signer, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type { NumericArrayLib, NumericArrayLibInterface } from "../../../contracts/libs/NumericArrayLib";
declare type NumericArrayLibConstructorParams = [signer?: Signer] | ConstructorParameters<typeof ContractFactory>;
export declare class NumericArrayLib__factory extends ContractFactory {
    constructor(...args: NumericArrayLibConstructorParams);
    deploy(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<NumericArrayLib>;
    getDeployTransaction(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): TransactionRequest;
    attach(address: string): NumericArrayLib;
    connect(signer: Signer): NumericArrayLib__factory;
    static readonly bytecode = "0x60566037600b82828239805160001a607314602a57634e487b7160e01b600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea2646970667358221220bd018ef3da8741902c8b4baaecf153886cbfc584f23e2edfc2b1794205a0d79764736f6c63430008040033";
    static readonly abi: {
        inputs: never[];
        name: string;
        type: string;
    }[];
    static createInterface(): NumericArrayLibInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): NumericArrayLib;
}
export {};
//# sourceMappingURL=NumericArrayLib__factory.d.ts.map