/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type {
  AccessController,
  AccessControllerInterface,
} from "../../../../contracts/main/access/AccessController";

const _abi = [
  {
    inputs: [],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [],
    name: "CallerNotAdmin",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "bytes32",
        name: "previousAdminRole",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "bytes32",
        name: "newAdminRole",
        type: "bytes32",
      },
    ],
    name: "RoleAdminChanged",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "sender",
        type: "address",
      },
    ],
    name: "RoleGranted",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "sender",
        type: "address",
      },
    ],
    name: "RoleRevoked",
    type: "event",
  },
  {
    inputs: [],
    name: "DEFAULT_ADMIN_ROLE",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "STRATEGY_MANAGER_ROLE",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "SUPER_ADMIN_ROLE",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "VAULT_MANAGER_ROLE",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "VAULT_ROLE",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
    ],
    name: "getRoleAdmin",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "grantRole",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "hasRole",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "renounceRole",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "revokeRole",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_creatorAddress",
        type: "address",
      },
      {
        internalType: "address",
        name: "_strategyManagerAddress",
        type: "address",
      },
      {
        internalType: "address",
        name: "_vaultAddress",
        type: "address",
      },
    ],
    name: "setupInitialRoles",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "setupRole",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b5061001c600033610021565b6100cd565b61002b828261002f565b5050565b6000828152602081815260408083206001600160a01b038516845290915290205460ff1661002b576000828152602081815260408083206001600160a01b03851684529091529020805460ff191660011790556100893390565b6001600160a01b0316816001600160a01b0316837f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a45050565b6109da806100dc6000396000f3fe608060405234801561001057600080fd5b50600436106100cf5760003560e01c806391d148541161008c578063a217fddf11610066578063a217fddf146101f0578063abcbe0b2146101f8578063d547741f1461021f578063fa82ac761461023257600080fd5b806391d14854146101a3578063985ee8d0146101b657806398c4f1ac146101c957600080fd5b806301ffc9a7146100d4578063248a9ca3146100fc5780632f2ff15d1461012d57806336568abe146101425780634460bdd6146101555780635e5a24a41461017c575b600080fd5b6100e76100e2366004610787565b610245565b60405190151581526020015b60405180910390f35b61011f61010a3660046107b1565b60009081526020819052604090206001015490565b6040519081526020016100f3565b61014061013b3660046107e6565b61027c565b005b6101406101503660046107e6565b6102a6565b61011f7f7613a25ecc738585a232ad50a301178f12b3ba8887d13e138b523c4269c4768981565b61011f7fd1473398bb66596de5d1ea1fc8e303ff2ac23265adc9144b1b52065dc4f0934b81565b6100e76101b13660046107e6565b610329565b6101406101c4366004610812565b610352565b61011f7f31e0210044b4f6757ce6aa31f9c6e8d4896d24a755014887391a926c5224d95981565b61011f600081565b61011f7f4170d100a3a3728ae51207936ee755ecaa64a7f6e9383c642ab204a136f90b1b81565b61014061022d3660046107e6565b610422565b6101406102403660046107e6565b610447565b60006001600160e01b03198216637965db0b60e01b148061027657506301ffc9a760e01b6001600160e01b03198316145b92915050565b60008281526020819052604090206001015461029781610479565b6102a18383610486565b505050565b6001600160a01b038116331461031b5760405162461bcd60e51b815260206004820152602f60248201527f416363657373436f6e74726f6c3a2063616e206f6e6c792072656e6f756e636560448201526e103937b632b9903337b91039b2b63360891b60648201526084015b60405180910390fd5b610325828261050a565b5050565b6000918252602082815260408084206001600160a01b0393909316845291905290205460ff1690565b61035d600033610329565b61037a5760405163036c8cf960e11b815260040160405180910390fd5b6103a47f7613a25ecc738585a232ad50a301178f12b3ba8887d13e138b523c4269c476898461056f565b6103ce7f4170d100a3a3728ae51207936ee755ecaa64a7f6e9383c642ab204a136f90b1b8361056f565b6103f87f31e0210044b4f6757ce6aa31f9c6e8d4896d24a755014887391a926c5224d9598261056f565b6102a17fd1473398bb66596de5d1ea1fc8e303ff2ac23265adc9144b1b52065dc4f0934b8461056f565b60008281526020819052604090206001015461043d81610479565b6102a1838361050a565b610452600033610329565b61046f5760405163036c8cf960e11b815260040160405180910390fd5b610325828261056f565b6104838133610579565b50565b6104908282610329565b610325576000828152602081815260408083206001600160a01b03851684529091529020805460ff191660011790556104c63390565b6001600160a01b0316816001600160a01b0316837f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a45050565b6105148282610329565b15610325576000828152602081815260408083206001600160a01b0385168085529252808320805460ff1916905551339285917ff6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b9190a45050565b6103258282610486565b6105838282610329565b61032557610590816105d2565b61059b8360206105e4565b6040516020016105ac929190610879565b60408051601f198184030181529082905262461bcd60e51b8252610312916004016108ee565b60606102766001600160a01b03831660145b606060006105f3836002610937565b6105fe90600261094e565b67ffffffffffffffff81111561061657610616610961565b6040519080825280601f01601f191660200182016040528015610640576020820181803683370190505b509050600360fc1b8160008151811061065b5761065b610977565b60200101906001600160f81b031916908160001a905350600f60fb1b8160018151811061068a5761068a610977565b60200101906001600160f81b031916908160001a90535060006106ae846002610937565b6106b990600161094e565b90505b6001811115610731576f181899199a1a9b1b9c1cb0b131b232b360811b85600f16601081106106ed576106ed610977565b1a60f81b82828151811061070357610703610977565b60200101906001600160f81b031916908160001a90535060049490941c9361072a8161098d565b90506106bc565b5083156107805760405162461bcd60e51b815260206004820181905260248201527f537472696e67733a20686578206c656e67746820696e73756666696369656e746044820152606401610312565b9392505050565b60006020828403121561079957600080fd5b81356001600160e01b03198116811461078057600080fd5b6000602082840312156107c357600080fd5b5035919050565b80356001600160a01b03811681146107e157600080fd5b919050565b600080604083850312156107f957600080fd5b82359150610809602084016107ca565b90509250929050565b60008060006060848603121561082757600080fd5b610830846107ca565b925061083e602085016107ca565b915061084c604085016107ca565b90509250925092565b60005b83811015610870578181015183820152602001610858565b50506000910152565b7f416363657373436f6e74726f6c3a206163636f756e74200000000000000000008152600083516108b1816017850160208801610855565b7001034b99036b4b9b9b4b733903937b6329607d1b60179184019182015283516108e2816028840160208801610855565b01602801949350505050565b602081526000825180602084015261090d816040850160208701610855565b601f01601f19169190910160400192915050565b634e487b7160e01b600052601160045260246000fd5b808202811582820484141761027657610276610921565b8082018082111561027657610276610921565b634e487b7160e01b600052604160045260246000fd5b634e487b7160e01b600052603260045260246000fd5b60008161099c5761099c610921565b50600019019056fea264697066735822122086ee290a8b4762d60443c324f906b042a8695060be03465682c81ea6e577592264736f6c63430008140033";

type AccessControllerConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: AccessControllerConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class AccessController__factory extends ContractFactory {
  constructor(...args: AccessControllerConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: string }
  ): Promise<AccessController> {
    return super.deploy(overrides || {}) as Promise<AccessController>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: string }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): AccessController {
    return super.attach(address) as AccessController;
  }
  override connect(signer: Signer): AccessController__factory {
    return super.connect(signer) as AccessController__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): AccessControllerInterface {
    return new utils.Interface(_abi) as AccessControllerInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): AccessController {
    return new Contract(address, _abi, signerOrProvider) as AccessController;
  }
}
