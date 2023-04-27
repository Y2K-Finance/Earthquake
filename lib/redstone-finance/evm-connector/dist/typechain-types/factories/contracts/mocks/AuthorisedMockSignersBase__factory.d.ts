import { Signer } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type { AuthorisedMockSignersBase, AuthorisedMockSignersBaseInterface } from "../../../contracts/mocks/AuthorisedMockSignersBase";
export declare class AuthorisedMockSignersBase__factory {
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
    static createInterface(): AuthorisedMockSignersBaseInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): AuthorisedMockSignersBase;
}
//# sourceMappingURL=AuthorisedMockSignersBase__factory.d.ts.map