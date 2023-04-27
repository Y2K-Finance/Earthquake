import { Signer } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type { RedstoneConsumerNumericBase, RedstoneConsumerNumericBaseInterface } from "../../../contracts/core/RedstoneConsumerNumericBase";
export declare class RedstoneConsumerNumericBase__factory {
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
    static createInterface(): RedstoneConsumerNumericBaseInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): RedstoneConsumerNumericBase;
}
//# sourceMappingURL=RedstoneConsumerNumericBase__factory.d.ts.map