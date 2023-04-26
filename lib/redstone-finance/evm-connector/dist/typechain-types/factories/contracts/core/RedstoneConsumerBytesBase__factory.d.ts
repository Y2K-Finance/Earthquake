import { Signer } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type { RedstoneConsumerBytesBase, RedstoneConsumerBytesBaseInterface } from "../../../contracts/core/RedstoneConsumerBytesBase";
export declare class RedstoneConsumerBytesBase__factory {
    static readonly abi: ({
        inputs: {
            internalType: string;
            name: string;
            type: string;
        }[];
        name: string;
        type: string;
        outputs?: undefined;
        stateMutability?: undefined;
    } | {
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
    })[];
    static createInterface(): RedstoneConsumerBytesBaseInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): RedstoneConsumerBytesBase;
}
//# sourceMappingURL=RedstoneConsumerBytesBase__factory.d.ts.map