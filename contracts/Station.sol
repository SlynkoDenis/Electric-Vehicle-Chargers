pragma solidity >=0.4.22 <0.8.0;
import 'Charger.sol';


// deprecated contract
contract Station {
    mapping(uint16 => Charger) chargers;


    function getCharger(uint16 id) public pure returns(Charger) {
        if (!chargers[id].isWorking) {
            revert("getCharger_isntWorking");
        }
        return chargers[id];
    }


    function addCharger(uint16 id) public returns(bool) {
        return true;
    }
}
