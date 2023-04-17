import type { BaseContract, BigNumber, BigNumberish, BytesLike, CallOverrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../common";
export interface RedstoneConsumerBytesBaseInterface extends utils.Interface {
    functions: {
        "aggregateByteValues(uint256[])": FunctionFragment;
        "aggregateValues(uint256[])": FunctionFragment;
        "getAuthorisedSignerIndex(address)": FunctionFragment;
        "getUniqueSignersThreshold()": FunctionFragment;
        "validateTimestamp(uint256)": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "aggregateByteValues" | "aggregateValues" | "getAuthorisedSignerIndex" | "getUniqueSignersThreshold" | "validateTimestamp"): FunctionFragment;
    encodeFunctionData(functionFragment: "aggregateByteValues", values: [PromiseOrValue<BigNumberish>[]]): string;
    encodeFunctionData(functionFragment: "aggregateValues", values: [PromiseOrValue<BigNumberish>[]]): string;
    encodeFunctionData(functionFragment: "getAuthorisedSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getUniqueSignersThreshold", values?: undefined): string;
    encodeFunctionData(functionFragment: "validateTimestamp", values: [PromiseOrValue<BigNumberish>]): string;
    decodeFunctionResult(functionFragment: "aggregateByteValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "aggregateValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getUniqueSignersThreshold", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "validateTimestamp", data: BytesLike): Result;
    events: {};
}
export interface RedstoneConsumerBytesBase extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: RedstoneConsumerBytesBaseInterface;
    queryFilter<TEvent extends TypedEvent>(event: TypedEventFilter<TEvent>, fromBlockOrBlockhash?: string | number | undefined, toBlock?: string | number | undefined): Promise<Array<TEvent>>;
    listeners<TEvent extends TypedEvent>(eventFilter?: TypedEventFilter<TEvent>): Array<TypedListener<TEvent>>;
    listeners(eventName?: string): Array<Listener>;
    removeAllListeners<TEvent extends TypedEvent>(eventFilter: TypedEventFilter<TEvent>): this;
    removeAllListeners(eventName?: string): this;
    off: OnEvent<this>;
    on: OnEvent<this>;
    once: OnEvent<this>;
    removeListener: OnEvent<this>;
    functions: {
        aggregateByteValues(calldataPointersForValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<[string]>;
        aggregateValues(calldataPointersToValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<[BigNumber] & {
            pointerToResultBytesInMemory: BigNumber;
        }>;
        getAuthorisedSignerIndex(receivedSigner: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<[number]>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[void]>;
    };
    aggregateByteValues(calldataPointersForValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<string>;
    aggregateValues(calldataPointersToValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
    getAuthorisedSignerIndex(receivedSigner: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
    validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    callStatic: {
        aggregateByteValues(calldataPointersForValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<string>;
        aggregateValues(calldataPointersToValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        getAuthorisedSignerIndex(receivedSigner: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    };
    filters: {};
    estimateGas: {
        aggregateByteValues(calldataPointersForValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        aggregateValues(calldataPointersToValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        getAuthorisedSignerIndex(receivedSigner: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<BigNumber>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
    };
    populateTransaction: {
        aggregateByteValues(calldataPointersForValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
        aggregateValues(calldataPointersToValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAuthorisedSignerIndex(receivedSigner: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=RedstoneConsumerBytesBase.d.ts.map