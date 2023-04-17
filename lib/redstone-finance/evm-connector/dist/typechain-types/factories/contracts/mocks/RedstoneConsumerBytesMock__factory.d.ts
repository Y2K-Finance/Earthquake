import { Signer, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type { RedstoneConsumerBytesMock, RedstoneConsumerBytesMockInterface } from "../../../contracts/mocks/RedstoneConsumerBytesMock";
declare type RedstoneConsumerBytesMockConstructorParams = [signer?: Signer] | ConstructorParameters<typeof ContractFactory>;
export declare class RedstoneConsumerBytesMock__factory extends ContractFactory {
    constructor(...args: RedstoneConsumerBytesMockConstructorParams);
    deploy(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<RedstoneConsumerBytesMock>;
    getDeployTransaction(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): TransactionRequest;
    attach(address: string): RedstoneConsumerBytesMock;
    connect(signer: Signer): RedstoneConsumerBytesMock__factory;
    static readonly bytecode = "0x608060405234801561001057600080fd5b50610bc3806100206000396000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c8063b24ebfcc1161005b578063b24ebfcc14610101578063d22158fa14610122578063f50b2efe14610135578063f90c49241461014a57600080fd5b806313bc58db1461008d5780633ce142f5146100b6578063429989f0146100db57806395262d9f146100ee575b600080fd5b6100a061009b366004610967565b610151565b6040516100ad9190610a6d565b60405180910390f35b6100c96100c4366004610933565b6102f1565b60405160ff90911681526020016100ad565b6100c96100e9366004610933565b610302565b6100c96100fc366004610933565b6107db565b61011461010f366004610967565b6107e6565b6040519081526020016100ad565b6100c9610130366004610933565b6107f9565b610148610143366004610a45565b610880565b005b60036100c9565b6060600082511161018e576040517f6c2325dc00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b3660006101db846000815181106101ce577f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b60200260200101516108c3565b91509150600082826040516101f1929190610a5d565b604051908190039020905060015b85518110156102b0573660006102478884815181106101ce577f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b9150915083828260405161025c929190610a5d565b60405180910390201461029b576040517fece458ec00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b505080806102a890610af6565b9150506101ff565b5082828080601f0160208091040260200160405190810160405280939291908181526020018383808284376000920191909152509298975050505050505050565b60006102fc826107db565b92915050565b600073f39fd6e51aad88f6f4ce6ab8827279cfffb9226673ffffffffffffffffffffffffffffffffffffffff8316141561033e57506000919050565b7370997970c51812dc3a010c7d01b50e0d17dc79c873ffffffffffffffffffffffffffffffffffffffff8316141561037857506001919050565b733c44cdddb6a900fa2b585dd299e03d12fa4293bc73ffffffffffffffffffffffffffffffffffffffff831614156103b257506002919050565b7390f79bf6eb2c4f870365e785982e1f101e93b90673ffffffffffffffffffffffffffffffffffffffff831614156103ec57506003919050565b7315d34aaf54267db7d7c367839aaf71a00a2c6a6573ffffffffffffffffffffffffffffffffffffffff8316141561042657506004919050565b739965507d1a55bcc2695c58ba16fb37d819b0a4dc73ffffffffffffffffffffffffffffffffffffffff8316141561046057506005919050565b73976ea74026e726554db657fa54763abd0c3a0aa973ffffffffffffffffffffffffffffffffffffffff8316141561049a57506006919050565b7314dc79964da2c08b23698b3d3cc7ca32193d995573ffffffffffffffffffffffffffffffffffffffff831614156104d457506007919050565b7323618e81e3f5cdf7f54c3d65f7fbc0abf5b21e8f73ffffffffffffffffffffffffffffffffffffffff8316141561050e57506008919050565b73a0ee7a142d267c1f36714e4a8f75612f20a7972073ffffffffffffffffffffffffffffffffffffffff8316141561054857506009919050565b73bcd4042de499d14e55001ccbb24a551f3b95409673ffffffffffffffffffffffffffffffffffffffff831614156105825750600a919050565b7371be63f3384f5fb98995898a86b02fb2426c578873ffffffffffffffffffffffffffffffffffffffff831614156105bc5750600b919050565b73fabb0ac9d68b0b445fb7357272ff202c5651694a73ffffffffffffffffffffffffffffffffffffffff831614156105f65750600c919050565b731cbd3b2770909d4e10f157cabc84c7264073c9ec73ffffffffffffffffffffffffffffffffffffffff831614156106305750600d919050565b73df3e18d64bc6a983f673ab319ccae4f1a57c709773ffffffffffffffffffffffffffffffffffffffff8316141561066a5750600e919050565b73cd3b766ccdd6ae721141f452c550ca635964ce7173ffffffffffffffffffffffffffffffffffffffff831614156106a45750600f919050565b732546bcd3c84621e976d8185a91a922ae77ecec3073ffffffffffffffffffffffffffffffffffffffff831614156106de57506010919050565b73bda5747bfd65f08deb54cb465eb87d40e51b197e73ffffffffffffffffffffffffffffffffffffffff8316141561071857506011919050565b73dd2fd4581271e230360230f9337d5c0430bf44c073ffffffffffffffffffffffffffffffffffffffff8316141561075257506012919050565b738626f6940e2eb28930efb4cef49b2d1f2c9c119973ffffffffffffffffffffffffffffffffffffffff8316141561078c57506013919050565b6040517fec459bc000000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff831660048201526024015b60405180910390fd5b60006102fc826107f9565b6000806107f283610151565b9392505050565b6000738626f6940e2eb28930efb4cef49b2d1f2c9c119973ffffffffffffffffffffffffffffffffffffffff83161415610877576040517fec459bc000000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff831660048201526024016107d2565b6102fc82610302565b6501812f2590c08110156108c0576040517f355b874300000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b50565b366000806108d18460801c90565b90506fffffffffffffffffffffffffffffffff8416366108f18284610ade565b1115610929576040517fb0e86e5100000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b9094909350915050565b600060208284031215610944578081fd5b813573ffffffffffffffffffffffffffffffffffffffff811681146107f2578182fd5b60006020808385031215610979578182fd5b823567ffffffffffffffff80821115610990578384fd5b818501915085601f8301126109a3578384fd5b8135818111156109b5576109b5610b5e565b8060051b6040517fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0603f830116810181811085821117156109f8576109f8610b5e565b604052828152858101935084860182860187018a1015610a16578788fd5b8795505b83861015610a38578035855260019590950194938601938601610a1a565b5098975050505050505050565b600060208284031215610a56578081fd5b5035919050565b8183823760009101908152919050565b6000602080835283518082850152825b81811015610a9957858101830151858201604001528201610a7d565b81811115610aaa5783604083870101525b50601f017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe016929092016040019392505050565b60008219821115610af157610af1610b2f565b500190565b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff821415610b2857610b28610b2f565b5060010190565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fdfea264697066735822122010230e843131196f4b9a3c2b6009d1d340d1c888b7d83fc0dc245971d4fe42cc64736f6c63430008040033";
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
    static createInterface(): RedstoneConsumerBytesMockInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): RedstoneConsumerBytesMock;
}
export {};
//# sourceMappingURL=RedstoneConsumerBytesMock__factory.d.ts.map