module.exports = {
  networks: {
    compilers: {
      solc: {
        version: "0.8.6",
      },
    },
  },

  solc: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
    evmVersion: "istanbul",
  },
};
