var ChargersListing = artifacts.require("ChargersListing");

module.exports = function(deployer) {
    deployer.deploy(ChargersListing);
};