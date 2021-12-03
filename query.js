var data = require('./src/chargers.json');

var ChargersListing = artifacts.require("ChargersListing");

module.exports = function() {
    async function getOraclesAddresses() {
        var accounts;
        await web3.eth.getAccounts(function(err, res) { accounts = res; });
        return {
            first: accounts.slice(1, 1 + data.length),
            second: accounts[accounts.length - 1]
        };
    };

    async function addChargersFromJson() {
        var tmp = await getOraclesAddresses();
        var oraclesAddresses = tmp.first;
        var userAddress = tmp.second;

        var listing = await ChargersListing.deployed();
        console.log(await listing.getAllChargersIndexes());
        for (let i = 0; i < oraclesAddresses.length; i++) {
            listing.addCharger(
                data[i].id,
                data[i].power,
                data[i].cableType,
                data[i].tariff,
                data[i].latitude,
                data[i].longitude,
                oraclesAddresses[i]
            );
            console.log(data[i]);
        }
    };

    // NB! we hang out because web3 by default waits for new blocks to be mined after
    // transactions before return
    addChargersFromJson();
}