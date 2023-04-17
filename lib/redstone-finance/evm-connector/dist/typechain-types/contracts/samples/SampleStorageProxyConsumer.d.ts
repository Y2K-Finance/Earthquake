import type { BaseContract, BigNumber, BigNumberish, BytesLike, CallOverrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../common";
export interface SampleStorageProxyConsumerInterface extends utils.Interface {
    functions: {
        "checkOracleValue(bytes32,uint256)": FunctionFragment;
        "checkOracleValues(bytes32[],uint256[])": FunctionFragment;
        "getOracleValue(bytes32)": FunctionFragment;
        "getOracleValues(bytes32[])": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "checkOracleValue" | "checkOracleValues" | "getOracleValue" | "getOracleValues"): FunctionFragment;
    encodeFunctionData(functionFragment: "checkOracleValue", values: [PromiseOrValue<BytesLike>, PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "checkOracleValues", values: [PromiseOrValue<BytesLike>[], PromiseOrValue<BigNumberish>[]]): string;
    encodeFunctionData(functionFragment: "getOracleValue", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "getOracleValues", values: [PromiseOrValue<BytesLike>[]]): string;
    decodeFunctionResult(functionFragment: "checkOracleValue", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "checkOracleValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getOracleValue", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getOracleValues", data: BytesLike): Result;
    events: {};
}
export interface SampleStorageProxyConsumer extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: SampleStorageProxyConsumerInterface;
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
        checkOracleValue(dataFeedId: PromiseOrValue<BytesLike>, expectedValue: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[void]>;
        checkOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], expectedValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<[void]>;
        getOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<[BigNumber]>;
        getOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<[BigNumber[]]>;
    };
    checkOracleValue(dataFeedId: PromiseOrValue<BytesLike>, expectedValue: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    checkOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], expectedValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<void>;
    getOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
    getOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<BigNumber[]>;
    callStatic: {
        checkOracleValue(dataFeedId: PromiseOrValue<BytesLike>, expectedValue: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        checkOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], expectedValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<void>;
        getOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        getOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<BigNumber[]>;
    };
    filters: {};
    estimateGas: {
        checkOracleValue(dataFeedId: PromiseOrValue<BytesLike>, expectedValue: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
        checkOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], expectedValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        getOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        getOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<BigNumber>;
    };
    populateTransaction: {
        checkOracleValue(dataFeedId: PromiseOrValue<BytesLike>, expectedValue: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        checkOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], expectedValues: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=SampleStorageProxyConsumer.d.ts.map