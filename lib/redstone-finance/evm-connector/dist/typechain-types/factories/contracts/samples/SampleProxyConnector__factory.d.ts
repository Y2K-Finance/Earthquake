import { Signer, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type { SampleProxyConnector, SampleProxyConnectorInterface } from "../../../contracts/samples/SampleProxyConnector";
declare type SampleProxyConnectorConstructorParams = [signer?: Signer] | ConstructorParameters<typeof ContractFactory>;
export declare class SampleProxyConnector__factory extends ContractFactory {
    constructor(...args: SampleProxyConnectorConstructorParams);
    deploy(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<SampleProxyConnector>;
    getDeployTransaction(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): TransactionRequest;
    attach(address: string): SampleProxyConnector;
    connect(signer: Signer): SampleProxyConnector__factory;
    static readonly bytecode = "0x608060405234801561001057600080fd5b5060405161001d9061005f565b604051809103906000f080158015610039573d6000803e3d6000fd5b50600080546001600160a01b0319166001600160a01b039290921691909117905561006c565b61190a8061106083390190565b610fe58061007b6000396000f3fe6080604052600436106100655760003560e01c8063893228441161004357806389322844146100bb578063d863a542146100d0578063f8382ebb146100f057600080fd5b806320981c0f1461006a57806381eb06531461007457806382c6ba28146100a6575b600080fd5b610072610110565b005b34801561008057600080fd5b5061009461008f366004610b00565b610259565b60405190815260200160405180910390f35b3480156100b257600080fd5b5061007261033a565b3480156100c757600080fd5b506100726103b8565b3480156100dc57600080fd5b506100726100eb366004610b18565b610432565b3480156100fc57600080fd5b5061007261010b366004610b18565b61056f565b6040805160048152602481019091526020810180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167f8e7a4120000000000000000000000000000000000000000000000000000000001790526000805461018c9073ffffffffffffffffffffffffffffffffffffffff1683836105b5565b90506000818060200190518101906101a49190610b39565b905080156101de576040517f99d0404800000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6000546102039073ffffffffffffffffffffffffffffffffffffffff168460016105b5565b9150818060200190518101906102199190610b39565b9050348114610254576040517f26d2b8a200000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b505050565b600080637a1202c860e01b8360405160240161027791815260200190565b604080517fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe08184030181529190526020810180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff0000000000000000000000000000000000000000000000000000000090931692909217909152600080549192509061031c9073ffffffffffffffffffffffffffffffffffffffff1683610656565b9050808060200190518101906103329190610b39565b949350505050565b6040805160048152602481019091526020810180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167f3c154daf000000000000000000000000000000000000000000000000000000001790526000546103b49073ffffffffffffffffffffffffffffffffffffffff1682610656565b5050565b6040805160048152602481019091526020810180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fc06a97cb000000000000000000000000000000000000000000000000000000001790526000546103b49073ffffffffffffffffffffffffffffffffffffffff1682610656565b600063351d31ab60e01b837fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff60405160240161046f929190610bb7565b604080517fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe08184030181529190526020810180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009093169290921790915260008054919250906105159073ffffffffffffffffffffffffffffffffffffffff1683836105b5565b905060008180602001905181019061052d9190610b39565b9050838114610568576040517f98d4901c00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5050505050565b600061057a83610259565b9050818114610254576040517f4983170000000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b606060006105c2846106e6565b90506000808673ffffffffffffffffffffffffffffffffffffffff16856105ea5760006105ec565b345b846040516105fa9190610b9b565b60006040518083038185875af1925050503d8060008114610637576040519150601f19603f3d011682016040523d82523d6000602084013e61063c565b606091505b509150915061064b828261078e565b979650505050505050565b60606000610663836106e6565b90506000808573ffffffffffffffffffffffffffffffffffffffff168360405161068d9190610b9b565b600060405180830381855afa9150503d80600081146106c8576040519150601f19603f3d011682016040523d82523d6000602084013e6106cd565b606091505b50915091506106dc828261078e565b9695505050505050565b805160609060006106f5610876565b905060006107038284610eab565b90503682111561073f576040517f5796f78a00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6060604051905081815285602001848101826020015b8183101561076d578251815260209283019201610755565b50505082833603856020018301379190920181016020016040529392505050565b6060826108705781516107cd576040517f567fe27a00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60208201517f08c379a00000000000000000000000000000000000000000000000000000000014801561083c576040517f0f7e82780000000000000000000000000000000000000000000000000000000081526044840190610833908290600401610e98565b60405180910390fd5b826040517ffd36fde30000000000000000000000000000000000000000000000000000000081526004016108339190610e98565b50919050565b6000806108816108e1565b9050600061088e82610a16565b61ffff16905061089f600283610eab565b915060005b818110156108d95760006108b784610a69565b90506108c38185610eab565b93505080806108d190610f47565b9150506108a4565b509092915050565b60006602ed57011e00007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe036013581161480610949576040517fe7764c9e00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60003660291115610986576040517f5796f78a00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd7360135600060096109bf600362ffffff8516610eab565b6109c99190610eab565b9050366109d7600283610eab565b1115610a0f576040517fc30a7bd700000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b9392505050565b600080610a24602084610eab565b905036811115610a60576040517f5796f78a00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b36033592915050565b6000806000610a7784610a9d565b9092509050604e610a89826020610eab565b610a939084610ec3565b6103329190610eab565b600080808080610aae604187610eab565b90506000610ac7610ac0602084610eab565b3690610af4565b803594509050610ad8816003610af4565b62ffffff9490941697933563ffffffff16965092945050505050565b6000610a0f8284610f00565b600060208284031215610b11578081fd5b5035919050565b60008060408385031215610b2a578081fd5b50508035926020909101359150565b600060208284031215610b4a578081fd5b5051919050565b60008151808452610b69816020860160208601610f17565b601f017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0169290920160200192915050565b60008251610bad818460208701610f17565b9190910192915050565b82815281602082015260e060408201526000610c5360e08301606c81527f6c6f6e675f737472696e675f616161616161616161616161616161616161616160208201527f61616161616161616161616161616161616161616161616161616161616161616040820181905260608201527f6161616161616161616161610000000000000000000000000000000000000000608082015260a00190565b8281036060840152610ce281606c81527f6c6f6e675f737472696e675f616161616161616161616161616161616161616160208201527f61616161616161616161616161616161616161616161616161616161616161616040820181905260608201527f6161616161616161616161610000000000000000000000000000000000000000608082015260a00190565b90508281036080840152610d7381606c81527f6c6f6e675f737472696e675f616161616161616161616161616161616161616160208201527f61616161616161616161616161616161616161616161616161616161616161616040820181905260608201527f6161616161616161616161610000000000000000000000000000000000000000608082015260a00190565b905082810360a0840152610e0481606c81527f6c6f6e675f737472696e675f616161616161616161616161616161616161616160208201527f61616161616161616161616161616161616161616161616161616161616161616040820181905260608201527f6161616161616161616161610000000000000000000000000000000000000000608082015260a00190565b83810360c0850152606c81527f6c6f6e675f737472696e675f616161616161616161616161616161616161616160208201527f61616161616161616161616161616161616161616161616161616161616161616040820181905260608201527f61616161616161616161616100000000000000000000000000000000000000006080820152905060a0810195945050505050565b602081526000610a0f6020830184610b51565b60008219821115610ebe57610ebe610f80565b500190565b6000817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0483118215151615610efb57610efb610f80565b500290565b600082821015610f1257610f12610f80565b500390565b60005b83811015610f32578181015183820152602001610f1a565b83811115610f41576000848401525b50505050565b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff821415610f7957610f79610f80565b5060010190565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fdfea26469706673582212209a2ad7799e5f1edec855af6946a046c3bc1cb84019f88943739767e356c55db064736f6c63430008040033608060405234801561001057600080fd5b506118ea806100206000396000f3fe6080604052600436106100e85760003560e01c80637a1202c81161008a578063c06a97cb11610059578063c06a97cb14610252578063d22158fa14610267578063f50b2efe14610287578063f90c4924146102a757600080fd5b80637a1202c8146101ec5780638e7a41201461020c57806395262d9f14610212578063b24ebfcc1461023257600080fd5b80633d60fee3116100c65780633d60fee314610169578063429989f0146101895780634f178e44146101a95780635ddf81ba146101d657600080fd5b8063351d31ab146100ed5780633c154daf146101205780633ce142f514610137575b600080fd5b3480156100f957600080fd5b5061010d61010836600461160f565b6102bb565b6040519081526020015b60405180910390f35b34801561012c57600080fd5b506101356102d2565b005b34801561014357600080fd5b5061015761015236600461152b565b610339565b60405160ff9091168152602001610117565b34801561017557600080fd5b506101356101843660046115f7565b61034a565b34801561019557600080fd5b506101576101a436600461152b565b610359565b3480156101b557600080fd5b506101c96101c436600461155f565b61082d565b60405161011791906116ee565b3480156101e257600080fd5b5061010d60005481565b3480156101f857600080fd5b5061010d6102073660046115f7565b610838565b3461010d565b34801561021e57600080fd5b5061015761022d36600461152b565b610843565b34801561023e57600080fd5b5061010d61024d36600461155f565b61084e565b34801561025e57600080fd5b50610135600080fd5b34801561027357600080fd5b5061015761028236600461152b565b610859565b34801561029357600080fd5b506101356102a23660046115f7565b6108e0565b3480156102b357600080fd5b50600a610157565b60006102c688610923565b98975050505050505050565b6040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152600c60248201527f54657374206d657373616765000000000000000000000000000000000000000060448201526064015b60405180910390fd5b600061034482610843565b92915050565b61035381610923565b60005550565b600073f39fd6e51aad88f6f4ce6ab8827279cfffb9226673ffffffffffffffffffffffffffffffffffffffff8316141561039557506000919050565b7370997970c51812dc3a010c7d01b50e0d17dc79c873ffffffffffffffffffffffffffffffffffffffff831614156103cf57506001919050565b733c44cdddb6a900fa2b585dd299e03d12fa4293bc73ffffffffffffffffffffffffffffffffffffffff8316141561040957506002919050565b7390f79bf6eb2c4f870365e785982e1f101e93b90673ffffffffffffffffffffffffffffffffffffffff8316141561044357506003919050565b7315d34aaf54267db7d7c367839aaf71a00a2c6a6573ffffffffffffffffffffffffffffffffffffffff8316141561047d57506004919050565b739965507d1a55bcc2695c58ba16fb37d819b0a4dc73ffffffffffffffffffffffffffffffffffffffff831614156104b757506005919050565b73976ea74026e726554db657fa54763abd0c3a0aa973ffffffffffffffffffffffffffffffffffffffff831614156104f157506006919050565b7314dc79964da2c08b23698b3d3cc7ca32193d995573ffffffffffffffffffffffffffffffffffffffff8316141561052b57506007919050565b7323618e81e3f5cdf7f54c3d65f7fbc0abf5b21e8f73ffffffffffffffffffffffffffffffffffffffff8316141561056557506008919050565b73a0ee7a142d267c1f36714e4a8f75612f20a7972073ffffffffffffffffffffffffffffffffffffffff8316141561059f57506009919050565b73bcd4042de499d14e55001ccbb24a551f3b95409673ffffffffffffffffffffffffffffffffffffffff831614156105d95750600a919050565b7371be63f3384f5fb98995898a86b02fb2426c578873ffffffffffffffffffffffffffffffffffffffff831614156106135750600b919050565b73fabb0ac9d68b0b445fb7357272ff202c5651694a73ffffffffffffffffffffffffffffffffffffffff8316141561064d5750600c919050565b731cbd3b2770909d4e10f157cabc84c7264073c9ec73ffffffffffffffffffffffffffffffffffffffff831614156106875750600d919050565b73df3e18d64bc6a983f673ab319ccae4f1a57c709773ffffffffffffffffffffffffffffffffffffffff831614156106c15750600e919050565b73cd3b766ccdd6ae721141f452c550ca635964ce7173ffffffffffffffffffffffffffffffffffffffff831614156106fb5750600f919050565b732546bcd3c84621e976d8185a91a922ae77ecec3073ffffffffffffffffffffffffffffffffffffffff8316141561073557506010919050565b73bda5747bfd65f08deb54cb465eb87d40e51b197e73ffffffffffffffffffffffffffffffffffffffff8316141561076f57506011919050565b73dd2fd4581271e230360230f9337d5c0430bf44c073ffffffffffffffffffffffffffffffffffffffff831614156107a957506012919050565b738626f6940e2eb28930efb4cef49b2d1f2c9c119973ffffffffffffffffffffffffffffffffffffffff831614156107e357506013919050565b6040517fec459bc000000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff83166004820152602401610330565b6060610344826109af565b600061034482610923565b600061034482610859565b6000610344826109ba565b6000738626f6940e2eb28930efb4cef49b2d1f2c9c119973ffffffffffffffffffffffffffffffffffffffff831614156108d7576040517fec459bc000000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff83166004820152602401610330565b61034482610359565b6501812f2590c0811015610920576040517f355b874300000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b50565b60408051600180825281830190925260009182919060208083019080368337019050509050828160008151811061096a57634e487b7160e01b600052603260045260246000fd5b60200260200101818152505061097f816109af565b60008151811061099f57634e487b7160e01b600052603260045260246000fd5b6020026020010151915050919050565b6060610344826109c5565b600061034482610bb8565b60606000825167ffffffffffffffff8111156109f157634e487b7160e01b600052604160045260246000fd5b604051908082528060200260200182016040528015610a1a578160200160208202803683370190505b5090506000835167ffffffffffffffff811115610a4757634e487b7160e01b600052604160045260246000fd5b604051908082528060200260200182016040528015610a70578160200160208202803683370190505b5090506000845167ffffffffffffffff811115610a9d57634e487b7160e01b600052604160045260246000fd5b604051908082528060200260200182016040528015610ad057816020015b6060815260200190600190039081610abb5790505b50905060005b8551811015610b3e5760408051600a808252610160820190925290602082016101408036833701905050828281518110610b2057634e487b7160e01b600052603260045260246000fd5b60200260200101819052508080610b3690611825565b915050610ad6565b506000610b49610cbc565b90506000610b5682610df1565b61ffff169050610b676002836117a5565b60405190925060005b82811015610bad576000610b878a89898989610e44565b9050610b9381866117a5565b945082604052508080610ba590611825565b915050610b70565b506102c68487611173565b6000815160001415610bf6576040517f9e198af900000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b610bff826112eb565b600060028351610c0f91906117bd565b905060028351610c1f919061185e565b610c9c576000610c8784610c3460018561180e565b81518110610c5257634e487b7160e01b600052603260045260246000fd5b6020026020010151858481518110610c7a57634e487b7160e01b600052603260045260246000fd5b6020026020010151611339565b9050610c946002826117bd565b949350505050565b82818151811061099f57634e487b7160e01b600052603260045260246000fd5b60006602ed57011e00007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe036013581161480610d24576040517fe7764c9e00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60003660291115610d61576040517f5796f78a00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd736013560006009610d9a600362ffffff85166117a5565b610da491906117a5565b905036610db26002836117a5565b1115610dea576040517fc30a7bd700000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b9392505050565b600080610dff6020846117a5565b905036811115610e3b576040517f5796f78a00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b36033592915050565b600080600080610e5385611345565b909250905060008080606081600d610e76610e6f6020896117a5565b8990611395565b610e8091906117a5565b90506000610e99610e9260688d6117a5565b36906113a1565b90506000610eb683610eac60418f6117a5565b610e9291906117a5565b9050610ec28382610ed5565b9350826020850120945081359650610f17565b604080518381526020818501810190925260009101838382377fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0019392505050565b610f288765ffffffffffff166108e0565b610f3c85610f3760418f6117a5565b6113ad565b9550610f4786610339565b60ff1699505050505050505060008060005b8481101561114057610f6c888583611443565b909350915060005b8c5181101561112d578c8181518110610f9d57634e487b7160e01b600052603260045260246000fd5b602002602001015184141561111b5760008b8281518110610fce57634e487b7160e01b600052603260045260246000fd5b60200260200101519050610fe781896001901b16151590565b15801561101e5750600a60ff168d838151811061101457634e487b7160e01b600052603260045260246000fd5b6020026020010151105b15611115578c828151811061104357634e487b7160e01b600052603260045260246000fd5b60200260200101805180919061105890611825565b81525050838b838151811061107d57634e487b7160e01b600052603260045260246000fd5b602002602001015160018f85815181106110a757634e487b7160e01b600052603260045260246000fd5b60200260200101516110b9919061180e565b815181106110d757634e487b7160e01b600052603260045260246000fd5b60209081029190910101526001881b81178c838151811061110857634e487b7160e01b600052603260045260246000fd5b6020026020010181815250505b5061112d565b8061112581611825565b915050610f74565b508061113881611825565b915050610f59565b5050508160208261115191906117a5565b61115b91906117d1565b61116690604e6117a5565b9998505050505050505050565b60606000835167ffffffffffffffff81111561119f57634e487b7160e01b600052604160045260246000fd5b6040519080825280602002602001820160405280156111c8578160200160208202803683370190505b509050600a60005b85518110156112e157818582815181106111fa57634e487b7160e01b600052603260045260246000fd5b6020026020010151101561126e5784818151811061122857634e487b7160e01b600052603260045260246000fd5b6020026020010151826040517f2b13aef5000000000000000000000000000000000000000000000000000000008152600401610330929190918252602082015260400190565b60006112a087838151811061129357634e487b7160e01b600052603260045260246000fd5b602002602001015161084e565b9050808483815181106112c357634e487b7160e01b600052603260045260246000fd5b602090810291909101015250806112d981611825565b9150506111d0565b5090949350505050565b8051602082016020820281019150805b8281101561133357815b8181101561132a578151815180821015611320578084528183525b5050602001611305565b506020016112fb565b50505050565b6000610dea82846117a5565b6000808080806113566041876117a5565b90506000611368610e926020846117a5565b8035945090506113798160036113a1565b62ffffff9490941697933563ffffffff16965092945050505050565b6000610dea82846117d1565b6000610dea828461180e565b60408051600080825260208083018085528690523685900380850135831a948401859052803560608501819052910135608084018190529193909260019060a0016020604051602081039080840390855afa158015611410573d6000803e3d6000fd5b50506040517fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe00151979650505050505050565b60008080611452604e876117a5565b9050600061147f6114786114676020896117a5565b6114728860016117a5565b90611395565b8390611339565b9050600061148d36836113a1565b80359960209091013598509650505050505050565b600082601f8301126114b2578081fd5b813567ffffffffffffffff8111156114cc576114cc61189e565b6114fd60207fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0601f84011601611732565b818152846020838601011115611511578283fd5b816020850160208301379081016020019190915292915050565b60006020828403121561153c578081fd5b813573ffffffffffffffffffffffffffffffffffffffff81168114610dea578182fd5b60006020808385031215611571578182fd5b823567ffffffffffffffff811115611587578283fd5b8301601f81018513611597578283fd5b80356115aa6115a582611781565b611732565b80828252848201915084840188868560051b87010111156115c9578687fd5b8694505b838510156115eb5780358352600194909401939185019185016115cd565b50979650505050505050565b600060208284031215611608578081fd5b5035919050565b600080600080600080600060e0888a031215611629578283fd5b8735965060208801359550604088013567ffffffffffffffff8082111561164e578485fd5b61165a8b838c016114a2565b965060608a013591508082111561166f578485fd5b61167b8b838c016114a2565b955060808a0135915080821115611690578485fd5b61169c8b838c016114a2565b945060a08a01359150808211156116b1578384fd5b6116bd8b838c016114a2565b935060c08a01359150808211156116d2578283fd5b506116df8a828b016114a2565b91505092959891949750929550565b6020808252825182820181905260009190848201906040850190845b818110156117265783518352928401929184019160010161170a565b50909695505050505050565b604051601f82017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe016810167ffffffffffffffff811182821017156117795761177961189e565b604052919050565b600067ffffffffffffffff82111561179b5761179b61189e565b5060051b60200190565b600082198211156117b8576117b8611872565b500190565b6000826117cc576117cc611888565b500490565b6000817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff048311821515161561180957611809611872565b500290565b60008282101561182057611820611872565b500390565b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82141561185757611857611872565b5060010190565b60008261186d5761186d611888565b500690565b634e487b7160e01b600052601160045260246000fd5b634e487b7160e01b600052601260045260246000fd5b634e487b7160e01b600052604160045260246000fdfea2646970667358221220fcbba462cc39e000b6357af59126ff50a6d625bb20587967215e83facd65343a64736f6c63430008040033";
    static readonly abi: ({
        inputs: never[];
        stateMutability: string;
        type: string;
        name?: undefined;
        outputs?: undefined;
    } | {
        inputs: {
            internalType: string;
            name: string;
            type: string;
        }[];
        name: string;
        type: string;
        stateMutability?: undefined;
        outputs?: undefined;
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
    static createInterface(): SampleProxyConnectorInterface;
    static connect(address: string, signerOrProvider: Signer | Provider): SampleProxyConnector;
}
export {};
//# sourceMappingURL=SampleProxyConnector__factory.d.ts.map