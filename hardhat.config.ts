import "@typechain/hardhat"
import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-ethers"
import "@openzeppelin/hardhat-upgrades"
import "hardhat-contract-sizer"
import "solidity-coverage"
import "hardhat-deploy"
import "hardhat-tracer";

import "hardhat-contract-sizer";

import dotenv from "dotenv"
dotenv.config({ path: ".env" })


export default {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      forking: {
        url: "https://rpc.berachain.com",
        enabled: true,
      },
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      }
    ],

  },
  mocha: {
    timeout: 600000,
  },
  paths: {
    deploy: "deploy",
    deployments: "deployments",
    imports: "imports",
  },
  typechain: {
    outDir: "types/",
    target: "ethers-v5",
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    only: [],
  }
}
