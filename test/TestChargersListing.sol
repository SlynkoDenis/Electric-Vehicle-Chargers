pragma solidity ^0.5.8;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ChargersListing.sol";
import "../contracts/Charger.sol";

contract TestChargersListing {

    uint16 public power = 228;                                                    // in kW
    Charger.TypeOfCable cableType;
    uint public tariff = 42;                                                     // tariff is represented in wei per minute
    string public latitude = "55.423791";                                        // e.g. 55.423791
    string public longitude = "37.518223";                                       // e.g. 37.518223

    address private oracleAddress;
    address payable public ownerAddress;

    ChargersListing meta = new ChargersListing();

    function testAddChargersListing()
                public
        {
        meta.addCharger(0, power, cableType, tariff, latitude, longitude, oracleAddress);
        (uint16 _power, Charger.TypeOfCable _cableType, uint _tariff, string memory _latitude, string memory _longitude, bool _isWorking) = meta.getChargerInfo(0);

        require(power == _power, "Charger has bad init power.");
        require(tariff == _tariff, "Charger has bad init tariff.");
        require(keccak256(abi.encodePacked((latitude))) == keccak256(abi.encodePacked((_latitude))), "Charger has bad init latitude.");
        require(keccak256(abi.encodePacked((longitude))) == keccak256(abi.encodePacked((_longitude))), "Charger has bad init longitude.");
        require(cableType == _cableType, "Charger has bad init cableType.");
        require(_isWorking == true, "Charger has bad init isWorking.");
    }

}
