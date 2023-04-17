import { Signer } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type { RedstoneConsumerBase, RedstoneConsumerBaseInterface } from "../../../contracts/core/RedstoneConsumerBase";
export declare class RedstoneConsumerBase__factory {
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
    static createInterface(): RedstoneConsumerBaseInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): RedstoneConsumerBase;
}
//# sourceMappingURL=RedstoneConsumerBase__factory.d.ts.map