pragma solidity ^0.5.8;

import "truffle/DeployedAddresses.sol";
import "../contracts/Charger.sol";

contract TestCharger {
    // Testing Charger all functions.
    // start from initialising new Charger with preset normal parameters.

    uint16 public power = 42;                                                   // in kW
    Charger.TypeOfCable cableType;
    uint public tariff = 13;                                                     // tariff is represented in wei per minute
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

    function testCalculateRequiredDeposit()
            public
        {
        // Test uses abi to check CalculateRequiredDeposit function.
        // Test fails if target function has incorrect calculating with normal input or doesn't raise error with bad input value.
        bool r;
        uint16 input = 0;
        (r, ) = address(this).call(abi.encodePacked(meta.calculateRequiredDeposit, input));
        // can use assert how alternative Assert.isFalse(r, "Calculate required deposit didn't stop with bad input values.");
        require(r==false, "Calculate required deposit didn't stop with bad input values.");
        input = 5;
        uint256 output = meta.calculateRequiredDeposit(input);
        require(output == input * 5 * tariff + block.gaslimit, "Calculate incorrect Required Deposit.");
    }

    function testSetIsWorking()
                public
        {
        // Test checks setIsWorking function.
        bool r;
        (r, ) = address(this).call(abi.encodePacked(meta.setIsWorking, false));
        require(r==false, "Charger can unauthorized set IsWorking to false.");
    }

    function testRegisterDeposit()
                public
        {
        // Test checks registerDeposit function.
        // Test fails if one of the input data is incorrect.
        bool r;
        uint startTime = block.timestamp / 300 + 100;
        uint16 durationInFiveMinutes = 0;
        uint64 secretSessionId = 1;
        (r, ) = address(this).call(abi.encodePacked(meta.registerDeposit, startTime, durationInFiveMinutes, secretSessionId));
        require(r==false, "Register Deposit with zero duration.");
        durationInFiveMinutes = 1;
        startTime = 0;
        (r, ) = address(this).call(abi.encodePacked(meta.registerDeposit, startTime, durationInFiveMinutes, secretSessionId));
        require(r==false, "Register Deposit with bad startTime.");
    }

}
