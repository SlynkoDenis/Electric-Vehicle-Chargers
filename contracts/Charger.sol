pragma solidity ^0.5.8;


contract Charger {
    // dummy values, not for release version
    enum TypeOfCable {TYPE1, TYPE2, TYPE3}

    struct DepositInfo {
        // time is measured in seconds since unix epoch
        uint startTime;
        uint16 durationInFiveMinutes;
        address payable user;
        uint receivedMoney;
    }

    struct InternalIndexInfo {
        uint16 listIndex;
        uint16 reservationsStart;
        uint16 reservationsEnd;
    }

    event DepositWasRegistered(
        uint startTime,
        uint16 durationInFiveMinutes,
        uint64 secretSessionId,
        uint receivedMoney
    );

    event DepositWasClosed(
        uint startTime,
        uint16 durationInMinutes,
        uint64 secretSessionId
    );

    event ChangeWorkingStateCharger(
        bool wasWorking,
        bool isWorking
    );

    uint16 public power;
    TypeOfCable public cableType;
    uint public tariff;                                             // tariff is represented in wei per minute
    string public latitude;                                         // e.g. 55.423791
    string public longitude;                                        // e.g. 37.518223
    bool public isWorking;
    address payable public ownerAddress;

    address private oracleAddress;
    uint private freeMoney;

    mapping(uint => InternalIndexInfo) private depositsIndexes;     // startTime => index in depositsList array
    DepositInfo[] private depositsList;
    uint16[] private freeIndexes;
    bool[2016] private reservations;                                // 7 days span is available for reservations.
                                                                    // 7 * 24 * 12 = 2016
    uint16 private rootIndex;
    uint private rootTime;                                          // in 5 minutes


    constructor(uint16 _power, TypeOfCable _cableType, uint _tariff,
                string memory _latitude, string memory _longitude,
                address _oracleAddress, address payable _ownerAddress) public {
        power = _power;
        cableType = _cableType;
        tariff = _tariff;
        latitude = _latitude;
        longitude = _longitude;
        isWorking = true;
        ownerAddress = _ownerAddress;

        oracleAddress = _oracleAddress;
        freeMoney = 0;

        rootIndex = 0;
        rootTime = block.timestamp / 300;
    }

    function getInfo()
        public
        view
        returns(uint16, TypeOfCable, uint, string memory, string memory, bool)
    {
        return (power, cableType, tariff, latitude, longitude, isWorking);
    }

    function registerDeposit(uint _startTime,
                             uint16 _durationInFiveMinutes,
                             uint64 _secretSessionId)
        external
        payable
    {
        require(isWorking, "registerDeposit_isNotWorking");
        require(calculateRequiredDeposit(_durationInFiveMinutes) < msg.value,
                "registerDeposit_notEnoughMoney");

        // firstly we update root index and time
        uint currentTime = block.timestamp / 300;
        require(_startTime >= currentTime, "registerDeposit_invalidStartTime");
        // TODO: we might want to automatically detect erroneous contract state, better to do it here
        uint16 offset = uint16((currentTime - rootTime) % 2016);
        rootIndex = (rootIndex + offset) % 2016;
        rootTime = currentTime;

        // then we reserve the time and revert operation if time is occupied
        uint16 i = uint16(_startTime - rootTime);
        uint16 endIndex = (i + _durationInFiveMinutes + 1) % 2016;
        if (endIndex > i) {
            for (; i < endIndex; i++) {
                require(reservations[i] == false, "registerDeposit_timeIsOccupied");
                reservations[i] = true;
            }
        } else {
            for (; i < 2016; i++) {
                require(reservations[i] == false, "registerDeposit_timeIsOccupied");
                reservations[i] = true;
            }
            for (i = 0; i < endIndex; i++) {
                require(reservations[i] == false, "registerDeposit_timeIsOccupied");
                reservations[i] = true;
            }
        }

        // finally we add the deposit info in the internal structures
        uint16 depositIndex = 0;
        if (freeIndexes.length == 0) {
            depositsList.push(DepositInfo(
                _startTime,
                _durationInFiveMinutes,
                msg.sender,
                msg.value
            ));
            depositIndex = uint16(depositsList.length - 1);
        } else {
            depositIndex = uint16(freeIndexes.length - 1);
            depositsList[depositIndex] = (DepositInfo(
                _startTime,
                _durationInFiveMinutes,
                msg.sender,
                msg.value
            ));
            depositsList.pop();
        }
        depositsIndexes[_startTime] = InternalIndexInfo(
            depositIndex,
            uint16(_startTime - rootTime),
            endIndex
        );

        emit DepositWasRegistered(_startTime, _durationInFiveMinutes, _secretSessionId, msg.value);
    }

    // public is used because the method can be called internally
    // assuming that charging time is between 5 minutes and one day
    function calculateRequiredDeposit(uint16 _durationInFiveMinutes)
        public
        view
        returns(uint)
    {
        require(_durationInFiveMinutes >= 1 && _durationInFiveMinutes <= 288,
                "calculateRequiredDeposit_invTime");
        return _durationInFiveMinutes * 5 * tariff + block.gaslimit;
    }

    function cancelOrder(uint _startTime, uint64 _secretSessionId)
        external
        payable
    {
        require(isWorking, "registerDeposit_isNotWorking");
        uint16 index = depositsIndexes[_startTime].listIndex;
        require(depositsList.length != 0 && depositsList[index].user == msg.sender,
                "cancelOrder_orderDoesNotExist");

        // calculate refund
        uint refund = depositsList[index].receivedMoney * 95 / 100;
        freeMoney += depositsList[index].receivedMoney - refund;

        // delete order from internal structures
        freeIndexes.push(index);
        delete depositsList[index];
        index = depositsIndexes[_startTime].reservationsStart;
        uint16 endIndex = depositsIndexes[_startTime].reservationsEnd;
        if (index < endIndex) {
            for (; index < endIndex; index++) {
                reservations[index] = false;
            }
        } else {
            for (; index < 2016; index++) {
                reservations[index] = false;
            }
            for (index = 0; index < endIndex; index++) {
                reservations[index] = false;
            }
        }
        delete depositsIndexes[_startTime];

        // refund in the end to prevent from race conditions
        msg.sender.transfer(refund);
        emit DepositWasClosed(_startTime, 0, _secretSessionId);
    }

    /**
     * Method must be triggered by the physical charger controller aka Oracle.
     * Oracle must return the time actualy used by the user.
     * @param _startTime            start time of the order to close
     * @param _timeInMinutes        time spend by user, measured by Oracle
     */
    function closeOrder(uint _startTime, uint16 _timeInMinutes)
        external
        payable
    {
        // TODO: there are options for outdated orders: automatic refund triggered by Oracle
        // with a call to closeOrder(x, _timeInMinutes: 0)
        // or explicit refund after request to a dedicated method by the user.
        // Yet we use closeOrder().
        require(isWorking, "registerDeposit_isNotWorking");
        uint16 index = depositsIndexes[_startTime].listIndex;
        require(msg.sender == oracleAddress, "closeOrder_invalidOracleAddress");
        require(depositsList.length != 0 && depositsList[index].user != address(0),
                "closeOrder_orderDoesNotExist");

        // refund calculation
        uint refund = 0;
        if (_timeInMinutes != 0) {
            refund = depositsList[index].receivedMoney - _timeInMinutes * tariff;
        } else {
            refund = depositsList[index].receivedMoney * 95 / 100;
        }
        freeMoney += depositsList[index].receivedMoney - refund;

        // delete order from internal structures
        freeIndexes.push(index);
        delete depositsList[index];
        index = depositsIndexes[_startTime].reservationsStart;
        uint16 endIndex = depositsIndexes[_startTime].reservationsEnd;
        if (index < endIndex) {
            for (; index < endIndex; index++) {
                reservations[index] = false;
            }
        } else {
            for (; index < 2016; index++) {
                reservations[index] = false;
            }
            for (index = 0; index < endIndex; index++) {
                reservations[index] = false;
            }
        }
        delete depositsIndexes[_startTime];

        // refund in the end to prevent from race conditions
        depositsList[index].user.transfer(refund);
        emit DepositWasClosed(_startTime, _timeInMinutes, 0);
    }

    function setIsWorking(bool _value) external {
        require(msg.sender == ownerAddress, "setIsWorking_unauthorized");
        bool wasWorking = isWorking;
        isWorking = _value;
        if (wasWorking && !isWorking) {
            delete freeIndexes;
            delete reservations;

            uint16 i = 0;
            for (; i < depositsList.length; i++) {
                depositsList[i].user.transfer(depositsList[i].receivedMoney);
            }
            delete depositsList;
        }

        emit ChangeWorkingStateCharger(wasWorking, _value);
    }

    function transferMoney(address payable receiver)
        external
        payable
    {
        require(msg.sender == ownerAddress, "transferMoney_unauthorized");
        freeMoney = 0;
        receiver.transfer(freeMoney);
    }

    function destructThisContract() external {
        require(msg.sender == ownerAddress, "destructThisContract_unauthorized");
        selfdestruct(ownerAddress);
    }
}
