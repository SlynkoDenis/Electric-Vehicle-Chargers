pragma solidity >=0.4.22 <0.8.0;
import "Charger.sol";


contract ChargersListing {
    mapping(uint64 => Charger) chargers;


    function getCharger(uint16 id) public view returns(Charger) {
        if (chargers[id].getIsWorking()) {
            revert("getCharger_isntWorking");
        }
        return chargers[id];
    }

    function addCharger(uint64 id, uint16 _power, uint8 _cableType, uint _tariff,
                        string memory _latitude, string memory _longitude) public returns (bool) {
        if (chargers[id].getIsWorking()) {
            return false;
        }

        chargers[id] = new Charger(_power, _cableType, _tariff, _latitude, _longitude);
        return true;
    }
}
