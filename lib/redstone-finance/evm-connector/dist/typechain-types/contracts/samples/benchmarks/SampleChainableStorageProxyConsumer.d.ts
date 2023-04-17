import type { BaseContract, BigNumber, BytesLike, CallOverrides, ContractTransaction, Overrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../../common";
export interface SampleChainableStorageProxyConsumerInterface extends utils.Interface {
    functions: {
        "getComputationResult()": FunctionFragment;
        "processOracleValue(bytes32)": FunctionFragment;
        "processOracleValues(bytes32[])": FunctionFragment;
        "register(address)": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "getComputationResult" | "processOracleValue" | "processOracleValues" | "register"): FunctionFragment;
    encodeFunctionData(functionFragment: "getComputationResult", values?: undefined): string;
    encodeFunctionData(functionFragment: "processOracleValue", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "processOracleValues", values: [PromiseOrValue<BytesLike>[]]): string;
    encodeFunctionData(functionFragment: "register", values: [PromiseOrValue<string>]): string;
    decodeFunctionResult(functionFragment: "getComputationResult", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "processOracleValue", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "processOracleValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "register", data: BytesLike): Result;
    events: {};
}
export interface SampleChainableStorageProxyConsumer extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: SampleChainableStorageProxyConsumerInterface;
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
        getComputationResult(overrides?: CallOverrides): Promise<[BigNumber]>;
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        register(_nextContract: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
    };
    getComputationResult(overrides?: CallOverrides): Promise<BigNumber>;
    processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    register(_nextContract: PromiseOrValue<string>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    callStatic: {
        getComputationResult(overrides?: CallOverrides): Promise<BigNumber>;
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<void>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<void>;
        register(_nextContract: PromiseOrValue<string>, overrides?: CallOverrides): Promise<void>;
    };
    filters: {};
    estimateGas: {
        getComputationResult(overrides?: CallOverrides): Promise<BigNumber>;
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        register(_nextContract: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
    };
    populateTransaction: {
        getComputationResult(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        register(_nextContract: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=SampleChainableStorageProxyConsumer.d.ts.map