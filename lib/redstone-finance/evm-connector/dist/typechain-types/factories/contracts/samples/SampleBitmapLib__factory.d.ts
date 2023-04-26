import { Signer, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type { SampleBitmapLib, SampleBitmapLibInterface } from "../../../contracts/samples/SampleBitmapLib";
declare type SampleBitmapLibConstructorParams = [signer?: Signer] | ConstructorParameters<typeof ContractFactory>;
export declare class SampleBitmapLib__factory extends ContractFactory {
    constructor(...args: SampleBitmapLibConstructorParams);
    deploy(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<SampleBitmapLib>;
    getDeployTransaction(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): TransactionRequest;
    attach(address: string): SampleBitmapLib;
    connect(signer: Signer): SampleBitmapLib__factory;
    static readonly bytecode = "0x608060405234801561001057600080fd5b5060eb8061001f6000396000f3fe6080604052348015600f57600080fd5b506004361060325760003560e01c80635aace7df1460375780637160c362146059575b600080fd5b604660423660046095565b6077565b6040519081526020015b60405180910390f35b606860643660046095565b6087565b60405190151581526020016050565b60006001821b83175b9392505050565b60006001821b831615156080565b6000806040838503121560a6578182fd5b5050803592602090910135915056fea264697066735822122091e2727285a9a36e7c2bec1d2ca7cef3cb9f33d811274e29853b006cb7aa5b5364736f6c63430008040033";
    static readonly abi: {
        inputs: {
            internalType: string;
            name: string;
            type: string;
        }[];
        name: string;
        outputs: {
            internalType: string;
            name: string;
            type: string;
        }[];
        stateMutability: string;
        type: string;
    }[];
    static createInterface(): SampleBitmapLibInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): SampleBitmapLib;
}
export {};
//# sourceMappingURL=SampleBitmapLib__factory.d.ts.map