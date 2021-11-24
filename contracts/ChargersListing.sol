pragma solidity >=0.4.22 <0.8.0;
import "Charger.sol";


contract ChargersListing {
    mapping(uint64 => address) chargers;
    uint64[] chargersIndexes;


    /**
     * @brief Method returns parameters of a registered station
     * @param id        Charger's Id, must reffer to a working station
     * @return          power, type-of-cable, tariff, latitude, longitude, isWorking
     */
    function getChargerInfo(uint64 id)
        external
        view
        returns(uint16, Charger.TypeOfCable, uint, string memory, string memory, bool)
    {
        require(chargers[id] != address(0), "getCharger_isNotRegistered");
        return chargers[id].getInfo();
    }

    function getAllChargersIndexes()
        external
        view
        returns(uint64[] memory)
    {
        return chargersIndexes;
    }

    function addCharger(uint64 id, uint16 _power, Charger.TypeOfCable _cableType, uint _tariff,
                        string calldata _latitude, string calldata _longitude) external {
        require(chargers[id] == address(0), "addCharger_chargerAlreadyExists");
        chargers[id] = address(new Charger(_power, _cableType, _tariff, _latitude, _longitude));
        chargersIndexes.push(id);
    }

    // TODO: provide delete method using selfdestruct?
}
