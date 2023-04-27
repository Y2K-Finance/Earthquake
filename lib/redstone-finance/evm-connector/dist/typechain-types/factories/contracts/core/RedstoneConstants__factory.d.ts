import { Signer, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type { RedstoneConstants, RedstoneConstantsInterface } from "../../../contracts/core/RedstoneConstants";
declare type RedstoneConstantsConstructorParams = [signer?: Signer] | ConstructorParameters<typeof ContractFactory>;
export declare class RedstoneConstants__factory extends ContractFactory {
    constructor(...args: RedstoneConstantsConstructorParams);
    deploy(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<RedstoneConstants>;
    getDeployTransaction(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): TransactionRequest;
    attach(address: string): RedstoneConstants;
    connect(signer: Signer): RedstoneConstants__factory;
    static readonly bytecode = "0x6080604052348015600f57600080fd5b50603f80601d6000396000f3fe6080604052600080fdfea2646970667358221220ba877f9705182d1df9f87499f420a811588acead94fe3242e62f8b1bb87188f064736f6c63430008040033";
    static readonly abi: {
        inputs: {
            internalType: string;
            name: string;
            type: string;
        }[];
        name: string;
        type: string;
    }[];
    static createInterface(): RedstoneConstantsInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): RedstoneConstants;
}
export {};
//# sourceMappingURL=RedstoneConstants__factory.d.ts.map