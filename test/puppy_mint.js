const PuppyMint = artifacts.require("PuppyMint");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("PuppyMint", function (/* accounts */) {
  it("should assert true", async function () {
    const contract = await PuppyMint.deployed();
  });
});