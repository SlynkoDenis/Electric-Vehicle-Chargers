pragma solidity >=0.4.22 <0.8.0;


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

    // TODO: don't expose user address, rather use secret
    event DepositRegistered(
        uint startTime,
        uint16 durationInFiveMinutes,
        address user,
        uint receivedMoney
    );

    event DepositWasClosed(
        uint startTime,
        uint16 durationInMinutes
    );

    uint16 public power;
    TypeOfCable public cableType;
    uint public tariff;                                // tariff is represented in wei per minute
    string public latitude;                            // e.g. 55.423791
    string public longitude;                           // e.g. 37.518223
    bool public isWorking;

    address private oracleAddress;

    mapping(uint => uint16) private depositsIndexes;   // startTime => index
    DepositInfo[] depositsList;
    uint16[] freeIndexes;

    bool[2016] private reservations;                   // 7 days span is available for reservations.
                                                       // 7 * 24 * 12 = 2016
    uint16 rootIndex;
    uint rootTime;                                     // in 5 minutes
    uint epsilon;                                      // gas estimation for performing all operations, expressed in wei


    constructor(uint16 _power, uint8 _cableType, uint _tariff,
                string memory _latitude, string memory _longitude, address _oracleAddress) public {
        require(_cableType < 3, "constructor_invalidCableType");
        power = _power;
        cableType = TypeOfCable(_cableType);
        tariff = _tariff;
        latitude = _latitude;
        longitude = _longitude;
        isWorking = true;

        oracleAddress = _oracleAddress;

        rootIndex = 0;
        rootTime = block.timestamp / 300;
        epsilon = block.gaslimit;
    }

    function getInfo()
        external
        view
        returns(uint16, TypeOfCable, uint, string memory, string memory, bool)
    {
        return (power, cableType, tariff, latitude, longitude, isWorking);
    }

    function registerDeposit(uint _startTime, uint16 _durationInFiveMinutes)
        payable
        external
    {
        // NB! require reverts all changes and refunds remaining gas
        require(calculateRequiredDeposit(_durationInFiveMinutes) + epsilon < msg.value,
                "registerDeposit_notEnoughMoney");

        // firstly we update root index and time
        uint currentTime = block.timestamp / 300;
        require(_startTime >= currentTime, "registerDeposit_invalidStartTime");
        uint16 offset = currentTime - rootTime;     // TODO: fix overflow and possible erroneous contract states
        rootIndex += offset;
        rootTime = currentTime;

        // then we reserve the time and revert if it is not available
        uint16 i = _startTime - rootTime;
        uint16 endIndex = (i + _durationInFiveMinutes + 1) % 2016;
        if (endIndex > i) {
            for (; i < endIndex; i++) {
                require(reservations[i] == false, "registerDeposit_timeIsNotAvailable");
                reservations[i] = true;
            }
        } else {
            for (; i < 2016; i++) {
                require(reservations[i] == false, "registerDeposit_timeIsNotAvailable");
                reservations[i] = true;
            }
            for (i = 0; i < endIndex; i++) {
                require(reservations[i] == false, "registerDeposit_timeIsNotAvailable");
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
            depositIndex = depositsList.length - 1;
        } else {
            depositIndex = freeIndexes.length - 1;
            depositsList[depositIndex] = (DepositInfo(
                _startTime,
                _durationInFiveMinutes,
                msg.sender,
                msg.value
            ));
            depositsList.pop();
        }
        depositsIndexes[_startTime] = depositIndex;

        emit DepositRegistered(_startTime, _durationInFiveMinutes, msg.sender, msg.value);
    }

    function setIsWorking(bool _value) external {
        isWorking = _value;
    }

    // public is used because the method can be called internally
    // assuming that charging time is between 5 minutes and one day
    function calculateRequiredDeposit(uint16 _durationInFiveMinutes)
        public
        view
        returns(uint)
    {
        require(_durationInFiveMinutes >= 1 && _durationInFiveMinutes <= 288,
                "calculateRequiredDeposit_invalidReservedTime");
        return _durationInFiveMinutes * 5 * tariff;
    }

    function cancelOrder(uint _startTime)
        payable
        external
    {
        require(depositsList.length != 0 && depositsList[depositsIndexes[_startTime]].user == msg.sender,
                "cancelOrder_orderDoesNotExist");

        uint16 index = depositsIndexes[_startTime];
        // return receivedMoney - penalty
        msg.sender.transfer(depositsList[index].receivedMoney * 95 / 100);

        // delete order from internal structures
        freeIndexes.push(index);
        delete depositsList[index];
        delete depositsIndexes[_startTime];
    }

    /**
     * @brief Method must be triggered by the physical charger controller aka Oracle.
              Oracle must return the time actualy used by the user.
     * @param _startTime            start time of the order to close
     * @param _timeInMinutes        time spend by user, measured by Oracle
     */
    function closeOrder(uint _startTime, uint16 _timeInMinutes)
        payable
        external
    {
        // TODO: there are options for outdated orders: automatic refund triggered by Oracle
        // with a call to closeOrder(x, _timeInMinutes: 0)
        // or explicit refund after request to a dedicated method by the user.
        // Yet we use closeOrder()
        require(msg.sender == oracleAddress, "closeOrder_invalidOracleAddress");
        require(depositsList.length != 0 && depositsList[depositsIndexes[_startTime]].user != address(0),
                "closeOrder_orderDoesNotExist");

        // return money
        uint16 index = depositsIndexes[_startTime];
        if (_timeInMinutes != 0) {
            depositsList[index].user.transfer(depositsList[index].receivedMoney - _timeInMinutes * tariff);
        } else {
            depositsList[index].user.transfer(depositsList[index].receivedMoney * 95 / 100);
        }

        // delete order from internal structures
        freeIndexes.push(index);
        delete depositsList[index];
        delete depositsIndexes[_startTime];

        emit DepositWasClosed(_startTime, _timeInMinutes);
    }
}
