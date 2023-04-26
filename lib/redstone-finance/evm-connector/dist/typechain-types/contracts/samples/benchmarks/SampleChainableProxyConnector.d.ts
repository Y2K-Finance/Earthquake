import type { BaseContract, BigNumber, BytesLike, CallOverrides, ContractTransaction, Overrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../../common";
export interface SampleChainableProxyConnectorInterface extends utils.Interface {
    functions: {
        "processOracleValue(bytes32)": FunctionFragment;
        "processOracleValues(bytes32[])": FunctionFragment;
        "registerConsumer(address)": FunctionFragment;
        "registerNextConnector(address)": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "processOracleValue" | "processOracleValues" | "registerConsumer" | "registerNextConnector"): FunctionFragment;
    encodeFunctionData(functionFragment: "processOracleValue", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "processOracleValues", values: [PromiseOrValue<BytesLike>[]]): string;
    encodeFunctionData(functionFragment: "registerConsumer", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "registerNextConnector", values: [PromiseOrValue<string>]): string;
    decodeFunctionResult(functionFragment: "processOracleValue", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "processOracleValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "registerConsumer", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "registerNextConnector", data: BytesLike): Result;
    events: {};
}
export interface SampleChainableProxyConnector extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: SampleChainableProxyConnectorInterface;
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
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        registerConsumer(_sampleProxyConnectorConsumer: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        registerNextConnector(_sampleProxyConnector: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
    };
    processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    registerConsumer(_sampleProxyConnectorConsumer: PromiseOrValue<string>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    registerNextConnector(_sampleProxyConnector: PromiseOrValue<string>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    callStatic: {
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<void>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<void>;
        registerConsumer(_sampleProxyConnectorConsumer: PromiseOrValue<string>, overrides?: CallOverrides): Promise<void>;
        registerNextConnector(_sampleProxyConnector: PromiseOrValue<string>, overrides?: CallOverrides): Promise<void>;
    };
    filters: {};
    estimateGas: {
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        registerConsumer(_sampleProxyConnectorConsumer: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        registerNextConnector(_sampleProxyConnector: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
    };
    populateTransaction: {
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        registerConsumer(_sampleProxyConnectorConsumer: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        registerNextConnector(_sampleProxyConnector: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=SampleChainableProxyConnector.d.ts.map