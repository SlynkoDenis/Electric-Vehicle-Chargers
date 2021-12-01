pragma solidity ^0.5.8;
import "./Charger.sol";


contract ChargersListing {
    mapping(uint64 => address) public chargers;
    uint64[] private chargersIndexes;


    /**
     * Method returns parameters of a registered station
     * @param id        Charger's Id, must reffer to a working station
     * @return          power, type-of-cable, tariff, latitude, longitude, isWorking
     */
    function getChargerInfo(uint64 id)
        external
        view
        returns(uint16, Charger.TypeOfCable, uint, string memory, string memory, bool)
    {
        require(chargers[id] != address(0), "getCharger_isNotRegistered");
        Charger targetCharger = Charger(chargers[id]);
        return targetCharger.getInfo();
    }

    function getCharger(uint64 id)
        external
        view
        returns(Charger)
    {
        require(chargers[id] != address(0), "getCharger_isNotRegistered");
        Charger targetCharger = Charger(chargers[id]);
        return targetCharger;
    }

    function getChargerRegisterDeposit(uint64 id,uint _startTime,
                             uint16 _durationInFiveMinutes,
                             uint64 _secretSessionId)
        external
    {
        require(chargers[id] != address(0), "getCharger_isNotRegistered");
        Charger targetCharger = Charger(chargers[id]);
        return targetCharger.registerDeposit(_startTime, _durationInFiveMinutes, _secretSessionId);
    }

    function getAllChargersIndexes()
        external
        view
        returns(uint64[] memory)
    {
        return chargersIndexes;
    }

    function getAllChargers()
        external
        view
        returns(address[] memory)
    {
        address[] memory ret = new address[](4);
        for (uint64 i = 0; i < 4; i++) {
            ret[i] = chargers[i];
        }
        return ret;
    }

    function addCharger(uint64 id, uint16 _power, Charger.TypeOfCable _cableType, uint _tariff,
                        string calldata _latitude, string calldata _longitude,
                        address oracleAddress) external {
        // require(chargers[id] != address(0), "addCharger_chargerAlreadyExists");
        chargers[id] = address(new Charger(
            _power,
            _cableType,
            _tariff,
            _latitude,
            _longitude,
            oracleAddress,
            msg.sender
        ));
        chargersIndexes.push(id);
        // chargersIndexes[id] = id;
    }

    function deleteCharger(uint64 id) external {
        require(chargers[id] != address(0), "addCharger_doesNotExist");
        Charger targetCharger = Charger(chargers[id]);
        require(targetCharger.ownerAddress() == msg.sender, "addCharger_unauthorized");
        delete chargers[id];
    }
}
