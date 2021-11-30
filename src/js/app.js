// import * as Charger from '../../build/contracts/Charger.json'

// const Charge = require('../../build/contracts/Charger.json')
// const { Charger } = require('/home/snumbrikvolgo/ChargerProject/build/contracts/Charger.json');
// const { default: Charger } = await import('/home/snumbrikvolgo/ChargerProject/build/contracts/Charger.json', { assert: { type: "json" } })
App = {
  web3Provider: null,
  contracts: {},

  init: async function() {
    // Load chargers.
    $.getJSON('../chargers.json', function(data) {
      var chargersRow = $('#chargersRow');
      var chargerTemplate = $('#chargerTemplate');

      for (i = 0; i < data.length; i ++) {
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
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access...
        console.error("User denied account access")
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
    }
    // If no injected web3 instance is detected, fall back to Ganache
    else {
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    }
    web3 = new Web3(App.web3Provider);

    return App.initContract();
  },

  initContract: function() {
    document.getElementById("Res").innerHTML = "InitContract"
    $.getJSON('ChargersListing.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract
      var ChargersListArtifact = data;
      App.contracts.ChargersListing = TruffleContract(ChargersListArtifact);
      console.log(142);
      // Set the provider for our contract
      App.contracts.ChargersListing.setProvider(App.web3Provider);
      web3.eth.getAccounts(function(error, accounts) {
        if (error) {
          console.log(error);
        }
        var account = accounts[0];
        // $.getJSON('/home/snumbrikvolgo/ChargerProject/build/contracts/Charger.json', function(Charger) {
        //   console.log('hui')
        // });
        console.log(accounts);
        App.contracts.ChargersListing.deployed().then(function(instance) {
          var chargingInstance
          chargingInstance = instance;
          $.getJSON('../chargers.json', function(data) {
            for (i = 0; i < data.length; i ++) {
              if (chargingInstance.chargers(i) == '0x0000000000000000000000000000000000000000')
              {
              chargingInstance.addCharger(data[i].id, data[i].power, data[i].cableType, data[i].tariff, data[i].latitude, data[i].longitude, data[i].oracleAddress, {from: account})
              console.log(chargingInstance.getChargerInfo(i));
              }

            }
          });
        });
      });
    
      return App.markCharging();
    });

    return App.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '.btn-charge', App.handleCharging);
  },

  markCharging: function(ChargersIndexes, account) {
    var chargingInstance;
    App.contracts.ChargersListing.deployed().then(function(instance) {
      document.getElementById("Res").innerHTML = "markCharging";
      chargingInstance = instance;

      return chargingInstance.getAllChargersIndexes();
    }).then(function(ChargersIndexes) {
      console.log(ChargersIndexes)
      for (i = 0; i < ChargersIndexes.length; i++) { 
        if (chargingInstance.chargers(i) !== '0x0000000000000000000000000000000000000000') {
          console.log(chargingInstance.chargers(i))

          $('.panel-chargers').eq(i).find('button').text('Success').attr('disabled', false);
        }
      }
      // return true;
    }).catch(function(err) {
      console.log(err.message);
    });
  },

  handleCharging: function(event) {
    event.preventDefault();
    
    document.getElementById("ResultBad").innerHTML = null;
    var beginTime = document.getElementById("appt1").value;
    console.log(beginTime);
    var endTime = document.getElementById("appt2").value;
    console.log(endTime);

    var beginMinutes = (Date.parse(beginTime))/1000/300;
    var diffMinutes = (Date.parse(endTime) - Date.parse(beginTime))/1000/300;
    document.getElementById("Res").innerHTML = "HI"
    if(beginTime && endTime){
      if(diffMinutes<=0)
      {
        document.getElementById("ResultBad").innerHTML = "Contract wasn't made begin time more then end time";
        return false;
      }
    }
    else {
      document.getElementById("ResultBad").innerHTML = "Contract wasn't made not both times were passed";
      return false;
    }
    document.getElementById("Res").innerHTML = "HI after if";
    var chargeId = parseInt($(event.target).data('id'));

    var chargingInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];
      console.log(accounts[0]);
      document.getElementById("Res").innerHTML = "HI before deploy";
      App.contracts.ChargersListing.deployed().then(function(instance) {
        chargingInstance = instance;

        // Execute adopt as a transaction by sending account
        document.getElementById("Res").innerHTML = "Before deposit";
        // var p = chargingInstance.getAllChargersIndexes();
        console.log(chargingInstance.getCharger(chargeId));
        document.getElementById("Res").innerHTML = "Got all chargers indexes";
        // var Charger = require('../../build/contracts/Charger.json')
        // const fs = require('../../node_modules/fs/package.json');
        // const contract = JSON.parse(fs.readFileSync('../../build/contracts/Charger.json', 'utf8'));
        // var targetCharger = new web3.eth.Contract(contract.abi, chargingInstance.chargers(chargeId))
        return chargingInstance.getChargerRegisterDeposit(chargeId, beginMinutes,diffMinutes,0, {from: account});
      }).then(function(result) {
        console.log('hui')
        return App.markCharging();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});