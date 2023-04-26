import { Signer, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type { ProxyConnector, ProxyConnectorInterface } from "../../../contracts/core/ProxyConnector";
declare type ProxyConnectorConstructorParams = [signer?: Signer] | ConstructorParameters<typeof ContractFactory>;
export declare class ProxyConnector__factory extends ContractFactory {
    constructor(...args: ProxyConnectorConstructorParams);
    deploy(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ProxyConnector>;
    getDeployTransaction(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): TransactionRequest;
    attach(address: string): ProxyConnector;
    connect(signer: Signer): ProxyConnector__factory;
    static readonly bytecode = "0x6080604052348015600f57600080fd5b50603f80601d6000396000f3fe6080604052600080fdfea26469706673582212201699bf1ffa96e9a94c912366da77867681765ce6d9803c82d1099044b7b2ce3564736f6c63430008040033";
    static readonly abi: {
        inputs: {
            internalType: string;
            name: string;
            type: string;
        }[];
        name: string;
        type: string;
    }[];
    static createInterface(): ProxyConnectorInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): ProxyConnector;
}
export {};
//# sourceMappingURL=ProxyConnector__factory.d.ts.map