# Electric Vehicle Chargers Project

## Architecture

```
-------------> Deposit -------------> Return (deposit-payment) money
                  |        Charge
     Don't charge |
     (cancel or   |
      timeout)    |
                  |
                  v
    Return (deposit-penalty) money
```

* Before usage chargers must declare themselves: power, price rate, cable type, coordinates
* Deposit's sum is defined by the user, who estimates the time he will charge the car.
Users can terminate charging before the end time (assume that it is
handled by the chargers' interface), then the remainder money will be transferred back.
* Penalty for order cancellation is 0.05 of the deposit.
* User pays only for the time actually spent charging. Hence, if he leaves earlier / arrives later,
spent time must be calculated by the physical Charger controller
and passed to the contract in order to refund correctly.
* When creating a new Charger, author must specify address of Oracle charger device to later validate
requests from it
