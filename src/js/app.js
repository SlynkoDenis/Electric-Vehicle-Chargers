// import * as Charger from '../../build/contracts/Charger.json'

// const Charge = require('../../build/contracts/Charger.json')
// const { Charger } = require('/home/snumbrikvolgo/ChargerProject/build/contracts/Charger.json');
// const { default: Charger } = await import('/home/snumbrikvolgo/ChargerProject/build/contracts/Charger.json', { assert: { type: "json" } })
App = {
  web3Provider: null,
  contracts: {},

  init: async function() {
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
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access...
        console.error("User denied account access")
      }
    }
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
    }
    else {
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    }
    web3 = new Web3(App.web3Provider);

    return App.initContract();
  },

  initContract: function() {
    $.getJSON('ChargersListing.json', function(data) {
      var ChargersListArtifact = data;
      App.contracts.ChargersListing = TruffleContract(ChargersListArtifact);
      App.contracts.ChargersListing.setProvider(App.web3Provider);
      web3.eth.getAccounts(function(error, accounts) {
        if (error) {
          console.log(error);
        }
        var account = accounts[0];
        App.contracts.ChargersListing.deployed().then(function(instance) {
          var chargingInstance
          chargingInstance = instance;
          chargingInstance.getAllChargers().then(function(chargers){
            for (let i = 0; i < chargers.length; i ++){
              if (chargers[i] == '0x0000000000000000000000000000000000000000')
              {
                $.getJSON('../chargers.json', function(data) {
                    console.log(data[i])
                    chargingInstance.addCharger(data[i].id, data[i].power, data[i].cableType, data[i].tariff, data[i].latitude, data[i].longitude, data[i].oracleAddress, {from: account})       
                });
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
      chargingInstance = instance;
      return chargingInstance.getAllChargersIndexes();
    }).then(function(ChargersIndexes) {
      console.log(ChargersIndexes)
      for (let i = 0; i < ChargersIndexes.length; i++) {
        chargingInstance.chargers(i).then(function(ch){
          if (ch == '0x0000000000000000000000000000000000000000') {
            $('.panel-chargers').eq(i).find('button').text('Submit').attr('disabled', true);
          }
        });
      }
    }).catch(function(err) {
      console.log(err.message);
    });
  },

  handleCharging: function(event) {
    event.preventDefault();
    var chargeId = parseInt($(event.target).data('id'));
    document.getElementsByClassName('bad').item(chargeId).innerHTML = "";
    document.getElementsByClassName("good").item(chargeId).innerHTML = "";
    var beginTime = document.getElementsByClassName('calendar1').item(chargeId).value;
    console.log(chargeId);

    console.log(beginTime);
    var endTime = document.getElementsByClassName('calendar2').item(chargeId).value;
    console.log(endTime);

    var beginMinutes = (Date.parse(beginTime))/1000/300;
    var diffMinutes = (Date.parse(endTime) - Date.parse(beginTime))/1000/300;
    if(beginTime && endTime){
      if(diffMinutes<=0)
      {
        document.getElementsByClassName('bad').item(chargeId).innerHTML = "Contract wasn't made begin time more then end time";
        return false;
      }
    }
    else {
      document.getElementsByClassName('bad').item(chargeId).innerHTML = "Contract wasn't made begin time more then end time";
      return false;
    }
    // var chargeId = parseInt($(event.target).data('id'));
    var chargingInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];
      console.log(accounts[0]);
      App.contracts.ChargersListing.deployed().then(function(instance) {
        chargingInstance = instance;
        return chargingInstance.getChargerRegisterDeposit(chargeId, beginMinutes,diffMinutes,0, {from: account});
      }).then(function(result) {
        console.log('depositOK')
        document.getElementsByClassName('bad').item(chargeId).innerHTML = "";
        document.getElementsByClassName("good").item(chargeId).innerHTML = "Successfully Registered";
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