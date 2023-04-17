import { Signer, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type { RedstoneDefaultsLib, RedstoneDefaultsLibInterface } from "../../../contracts/core/RedstoneDefaultsLib";
declare type RedstoneDefaultsLibConstructorParams = [signer?: Signer] | ConstructorParameters<typeof ContractFactory>;
export declare class RedstoneDefaultsLib__factory extends ContractFactory {
    constructor(...args: RedstoneDefaultsLibConstructorParams);
    deploy(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<RedstoneDefaultsLib>;
    getDeployTransaction(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): TransactionRequest;
    attach(address: string): RedstoneDefaultsLib;
    connect(signer: Signer): RedstoneDefaultsLib__factory;
    static readonly bytecode = "0x60566037600b82828239805160001a607314602a57634e487b7160e01b600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea2646970667358221220319dc6952c5cb841bfe520adcf116c0d80c801a4f3249633571f3616584c554164736f6c63430008040033";
    static readonly abi: {
        inputs: {
            internalType: string;
            name: string;
            type: string;
        }[];
        name: string;
        type: string;
    }[];
    static createInterface(): RedstoneDefaultsLibInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): RedstoneDefaultsLib;
}
export {};
//# sourceMappingURL=RedstoneDefaultsLib__factory.d.ts.map