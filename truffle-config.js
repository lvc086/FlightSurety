var HDWalletProvider = require("@truffle/hdwallet-provider");
var mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat"
const infuraKey = "v3/12e8d56547c1422aaf3d12f28b43e632";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '*',
      gas: 4500000,
      gasPrice: 10000000000
    },
    rinkeby: {
      provider: function() { 
       return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/"+infuraKey);

      },
      gas: 4500000,
      gasPrice: 10000000000,
      network_id: 4
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
      //version: "^0.5"
    }
  }
};