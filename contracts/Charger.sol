pragma solidity >=0.4.22 <0.8.0;


contract Charger {
    // dummy values, not for release version
    enum TypeOfCable {TYPE1, TYPE2, TYPE3}
    struct DepositInfo {
        // time is measured in seconds since unix epoch
        uint startTime;
        uint20 durationInMinutes;
        address user;
        int32 left;
        int32 right;
    }

    uint16 private power;
    TypeOfCable private cableType;
    uint private tariff;                                // tariff is represented in wei per minute
    string private latitude;                            // e.g. 55.423791
    string private longitude;                           // e.g. 37.518223
    bool private isWorking;
    DepositInfo[] private reservations;
    uint32[] private freeIndexes;
    uint32 root;


    constructor(uint16 _power, uint8 _cableType, uint _tariff,
                string memory _latitude, string memory _longitude) public {
        require(_cableType < 3, "constructor_invalidCableType");
        power = _power;
        cableType = TypeOfCable(_cableType);
        tariff = _tariff;
        latitude = _latitude;
        longitude = _longitude;
        isWorking = true;

        root = 0;
    }

    function insertDeposit(uint _startTime, uint20 _durationInMinutes, address _user) private {
        if (reservations.length == 0) {
            reservations.push(DepositInfo(_startTime, _durationInMinutes, _user, ));
        } else {
            // ....
        }
    }

    function setIsWorking(bool _value) external {
        isWorking = _value;
    }

    function getIsWorking() external view returns(bool) {
        return isWorking;
    }

    function isAvailable(uint _startTime, uint20 _durationInMinutes) external view returns(bool) {
        if (reservations.length == 0) {
            return true;
        }

        uint32 i = 0;
        // TODO: iteration over array costs a lot of gas
        for (i = 0; i < reservations.length; i++) {
            if (reservations[i].endTime1 <= _startTime1 && reservations[i].endMinute <= _startMinute) {
                if (i + 1 != reservations.length) {
                    if (_endTime1 <= reservations[i + 1].startTime1 && _endMinute <= reservations[i + 1].startMinute) {
                        return true;
                    }
                } else {
                    return true;
                }
            } else {
                break;
            }
        }

        return false;
    }

    // public is used because the method can be called internally
    // assuming that charging time is between 5 minutes and one day
    function calculateRequiredDeposit(uint20 _durationInMinutes) public view returns(uint) {
        require(_durationInMinutes > 5 && _durationInMinutes < 1440, "calculateRequiredDeposit_invalidReservedTime");
        return _durationInMinutes * tariff;
    }

    function receiveDeposit(uint _startTime, uint20 _durationInMinutes) external payable {
        if (!isAvailable(_startTime, _durationInMinutes)) {
            msg.sender.transfer(msg.value);
            revert("receiveDeposit_timeIsNotAvailable");
        }
        if (msg.value < calculateRequiredDeposit(_durationInMinutes)) {
            msg.sender.transfer(msg.value);
            revert("receiveDeposit_notEnoughMoney");
        }
        // TODO: add to the queue and mapping, set isActive to true
    }

    function cancelOrder() payable external {
        if (!activeDeposits[msg.sender].isActive) {
            revert("cancelOrder_addressIsNotActive");
        }

        msg.sender.transfer(activeDeposits[msg.sender].depositMoney / 100 * 95);
        activeDeposits[msg.sender].isActive = false;
        // TODO: remove from queue
    }

    function closeOrder(address payable) payable external returns(bool) {
        // TODO: method must be triggered by the physical charger controller aka Oracle.
        // Oracle must return the time actualy used by the user.
        return true;
    }
}
