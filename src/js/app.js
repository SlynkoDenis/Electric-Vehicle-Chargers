App = {
    web3Provider: null,
    contracts: {},
    chargersAddresses: {},
    userAddress: '',

    init: async function() {
        $.getJSON('../chargers.json', function(data) {
            var chargersRow = $('#chargersRow');
            var chargerTemplate = $('#chargerTemplate');

            for (i = 0; i < data.length; i++) {
                chargerTemplate.find('.panel-title').text(data[i].name);
                chargerTemplate.find('img').attr('src', data[i].picture);
                chargerTemplate.find('.charge-power').text(data[i].power);
                chargerTemplate.find('.charge-cableType').text(data[i].cableType);
                chargerTemplate.find('.charge-location').text(data[i].location);
                chargerTemplate.find('.charge-tariff').text(data[i].tariff);
                chargerTemplate.find('.charge-latitude').text(data[i].latitude);
                chargerTemplate.find('.charge-longitude').text(data[i].longitude);
                chargerTemplate.find('.charge-oracleAddress').text(data[i].oracleAddress)
                chargerTemplate.find('.btn-charge').attr('data-id', data[i].id);
                chargerTemplate.find('calendar1').attr('name', data[i].id);
                chargerTemplate.find('calendar2').attr('name', data[i].id);

                chargersRow.append(chargerTemplate.html());
            }
        });
        return await App.initWeb3();
    },

    initWeb3: async function() {
        if (window.ethereum) {
            App.web3Provider = window.ethereum;
            try {
                // Request account access
                const accounts = await App.web3Provider.request({ method: 'eth_requestAccounts' });
                App.userAddress = accounts[0];
                console.log('User addess:', App.userAddress);
            } catch (error) {
                console.error('User denied account access:', error.message);
            }
        } else if (window.web3) {
            App.web3Provider = window.web3.currentProvider;
        } else {
            App.web3Provider = new Web3.providers.HttpProvider('http://127.0.0.1:7545');
        }
        web3 = new Web3(App.web3Provider);
        // TODO(slynkodenis): remove log before presentation; added only for self-check, version must be 1.6.1
        console.log('Web3 version:', web3.version);

        return await App.initContract();
    },

    initContract: async function() {
        await $.getJSON('ChargersListing.json', function(ChargersListArtifact) {
            App.contracts.ChargersListing = TruffleContract(ChargersListArtifact);
            App.contracts.ChargersListing.setProvider(App.web3Provider);
        });

        if (App.userAddress.length == 0) {
            App.userAddress = await web3.eth.getAccounts().then(function(accounts) {
                return accounts[0];
            }).catch(function(error) {
                console.log('Failed on call to getAccounts()');
                console.log(error.message);
                throw new Error(error.message);
            });
            console.log('User addess:', App.userAddress);
        }

        var listingInstance = await App.contracts.ChargersListing.deployed().then(function(instance) {
            return instance;
        }).catch(function(error) {
            console.log('Failed to get deployed ChargersListing');
            console.log(error.message);
            throw new Error(error.message);
        });
        App.chargersAddresses = await listingInstance.getAllChargers().then(function(chargers) {
            for (let i = 0; i < chargers.length; i++) {
                if (chargers[i] == '0x0000000000000000000000000000000000000000') {
                    console.log('Please use Chargers upload before the first app run');
                    $.getJSON('../chargers.json', function(data) {
                        console.log(data[i]);
                        listingInstance.addCharger(
                            data[i].id,
                            data[i].power,
                            data[i].cableType,
                            data[i].tariff,
                            data[i].latitude,
                            data[i].longitude,
                            data[i].oracleAddress, { from: App.userAddress }
                        ).catch(function(error) {
                            console.log('Failed to add a Charger with index', data[i].id);
                            console.log(error.message);
                        });
                    });
                }
            }
            return chargers;
        }).catch(function(error) {
            console.log('Failed to get addresses of chargers');
            console.log(error.message);
        });

        App.markCharging();
        return App.bindEvents();
    },

    bindEvents: function() {
        $(document).on('click', '.btn-charge', App.handleCharging);
    },

    markCharging: async function() {
        var chargingInstance = await App.contracts.ChargersListing.deployed();
        // TODO(slynkodenis): utilize App.chargersAddresses
        var chargersAddresses = await chargingInstance.getAllChargers().then(function(addresses) {
            return addresses;
        }).catch(function(error) {
            console.log('Failed to get addresses of chargers');
            console.log(error.message);
        });
        chargersAddresses.forEach(function(addr) {
            if (addr == '0x0000000000000000000000000000000000000000') {
                $('.panel-chargers').eq(i).find('button').text('Submit').attr('disabled', true);
            }
        });
    },

    handleCharging: function(event) {
        event.preventDefault();
        var chargeId = parseInt($(event.target).data('id'));
        document.getElementsByClassName('bad').item(chargeId).innerHTML = "";
        document.getElementsByClassName('good').item(chargeId).innerHTML = "";
        var beginTime = document.getElementsByClassName('calendar1').item(chargeId).value;
        console.log('User chose Charger with id', chargeId);

        console.log('Begin time:', beginTime);
        var endTime = document.getElementsByClassName('calendar2').item(chargeId).value;
        console.log('End time:', endTime);

        var beginMinutes = (Date.parse(beginTime)) / 1000 / 300;
        var diffMinutes = (Date.parse(endTime) - Date.parse(beginTime)) / 1000 / 300;
        if (beginTime && endTime) {
            if (diffMinutes <= 0) {
                document.getElementsByClassName('bad').item(chargeId).innerHTML = "Contract wasn't made: begin time is greater than end time";
                return false;
            }
        } else {
            document.getElementsByClassName('bad').item(chargeId).innerHTML = "Invalid time was provided";
            return false;
        }
        // var chargeId = parseInt($(event.target).data('id'));

        // TODO: add validation of App.userAddress (at least that it was specified)
        App.contracts.ChargersListing.deployed().then(function(chargingInstance) {
            return chargingInstance.getChargerRegisterDeposit(chargeId, beginMinutes, diffMinutes, 0, { from: App.userAddress });
        }).then(function(result) {
            console.log('depositOK')
            document.getElementsByClassName('bad').item(chargeId).innerHTML = "";
            document.getElementsByClassName("good").item(chargeId).innerHTML = "Successfully Registered";
            return App.markCharging();
        }).catch(function(err) {
            console.log(err.message);
        });
    }
};

$(function() {
    $(window).load(function() {
        App.init();
    });
});