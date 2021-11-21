pragma solidity >=0.4.22 <0.8.0;


contract Charger {
    // dummy values, not for release version
    enum TypeOfCable {TYPE1, TYPE2, TYPE3}
    struct DepositInfo {
        // in bytes40 we can store concatenated {year, month, day, hour, time}
        // using bytes40 allows to easily compare dates. However, there is no bytes40.
        // But we can always divide the data into two variables
        bytes32 startTime1;
        uint8 startMinute;
        bytes32 endTime1;
        uint8 endMinute;
        address user;
        uint depositMoney;
        bool isActive;                                  // true for open, false for closed
    }

    uint16 private power;
    TypeOfCable private cableType;
    uint private tariff;                                // tariff is represented in wei per minute
    string private latitude;                            // e.g. 55.423791
    string private longitude;                           // e.g. 37.518223
    DepositInfo[] private reservations;
    bool private isWorking;
    mapping(address => DepositInfo) activeDeposits;


    constructor(uint16 _power, uint8 _cableType, uint _tariff,
                string memory _latitude, string memory _longitude) public {
        require(_cableType < 3, "constructor_invalidCableType");
        power = _power;
        cableType = TypeOfCable(_cableType);
        tariff = _tariff;
        latitude = _latitude;
        longitude = _longitude;
        isWorking = true;
    }


    function setIsWorking(bool _value) external {
        isWorking = _value;
    }


    function getIsWorking() external view returns(bool) {
        return isWorking;
    }


    // return bool(lhs <= rhs)
    // function isDayEarlier(ReserveTime lhs, ReserveTime rhs) external pure returns(bool) {
    //     if (lhs.year < rhs.year) {
    //         return true;
    //     } else if (lhs.year == rhs.year) {
    //         if (lhs.month < rhs.month) {
    //             return true;
    //         } else if (lhs.month == rhs.month) {
    //             if (lhs.day < rhs.day) {
    //                 return true;
    //             } else if (lhs.day == rhs.day) {
    //                 if (lhs.hour < rhs.hour) {
    //                     return true;
    //                 } else if (lhs.hour == rhs.hour) {
    //                     if (lhs.minute <= rhs.minute) {
    //                         return true;
    //                     }
    //                 }
    //             }
    //         }
    //     }
    //     return false;
    // }

    function isAvailable(bytes32 _startTime1, uint8 _startMinute,
                         bytes32 _endTime1, uint8 _endMinute) external view returns(bool) {
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

        // TODO: implement binary search
        // uint32 i = reservations.length / 2;
        // uint32 step = reservations.length / 4;

        // while (step > 0 && i < reservations.length && i >= 0) {
        //     if (isDayEarlier(reservations[i], checkedTime)) {
        //         i += step;
        //     } else {
        //         i -= step;
        //     }
        //     step /= 2;
        // }
        return false;
    }


    // taken from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    function bytesToUint8(bytes32 _bytes, uint _start) private pure returns(uint8) {
        require(_start < 32, "toUint8_outOfBounds");
        uint8 res;

        assembly {
            res := mload(add(add(_bytes, 0x1), _start))
        }

        return res;
    }


    // public is used because the method can be called internally
    // assuming that charging can't take more than a day
    // TODO: check that all hour:minute:month:date:year have valid values
    function calculateRequiredDeposit(bytes32 _startTime1, uint8 _startMinute,
                                      bytes32 _endTime1, uint8 _endMinute) public view returns(uint) {
        require(_endTime1 > _startTime1, "calculateRequiredDeposit_invalidDates");
        uint money = 0;

        uint8 yearGap = bytesToUint8(_endTime1, 0) - bytesToUint8(_startTime1, 0);
        require(yearGap <= 1, "calculateRequiredDeposit_tooMuchTime");

        uint8 monthGap = 0;
        if (yearGap == 1) {
            require(bytesToUint8(_endTime1, 8) == 1, "calculateRequiredDeposit_tooMuchTime");
            monthGap = 1;
        } else {
            monthGap = bytesToUint8(_endTime1, 8) - bytesToUint8(_startTime1, 8);
        }
        require(monthGap <= 1, "calculateRequiredDeposit_tooMuchTime");

        uint8 dayGap = 0;
        if (monthGap == 1) {
            require(bytesToUint8(_endTime1, 16) == 1, "calculateRequiredDeposit_tooMuchTime");
            dayGap = 1;
        } else {
            dayGap = bytesToUint8(_endTime1, 16) - bytesToUint8(_startTime1, 16);
        }
        require(dayGap <= 1, "calculateRequiredDeposit_tooMuchTime");

        uint8 startHour = bytesToUint8(_startTime1, 24);
        uint8 endHour = bytesToUint8(_endTime1, 24);
        uint16 durationInMinutes = 0;
        if (dayGap == 1) {
            durationInMinutes = 60 - _startMinute + (23 - startHour + endHour) * 60  + _endMinute;
        } else {
            if (startHour == endHour) {
                durationInMinutes = _endMinute - _startMinute;
            } else {
                durationInMinutes = 60 - _startMinute + (endHour - startHour - 1) * 60 + _endMinute;
            }
        }
        money = tariff * durationInMinutes;
    }


    function receiveDeposit(bytes32 _startTime1, uint8 _startMinute,
                            bytes32 _endTime1, uint8 _endMinute) external payable {
        if (msg.value < calculateRequiredDeposit(_startTime1, _startMinute, _endTime1, _endMinute)) {
            revert("receiveDeposit_notEnoughMoney");
        }
        // TODO: add to the queue and mapping, set isActive to true
    }


    function cancelOrder(address payable _depositAddress) payable external {
        if (!activeDeposits[_depositAddress].isActive) {
            revert("cancelOrder_addressIsNotActive");
        }

        _depositAddress.transfer(activeDeposits[_depositAddress].depositMoney / 100 * 95);
        activeDeposits[_depositAddress].isActive = false;
        // TODO: remove from queue
    }


    function closeOrder(address payable) payable external returns(bool) {
        // TODO: method must be triggered by the physical charger controller aka Oracle.
        // Oracle must return the time actualy used by the user.
        return true;
    }
}
