var contract = artifacts.require("Charger");
var data = require('../src/chargers.json');

var ChargersListing = artifacts.require("ChargersListing");

module.exports = async function(callback) {
    var targetChargerIndex = 0;
    var startTime = 5463884;
    var durationInMinutes = 15;
    var secret = 42;

    async function getOraclesAddresses() {
        var accounts;
        await web3.eth.getAccounts(function(err, res) { accounts = res; });
        return accounts.slice(1, 1 + data.length)
    };

    async function chargerCloseOrder() {
        var oraclesAddresses = await getOraclesAddresses();

        var listing = await ChargersListing.deployed();
        var targetChargerAddress = await listing.chargers(targetChargerIndex);

        console.log('Reporting to Charger #%d on address %s from address %s',
            targetChargerIndex,
            targetChargerAddress,
            oraclesAddresses[targetChargerIndex]);

        var chargerInstance = await contract.at(targetChargerAddress);
        res = chargerInstance.closeOrder(
            startTime,
            durationInMinutes,
            secret, { from: oraclesAddresses[targetChargerIndex] }
        );
    };

    chargerCloseOrder();
}
