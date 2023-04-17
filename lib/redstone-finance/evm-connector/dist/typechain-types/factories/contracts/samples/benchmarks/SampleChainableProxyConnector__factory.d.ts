import { Signer, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../common";
import type { SampleChainableProxyConnector, SampleChainableProxyConnectorInterface } from "../../../../contracts/samples/benchmarks/SampleChainableProxyConnector";
declare type SampleChainableProxyConnectorConstructorParams = [signer?: Signer] | ConstructorParameters<typeof ContractFactory>;
export declare class SampleChainableProxyConnector__factory extends ContractFactory {
    constructor(...args: SampleChainableProxyConnectorConstructorParams);
    deploy(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<SampleChainableProxyConnector>;
    getDeployTransaction(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): TransactionRequest;
    attach(address: string): SampleChainableProxyConnector;
    connect(signer: Signer): SampleChainableProxyConnector__factory;
    static readonly bytecode = "0x608060405234801561001057600080fd5b50610b5e806100206000396000f3fe608060405234801561001057600080fd5b506004361061004c5760003560e01c806344b22fdd146100515780634db39f23146100a8578063c6062a68146100bb578063fabdf83614610110575b600080fd5b6100a661005f36600461080e565b600080547fffffffffffffffffffffffff00000000000000000000000000000000000000001673ffffffffffffffffffffffffffffffffffffffff92909216919091179055565b005b6100a66100b6366004610920565b610123565b6100a66100c936600461080e565b600180547fffffffffffffffffffffffff00000000000000000000000000000000000000001673ffffffffffffffffffffffffffffffffffffffff92909216919091179055565b6100a661011e366004610842565b6102f7565b60015473ffffffffffffffffffffffffffffffffffffffff161561021e57604051602481018290526000907f4db39f2300000000000000000000000000000000000000000000000000000000906044015b604080517fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe08184030181529190526020810180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff00000000000000000000000000000000000000000000000000000000909316929092179091526001549091506102199073ffffffffffffffffffffffffffffffffffffffff1682600061034b565b505050565b604051602481018290526000907f4db39f2300000000000000000000000000000000000000000000000000000000906044015b604080517fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe08184030181529190526020810180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff0000000000000000000000000000000000000000000000000000000090931692909217909152600080549192506102199173ffffffffffffffffffffffffffffffffffffffff1690839061034b565b60015473ffffffffffffffffffffffffffffffffffffffff161561033057600063fabdf83660e01b82604051602401610174919061099e565b600063fabdf83660e01b82604051602401610251919061099e565b60606000610358846103ec565b90506000808673ffffffffffffffffffffffffffffffffffffffff1685610380576000610382565b345b846040516103909190610982565b60006040518083038185875af1925050503d80600081146103cd576040519150601f19603f3d011682016040523d82523d6000602084013e6103d2565b606091505b50915091506103e18282610494565b979650505050505050565b805160609060006103fb61057c565b9050600061040982846109f5565b905036821115610445576040517f5796f78a00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6060604051905081815285602001848101826020015b8183101561047357825181526020928301920161045b565b50505082833603856020018301379190920181016020016040529392505050565b6060826105765781516104d3576040517f567fe27a00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60208201517f08c379a000000000000000000000000000000000000000000000000000000000148015610542576040517f0f7e827800000000000000000000000000000000000000000000000000000000815260448401906105399082906004016109e2565b60405180910390fd5b826040517ffd36fde300000000000000000000000000000000000000000000000000000000815260040161053991906109e2565b50919050565b6000806105876105e7565b905060006105948261071c565b61ffff1690506105a56002836109f5565b915060005b818110156105df5760006105bd8461076f565b90506105c981856109f5565b93505080806105d790610a91565b9150506105aa565b509092915050565b60006602ed57011e00007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601358116148061064f576040517fe7764c9e00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6000366029111561068c576040517f5796f78a00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd7360135600060096106c5600362ffffff85166109f5565b6106cf91906109f5565b9050366106dd6002836109f5565b1115610715576040517fc30a7bd700000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b9392505050565b60008061072a6020846109f5565b905036811115610766576040517f5796f78a00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b36033592915050565b600080600061077d846107ab565b9092509050604e61078f8260206109f5565b6107999084610a0d565b6107a391906109f5565b949350505050565b6000808080806107bc6041876109f5565b905060006107d56107ce6020846109f5565b3690610802565b8035945090506107e6816003610802565b62ffffff9490941697933563ffffffff16965092945050505050565b60006107158284610a4a565b60006020828403121561081f578081fd5b813573ffffffffffffffffffffffffffffffffffffffff81168114610715578182fd5b60006020808385031215610854578182fd5b823567ffffffffffffffff8082111561086b578384fd5b818501915085601f83011261087e578384fd5b81358181111561089057610890610af9565b8060051b6040517fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0603f830116810181811085821117156108d3576108d3610af9565b604052828152858101935084860182860187018a10156108f1578788fd5b8795505b838610156109135780358552600195909501949386019386016108f5565b5098975050505050505050565b600060208284031215610931578081fd5b5035919050565b60008151808452610950816020860160208601610a61565b601f017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0169290920160200192915050565b60008251610994818460208701610a61565b9190910192915050565b6020808252825182820181905260009190848201906040850190845b818110156109d6578351835292840192918401916001016109ba565b50909695505050505050565b6020815260006107156020830184610938565b60008219821115610a0857610a08610aca565b500190565b6000817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0483118215151615610a4557610a45610aca565b500290565b600082821015610a5c57610a5c610aca565b500390565b60005b83811015610a7c578181015183820152602001610a64565b83811115610a8b576000848401525b50505050565b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff821415610ac357610ac3610aca565b5060010190565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fdfea26469706673582212207c7b9894fc8365ea02cb844702379c00f3d440e82082dc73724829fd124ddf8364736f6c63430008040033";
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
        outputs: never[];
        stateMutability: string;
        type: string;
    })[];
    static createInterface(): SampleChainableProxyConnectorInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): SampleChainableProxyConnector;
}
export {};
//# sourceMappingURL=SampleChainableProxyConnector__factory.d.ts.map