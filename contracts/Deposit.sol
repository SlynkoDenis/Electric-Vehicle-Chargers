pragma solidity >=0.4.22 <0.8.0;
import "Charger.sol";


contract Deposit {
    address recipient;
    bytes32 startTime1;
    uint8 startMinute;
    bytes32 endTime1;
    uint8 endMinute;
    bool isActive;                // true for open, false for closed

    event TimeSlotReserved(
        address user,
        bytes32 startTime1,
        uint8 startMinute,
        bytes32 endTime1,
        uint8 endMinute,
        uint weiAmount
    );


    function payDeposit(address payable _recipient, bytes32 _startTime1,
                        uint8 _startMinute, bytes32 _endTime1, uint8 _endMinute) external returns(bool) {
        Charger targetCharger = Charger(_recipient);
        uint _weiAmount = targetCharger.calculateRequiredDeposit(_startTime1, _startMinute,
                                                                 _endTime1, _endMinute);
        if (_weiAmount < address(this).balance) {
            return false;
        }

        _recipient.transfer(_weiAmount);
        emit TimeSlotReserved(address(this), _startTime1, _startMinute, _endTime1,
                              _endMinute, _weiAmount);

        recipient = _recipient;
        startTime1 = _startTime1;
        startMinute = _startMinute;
        endTime1 = _endTime1;
        endMinute = _endMinute;
        isActive = true;

        return true;
    }

    function cancelOrder() external returns(bool) {
        // TODO: call to recipient and cancel order. Cancellation must trigger
        // deposit refund

        isActive = false;

        return true;
    }
}
