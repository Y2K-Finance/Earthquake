import type { BaseContract, BigNumber, BigNumberish, BytesLike, CallOverrides, ContractTransaction, Overrides, PayableOverrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result, EventFragment } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../../common";
export interface SampleSyntheticTokenInterface extends utils.Interface {
    functions: {
        "COLLATERAL_TOKEN()": FunctionFragment;
        "LIQUIDATION_BONUS()": FunctionFragment;
        "MAX_SOLVENCY()": FunctionFragment;
        "MIN_SOLVENCY()": FunctionFragment;
        "SOLVENCY_PRECISION()": FunctionFragment;
        "addCollateral()": FunctionFragment;
        "aggregateValues(uint256[])": FunctionFragment;
        "allowance(address,address)": FunctionFragment;
        "approve(address,uint256)": FunctionFragment;
        "asset()": FunctionFragment;
        "balanceOf(address)": FunctionFragment;
        "balanceValueOf(address)": FunctionFragment;
        "broker()": FunctionFragment;
        "burn(uint256)": FunctionFragment;
        "collateral(address)": FunctionFragment;
        "collateralOf(address)": FunctionFragment;
        "collateralValueOf(address)": FunctionFragment;
        "debt(address)": FunctionFragment;
        "debtOf(address)": FunctionFragment;
        "debtValueOf(address)": FunctionFragment;
        "decimals()": FunctionFragment;
        "decreaseAllowance(address,uint256)": FunctionFragment;
        "getAllMockAuthorised(address)": FunctionFragment;
        "getAllMockExceptLastOneAuthorised(address)": FunctionFragment;
        "getAuthorisedMockSignerIndex(address)": FunctionFragment;
        "getAuthorisedSignerIndex(address)": FunctionFragment;
        "getUniqueSignersThreshold()": FunctionFragment;
        "increaseAllowance(address,uint256)": FunctionFragment;
        "initialize(bytes32,string,string)": FunctionFragment;
        "liquidate(address,uint256)": FunctionFragment;
        "mint(uint256)": FunctionFragment;
        "name()": FunctionFragment;
        "owner()": FunctionFragment;
        "removeCollateral(uint256)": FunctionFragment;
        "renounceOwnership()": FunctionFragment;
        "solvencyOf(address)": FunctionFragment;
        "symbol()": FunctionFragment;
        "totalSupply()": FunctionFragment;
        "totalValue()": FunctionFragment;
        "transfer(address,uint256)": FunctionFragment;
        "transferFrom(address,address,uint256)": FunctionFragment;
        "transferOwnership(address)": FunctionFragment;
        "validateTimestamp(uint256)": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "COLLATERAL_TOKEN" | "LIQUIDATION_BONUS" | "MAX_SOLVENCY" | "MIN_SOLVENCY" | "SOLVENCY_PRECISION" | "addCollateral" | "aggregateValues" | "allowance" | "approve" | "asset" | "balanceOf" | "balanceValueOf" | "broker" | "burn" | "collateral" | "collateralOf" | "collateralValueOf" | "debt" | "debtOf" | "debtValueOf" | "decimals" | "decreaseAllowance" | "getAllMockAuthorised" | "getAllMockExceptLastOneAuthorised" | "getAuthorisedMockSignerIndex" | "getAuthorisedSignerIndex" | "getUniqueSignersThreshold" | "increaseAllowance" | "initialize" | "liquidate" | "mint" | "name" | "owner" | "removeCollateral" | "renounceOwnership" | "solvencyOf" | "symbol" | "totalSupply" | "totalValue" | "transfer" | "transferFrom" | "transferOwnership" | "validateTimestamp"): FunctionFragment;
    encodeFunctionData(functionFragment: "COLLATERAL_TOKEN", values?: undefined): string;
    encodeFunctionData(functionFragment: "LIQUIDATION_BONUS", values?: undefined): string;
    encodeFunctionData(functionFragment: "MAX_SOLVENCY", values?: undefined): string;
    encodeFunctionData(functionFragment: "MIN_SOLVENCY", values?: undefined): string;
    encodeFunctionData(functionFragment: "SOLVENCY_PRECISION", values?: undefined): string;
    encodeFunctionData(functionFragment: "addCollateral", values?: undefined): string;
    encodeFunctionData(functionFragment: "aggregateValues", values: [PromiseOrValue<BigNumberish>[]]): string;
    encodeFunctionData(functionFragment: "allowance", values: [PromiseOrValue<string>, PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "approve", values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "asset", values?: undefined): string;
    encodeFunctionData(functionFragment: "balanceOf", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "balanceValueOf", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "broker", values?: undefined): string;
    encodeFunctionData(functionFragment: "burn", values: [PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "collateral", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "collateralOf", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "collateralValueOf", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "debt", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "debtOf", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "debtValueOf", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "decimals", values?: undefined): string;
    encodeFunctionData(functionFragment: "decreaseAllowance", values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "getAllMockAuthorised", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAllMockExceptLastOneAuthorised", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAuthorisedMockSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAuthorisedSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getUniqueSignersThreshold", values?: undefined): string;
    encodeFunctionData(functionFragment: "increaseAllowance", values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "initialize", values: [
        PromiseOrValue<BytesLike>,
        PromiseOrValue<string>,
        PromiseOrValue<string>
    ]): string;
    encodeFunctionData(functionFragment: "liquidate", values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "mint", values: [PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "name", values?: undefined): string;
    encodeFunctionData(functionFragment: "owner", values?: undefined): string;
    encodeFunctionData(functionFragment: "removeCollateral", values: [PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "renounceOwnership", values?: undefined): string;
    encodeFunctionData(functionFragment: "solvencyOf", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "symbol", values?: undefined): string;
    encodeFunctionData(functionFragment: "totalSupply", values?: undefined): string;
    encodeFunctionData(functionFragment: "totalValue", values?: undefined): string;
    encodeFunctionData(functionFragment: "transfer", values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "transferFrom", values: [
        PromiseOrValue<string>,
        PromiseOrValue<string>,
        PromiseOrValue<BigNumberish>
    ]): string;
    encodeFunctionData(functionFragment: "transferOwnership", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "validateTimestamp", values: [PromiseOrValue<BigNumberish>]): string;
    decodeFunctionResult(functionFragment: "COLLATERAL_TOKEN", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "LIQUIDATION_BONUS", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "MAX_SOLVENCY", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "MIN_SOLVENCY", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "SOLVENCY_PRECISION", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "addCollateral", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "aggregateValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "allowance", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "approve", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "asset", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "balanceOf", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "balanceValueOf", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "broker", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "burn", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "collateral", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "collateralOf", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "collateralValueOf", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "debt", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "debtOf", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "debtValueOf", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "decimals", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "decreaseAllowance", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAllMockAuthorised", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAllMockExceptLastOneAuthorised", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedMockSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getUniqueSignersThreshold", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "increaseAllowance", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "initialize", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "liquidate", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "mint", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "name", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "removeCollateral", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "renounceOwnership", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "solvencyOf", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "symbol", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "totalSupply", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "totalValue", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "transfer", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "transferFrom", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "transferOwnership", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "validateTimestamp", data: BytesLike): Result;
    events: {
        "Approval(address,address,uint256)": EventFragment;
        "CollateralAdded(address,uint256,uint256)": EventFragment;
        "CollateralRemoved(address,uint256,uint256)": EventFragment;
        "OwnershipTransferred(address,address)": EventFragment;
        "Transfer(address,address,uint256)": EventFragment;
    };
    getEvent(nameOrSignatureOrTopic: "Approval"): EventFragment;
    getEvent(nameOrSignatureOrTopic: "CollateralAdded"): EventFragment;
    getEvent(nameOrSignatureOrTopic: "CollateralRemoved"): EventFragment;
    getEvent(nameOrSignatureOrTopic: "OwnershipTransferred"): EventFragment;
    getEvent(nameOrSignatureOrTopic: "Transfer"): EventFragment;
}
export interface ApprovalEventObject {
    owner: string;
    spender: string;
    value: BigNumber;
}
export declare type ApprovalEvent = TypedEvent<[
    string,
    string,
    BigNumber
], ApprovalEventObject>;
export declare type ApprovalEventFilter = TypedEventFilter<ApprovalEvent>;
export interface CollateralAddedEventObject {
    account: string;
    val: BigNumber;
    time: BigNumber;
}
export declare type CollateralAddedEvent = TypedEvent<[
    string,
    BigNumber,
    BigNumber
], CollateralAddedEventObject>;
export declare type CollateralAddedEventFilter = TypedEventFilter<CollateralAddedEvent>;
export interface CollateralRemovedEventObject {
    account: string;
    val: BigNumber;
    time: BigNumber;
}
export declare type CollateralRemovedEvent = TypedEvent<[
    string,
    BigNumber,
    BigNumber
], CollateralRemovedEventObject>;
export declare type CollateralRemovedEventFilter = TypedEventFilter<CollateralRemovedEvent>;
export interface OwnershipTransferredEventObject {
    previousOwner: string;
    newOwner: string;
}
export declare type OwnershipTransferredEvent = TypedEvent<[
    string,
    string
], OwnershipTransferredEventObject>;
export declare type OwnershipTransferredEventFilter = TypedEventFilter<OwnershipTransferredEvent>;
export interface TransferEventObject {
    from: string;
    to: string;
    value: BigNumber;
}
export declare type TransferEvent = TypedEvent<[
    string,
    string,
    BigNumber
], TransferEventObject>;
export declare type TransferEventFilter = TypedEventFilter<TransferEvent>;
export interface SampleSyntheticToken extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: SampleSyntheticTokenInterface;
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
        COLLATERAL_TOKEN(overrides?: CallOverrides): Promise<[string]>;
        LIQUIDATION_BONUS(overrides?: CallOverrides): Promise<[BigNumber]>;
        MAX_SOLVENCY(overrides?: CallOverrides): Promise<[BigNumber]>;
        MIN_SOLVENCY(overrides?: CallOverrides): Promise<[BigNumber]>;
        SOLVENCY_PRECISION(overrides?: CallOverrides): Promise<[BigNumber]>;
        addCollateral(overrides?: PayableOverrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<[BigNumber]>;
        allowance(owner: PromiseOrValue<string>, spender: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[BigNumber]>;
        approve(spender: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        asset(overrides?: CallOverrides): Promise<[string]>;
        balanceOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[BigNumber]>;
        balanceValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[BigNumber]>;
        broker(overrides?: CallOverrides): Promise<[string]>;
        burn(amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        collateral(arg0: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[BigNumber]>;
        collateralOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[BigNumber]>;
        collateralValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[BigNumber]>;
        debt(arg0: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[BigNumber]>;
        debtOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[BigNumber]>;
        debtValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[BigNumber]>;
        decimals(overrides?: CallOverrides): Promise<[number]>;
        decreaseAllowance(spender: PromiseOrValue<string>, subtractedValue: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<[number]>;
        increaseAllowance(spender: PromiseOrValue<string>, addedValue: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        initialize(asset_: PromiseOrValue<BytesLike>, name_: PromiseOrValue<string>, symbol_: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        liquidate(account: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        mint(amount: PromiseOrValue<BigNumberish>, overrides?: PayableOverrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        name(overrides?: CallOverrides): Promise<[string]>;
        owner(overrides?: CallOverrides): Promise<[string]>;
        removeCollateral(amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        renounceOwnership(overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        solvencyOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[BigNumber]>;
        symbol(overrides?: CallOverrides): Promise<[string]>;
        totalSupply(overrides?: CallOverrides): Promise<[BigNumber]>;
        totalValue(overrides?: CallOverrides): Promise<[BigNumber]>;
        transfer(recipient: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        transferFrom(sender: PromiseOrValue<string>, recipient: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        transferOwnership(newOwner: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[void]>;
    };
    COLLATERAL_TOKEN(overrides?: CallOverrides): Promise<string>;
    LIQUIDATION_BONUS(overrides?: CallOverrides): Promise<BigNumber>;
    MAX_SOLVENCY(overrides?: CallOverrides): Promise<BigNumber>;
    MIN_SOLVENCY(overrides?: CallOverrides): Promise<BigNumber>;
    SOLVENCY_PRECISION(overrides?: CallOverrides): Promise<BigNumber>;
    addCollateral(overrides?: PayableOverrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
    allowance(owner: PromiseOrValue<string>, spender: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
    approve(spender: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    asset(overrides?: CallOverrides): Promise<string>;
    balanceOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
    balanceValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
    broker(overrides?: CallOverrides): Promise<string>;
    burn(amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    collateral(arg0: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
    collateralOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
    collateralValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
    debt(arg0: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
    debtOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
    debtValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
    decimals(overrides?: CallOverrides): Promise<number>;
    decreaseAllowance(spender: PromiseOrValue<string>, subtractedValue: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
    increaseAllowance(spender: PromiseOrValue<string>, addedValue: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    initialize(asset_: PromiseOrValue<BytesLike>, name_: PromiseOrValue<string>, symbol_: PromiseOrValue<string>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    liquidate(account: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    mint(amount: PromiseOrValue<BigNumberish>, overrides?: PayableOverrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    name(overrides?: CallOverrides): Promise<string>;
    owner(overrides?: CallOverrides): Promise<string>;
    removeCollateral(amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    renounceOwnership(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    solvencyOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
    symbol(overrides?: CallOverrides): Promise<string>;
    totalSupply(overrides?: CallOverrides): Promise<BigNumber>;
    totalValue(overrides?: CallOverrides): Promise<BigNumber>;
    transfer(recipient: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    transferFrom(sender: PromiseOrValue<string>, recipient: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    transferOwnership(newOwner: PromiseOrValue<string>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    callStatic: {
        COLLATERAL_TOKEN(overrides?: CallOverrides): Promise<string>;
        LIQUIDATION_BONUS(overrides?: CallOverrides): Promise<BigNumber>;
        MAX_SOLVENCY(overrides?: CallOverrides): Promise<BigNumber>;
        MIN_SOLVENCY(overrides?: CallOverrides): Promise<BigNumber>;
        SOLVENCY_PRECISION(overrides?: CallOverrides): Promise<BigNumber>;
        addCollateral(overrides?: CallOverrides): Promise<void>;
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        allowance(owner: PromiseOrValue<string>, spender: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        approve(spender: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<boolean>;
        asset(overrides?: CallOverrides): Promise<string>;
        balanceOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        balanceValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        broker(overrides?: CallOverrides): Promise<string>;
        burn(amount: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        collateral(arg0: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        collateralOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        collateralValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        debt(arg0: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        debtOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        debtValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        decimals(overrides?: CallOverrides): Promise<number>;
        decreaseAllowance(spender: PromiseOrValue<string>, subtractedValue: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<boolean>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
        increaseAllowance(spender: PromiseOrValue<string>, addedValue: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<boolean>;
        initialize(asset_: PromiseOrValue<BytesLike>, name_: PromiseOrValue<string>, symbol_: PromiseOrValue<string>, overrides?: CallOverrides): Promise<void>;
        liquidate(account: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        mint(amount: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        name(overrides?: CallOverrides): Promise<string>;
        owner(overrides?: CallOverrides): Promise<string>;
        removeCollateral(amount: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        renounceOwnership(overrides?: CallOverrides): Promise<void>;
        solvencyOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        symbol(overrides?: CallOverrides): Promise<string>;
        totalSupply(overrides?: CallOverrides): Promise<BigNumber>;
        totalValue(overrides?: CallOverrides): Promise<BigNumber>;
        transfer(recipient: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<boolean>;
        transferFrom(sender: PromiseOrValue<string>, recipient: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<boolean>;
        transferOwnership(newOwner: PromiseOrValue<string>, overrides?: CallOverrides): Promise<void>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    };
    filters: {
        "Approval(address,address,uint256)"(owner?: PromiseOrValue<string> | null, spender?: PromiseOrValue<string> | null, value?: null): ApprovalEventFilter;
        Approval(owner?: PromiseOrValue<string> | null, spender?: PromiseOrValue<string> | null, value?: null): ApprovalEventFilter;
        "CollateralAdded(address,uint256,uint256)"(account?: null, val?: null, time?: null): CollateralAddedEventFilter;
        CollateralAdded(account?: null, val?: null, time?: null): CollateralAddedEventFilter;
        "CollateralRemoved(address,uint256,uint256)"(account?: null, val?: null, time?: null): CollateralRemovedEventFilter;
        CollateralRemoved(account?: null, val?: null, time?: null): CollateralRemovedEventFilter;
        "OwnershipTransferred(address,address)"(previousOwner?: PromiseOrValue<string> | null, newOwner?: PromiseOrValue<string> | null): OwnershipTransferredEventFilter;
        OwnershipTransferred(previousOwner?: PromiseOrValue<string> | null, newOwner?: PromiseOrValue<string> | null): OwnershipTransferredEventFilter;
        "Transfer(address,address,uint256)"(from?: PromiseOrValue<string> | null, to?: PromiseOrValue<string> | null, value?: null): TransferEventFilter;
        Transfer(from?: PromiseOrValue<string> | null, to?: PromiseOrValue<string> | null, value?: null): TransferEventFilter;
    };
    estimateGas: {
        COLLATERAL_TOKEN(overrides?: CallOverrides): Promise<BigNumber>;
        LIQUIDATION_BONUS(overrides?: CallOverrides): Promise<BigNumber>;
        MAX_SOLVENCY(overrides?: CallOverrides): Promise<BigNumber>;
        MIN_SOLVENCY(overrides?: CallOverrides): Promise<BigNumber>;
        SOLVENCY_PRECISION(overrides?: CallOverrides): Promise<BigNumber>;
        addCollateral(overrides?: PayableOverrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        allowance(owner: PromiseOrValue<string>, spender: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        approve(spender: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        asset(overrides?: CallOverrides): Promise<BigNumber>;
        balanceOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        balanceValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        broker(overrides?: CallOverrides): Promise<BigNumber>;
        burn(amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        collateral(arg0: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        collateralOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        collateralValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        debt(arg0: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        debtOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        debtValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        decimals(overrides?: CallOverrides): Promise<BigNumber>;
        decreaseAllowance(spender: PromiseOrValue<string>, subtractedValue: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<BigNumber>;
        increaseAllowance(spender: PromiseOrValue<string>, addedValue: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        initialize(asset_: PromiseOrValue<BytesLike>, name_: PromiseOrValue<string>, symbol_: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        liquidate(account: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        mint(amount: PromiseOrValue<BigNumberish>, overrides?: PayableOverrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        name(overrides?: CallOverrides): Promise<BigNumber>;
        owner(overrides?: CallOverrides): Promise<BigNumber>;
        removeCollateral(amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        renounceOwnership(overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        solvencyOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        symbol(overrides?: CallOverrides): Promise<BigNumber>;
        totalSupply(overrides?: CallOverrides): Promise<BigNumber>;
        totalValue(overrides?: CallOverrides): Promise<BigNumber>;
        transfer(recipient: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        transferFrom(sender: PromiseOrValue<string>, recipient: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        transferOwnership(newOwner: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
    };
    populateTransaction: {
        COLLATERAL_TOKEN(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        LIQUIDATION_BONUS(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        MAX_SOLVENCY(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        MIN_SOLVENCY(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        SOLVENCY_PRECISION(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        addCollateral(overrides?: PayableOverrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
        allowance(owner: PromiseOrValue<string>, spender: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        approve(spender: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        asset(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        balanceOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        balanceValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        broker(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        burn(amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        collateral(arg0: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        collateralOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        collateralValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        debt(arg0: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        debtOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        debtValueOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        decimals(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        decreaseAllowance(spender: PromiseOrValue<string>, subtractedValue: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        increaseAllowance(spender: PromiseOrValue<string>, addedValue: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        initialize(asset_: PromiseOrValue<BytesLike>, name_: PromiseOrValue<string>, symbol_: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        liquidate(account: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        mint(amount: PromiseOrValue<BigNumberish>, overrides?: PayableOverrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        name(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        owner(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        removeCollateral(amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        renounceOwnership(overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        solvencyOf(account: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        symbol(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        totalSupply(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        totalValue(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        transfer(recipient: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        transferFrom(sender: PromiseOrValue<string>, recipient: PromiseOrValue<string>, amount: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        transferOwnership(newOwner: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=SampleSyntheticToken.d.ts.map