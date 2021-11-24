pragma solidity >=0.4.22 <0.8.0;
import "Charger.sol";


contract Deposit {
    address recipient;
    uint startTime;
    uint20 durationInMinutes;
    bool isActive;    // true for open, false for closed

    event TimeSlotReserved(
        address user,
        uint startTime,
        uint20 durationInMinutes, 
        uint weiAmount
    );


    function payDeposit(address payable _recipient,
                        uint _startTime, uint20 _durationInMinutes) external returns(bool) {
        Charger targetCharger = Charger(_recipient);
        uint _weiAmount = targetCharger.calculateRequiredDeposit(_startTime, _durationInMinutes);
        if (_weiAmount < address(this).balance) {
            return false;
        }

        _recipient.transfer(_weiAmount);
        emit TimeSlotReserved(address(this), _startTime, _durationInMinutes, _weiAmount);

        recipient = _recipient;
        startTime = _startTime;
        durationInMinutes = _durationInMinutes;
        isActive = true;

        return true;
    }

    function cancelOrder() external returns(bool) {
        if (!isActive) {
            return false;
        }
        Charger targetCharger = Charger(recipient);
        targetCharger.cancelOrder();
        // TODO: where to check that money was returned?

        return true;
    }

    function getReturnedMoney() external payable {
        // TODO: add check that the received amount is right?
        isActive = false;
    }
}
