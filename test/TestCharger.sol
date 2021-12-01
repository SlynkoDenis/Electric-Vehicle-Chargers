pragma solidity ^0.5.8;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Charger.sol";

contract TestCharger {
    // Testing Charger all functions.
    // start from initialising new Charger with preset normal parameters.
    uint16 public power = 228;                                                   // in kW
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
        // Test initialising Charger using getInfo function and check all parameters.
        // Test fails if init parameters aren't equal to current and status isWorking==false.
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
        // Test uses selector to check CalculateRequiredDeposit function.
        // Test fails if target function raises error with normal input or doesn't raise with bad input value.
        bool r;
        (r, ) = address(this).call(abi.encodePacked(meta.calculateRequiredDeposit.selector));
        Assert.isFalse(r, "Calculate required deposit stopped with normal input values.");
    }

}
