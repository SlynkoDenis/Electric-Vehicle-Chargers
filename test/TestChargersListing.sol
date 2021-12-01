pragma solidity ^0.5.8;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ChargersListing.sol";
import "../contracts/Charger.sol";

contract TestChargersListing {
    // Testing ChargersListing all functions.
    // start from initialising new ChargersListing with preset normal parameters for first Charger.

    uint16 public power = 42;                                                    // in kW
    Charger.TypeOfCable cableType;
    uint public tariff = 13;                                                     // tariff is represented in wei per minute
    string public latitude = "55.423791";                                        // e.g. 55.423791
    string public longitude = "37.518223";                                       // e.g. 37.518223

    address private oracleAddress;
    address payable public ownerAddress;

    ChargersListing meta = new ChargersListing();

    function testAddChargersListing()
                public
        {
        // Test adding new Charger to ChargersListing using getChargerInfo function and check all parameters.
        // Test fails if init parameters aren't equal to current and status isWorking==false.
        meta.addCharger(0, power, cableType, tariff, latitude, longitude, oracleAddress);
        (uint16 _power, Charger.TypeOfCable _cableType, uint _tariff, string memory _latitude, string memory _longitude, bool _isWorking) = meta.getChargerInfo(0);

        require(power == _power, "Charger has bad init power.");
        require(tariff == _tariff, "Charger has bad init tariff.");
        require(keccak256(abi.encodePacked((latitude))) == keccak256(abi.encodePacked((_latitude))), "Charger has bad init latitude.");
        require(keccak256(abi.encodePacked((longitude))) == keccak256(abi.encodePacked((_longitude))), "Charger has bad init longitude.");
        require(cableType == _cableType, "Charger has bad init cableType.");
        require(_isWorking == true, "Charger has bad init isWorking.");
    }

    function testDeleteCharger()
                public
        {
        // Test deleting Charger by id.
        // Test fails if function doesn't delete Charger or can delete Charger with incorrect id.
        bool r;
        uint64 input = 666;
        (r, ) = address(this).call(abi.encodePacked(meta.deleteCharger, input));
        Assert.isFalse(r, "Delete Charger with incorrect id without errors.");
        input = 0;
        meta.deleteCharger(input);
        (r, ) = address(this).call(abi.encodePacked(meta.getChargerInfo, input));
        Assert.isFalse(r, "Didn't delete Charger.");
    }

}
