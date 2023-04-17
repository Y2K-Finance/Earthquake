import { Signer, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type { CustomErrors, CustomErrorsInterface } from "../../../contracts/price-feeds/CustomErrors";
declare type CustomErrorsConstructorParams = [signer?: Signer] | ConstructorParameters<typeof ContractFactory>;
export declare class CustomErrors__factory extends ContractFactory {
    constructor(...args: CustomErrorsConstructorParams);
    deploy(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<CustomErrors>;
    getDeployTransaction(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): TransactionRequest;
    attach(address: string): CustomErrors;
    connect(signer: Signer): CustomErrors__factory;
    static readonly bytecode = "0x60566037600b82828239805160001a607314602a57634e487b7160e01b600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea264697066735822122004647cd586bd9664af64899783dde38af608e551c02b181934e818911ad9be4d64736f6c63430008040033";
    static readonly abi: {
        inputs: {
            internalType: string;
            name: string;
            type: string;
        }[];
        name: string;
        type: string;
    }[];
    static createInterface(): CustomErrorsInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): CustomErrors;
}
export {};
//# sourceMappingURL=CustomErrors__factory.d.ts.map