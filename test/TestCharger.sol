pragma solidity ^0.5.8;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Charger.sol";

contract TestCharger {

    uint16 public power = 228;                                                    // in kW
    Charger.TypeOfCable cableType;
    uint public tariff = 42;                                                     // tariff is represented in wei per minute
    string public latitude = "55.423791";                                        // e.g. 55.423791
    string public longitude = "37.518223";                                       // e.g. 37.518223

    address private oracleAddress;
    address payable public ownerAddress;

    Charger meta = new Charger(power, cableType, tariff, latitude, longitude, oracleAddress, ownerAddress);

    function testInitCharger()
            public
        {
        (uint16 _power, Charger.TypeOfCable _cableType, uint _tariff, string memory _latitude, string memory _longitude, bool _isWorking) = meta.getInfo();

        require(power == _power, "Charger has bad init power.");
        require(tariff == _tariff, "Charger has bad init tariff.");
        require(keccak256(abi.encodePacked((latitude))) == keccak256(abi.encodePacked((_latitude))), "Charger has bad init latitude.");
        require(keccak256(abi.encodePacked((longitude))) == keccak256(abi.encodePacked((_longitude))), "Charger has bad init longitude.");
        require(cableType == _cableType, "Charger has bad init cableType.");
        require(_isWorking == true, "Charger has bad init isWorking.");
    }
    //TODO tests for Charger.registerDeposit, closeOrder, cancelOrder

    function testCalculateRequiredDeposit()
            public
        {
        bool r;
        (r, ) = address(this).call(abi.encodePacked(meta.calculateRequiredDeposit.selector));
        Assert.isFalse(r, "Calculate required deposit stopped with normal input values.");
    }

}
