const PuppyMint = artifacts.require("PuppyMint");

module.exports = function (deployer) {
  deployer.deploy(PuppyMint);
};
