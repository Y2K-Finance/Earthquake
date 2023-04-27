import type { BaseContract, BigNumber, BigNumberish, BytesLike, CallOverrides, ContractTransaction, Overrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../common";
export interface SampleRedstoneConsumerBytesMockInterface extends utils.Interface {
    functions: {
        "aggregateByteValues(uint256[])": FunctionFragment;
        "aggregateValues(uint256[])": FunctionFragment;
        "getAllMockAuthorised(address)": FunctionFragment;
        "getAllMockExceptLastOneAuthorised(address)": FunctionFragment;
        "getAuthorisedMockSignerIndex(address)": FunctionFragment;
        "getAuthorisedSignerIndex(address)": FunctionFragment;
        "getUniqueSignersThreshold()": FunctionFragment;
        "getValueSecurely(bytes32)": FunctionFragment;
        "latestSavedValue()": FunctionFragment;
        "saveOracleValueInContractStorage(bytes32)": FunctionFragment;
        "validateTimestamp(uint256)": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "aggregateByteValues" | "aggregateValues" | "getAllMockAuthorised" | "getAllMockExceptLastOneAuthorised" | "getAuthorisedMockSignerIndex" | "getAuthorisedSignerIndex" | "getUniqueSignersThreshold" | "getValueSecurely" | "latestSavedValue" | "saveOracleValueInContractStorage" | "validateTimestamp"): FunctionFragment;
    encodeFunctionData(functionFragment: "aggregateByteValues", values: [PromiseOrValue<BigNumberish>[]]): string;
    encodeFunctionData(functionFragment: "aggregateValues", values: [PromiseOrValue<BigNumberish>[]]): string;
    encodeFunctionData(functionFragment: "getAllMockAuthorised", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAllMockExceptLastOneAuthorised", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAuthorisedMockSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAuthorisedSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getUniqueSignersThreshold", values?: undefined): string;
    encodeFunctionData(functionFragment: "getValueSecurely", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "latestSavedValue", values?: undefined): string;
    encodeFunctionData(functionFragment: "saveOracleValueInContractStorage", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "validateTimestamp", values: [PromiseOrValue<BigNumberish>]): string;
    decodeFunctionResult(functionFragment: "aggregateByteValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "aggregateValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAllMockAuthorised", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAllMockExceptLastOneAuthorised", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedMockSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getUniqueSignersThreshold", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getValueSecurely", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "latestSavedValue", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "saveOracleValueInContractStorage", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "validateTimestamp", data: BytesLike): Result;
    events: {};
}
export interface SampleRedstoneConsumerBytesMock extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: SampleRedstoneConsumerBytesMockInterface;
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
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<[number]>;
        getValueSecurely(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<[BigNumber]>;
        latestSavedValue(overrides?: CallOverrides): Promise<[BigNumber]>;
        saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[void]>;
    };
    aggregateByteValues(calldataPointersForValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<string>;
    aggregateValues(calldataPointersToValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
    getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
    getValueSecurely(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
    latestSavedValue(overrides?: CallOverrides): Promise<BigNumber>;
    saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    callStatic: {
        aggregateByteValues(calldataPointersForValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<string>;
        aggregateValues(calldataPointersToValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
        getValueSecurely(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        latestSavedValue(overrides?: CallOverrides): Promise<BigNumber>;
        saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<void>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    };
    filters: {};
    estimateGas: {
        aggregateByteValues(calldataPointersForValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        aggregateValues(calldataPointersToValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<BigNumber>;
        getValueSecurely(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        latestSavedValue(overrides?: CallOverrides): Promise<BigNumber>;
        saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
    };
    populateTransaction: {
        aggregateByteValues(calldataPointersForValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
        aggregateValues(calldataPointersToValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getValueSecurely(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        latestSavedValue(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=SampleRedstoneConsumerBytesMock.d.ts.map