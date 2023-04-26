import { Signer } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type { AggregatorV3Interface, AggregatorV3InterfaceInterface } from "../../../../../../@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface";
export declare class AggregatorV3Interface__factory {
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
    static createInterface(): AggregatorV3InterfaceInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): AggregatorV3Interface;
}
//# sourceMappingURL=AggregatorV3Interface__factory.d.ts.map