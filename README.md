# Electric Vehicle Chargers

Chargers' rent web application (DApp) on Ethereum Blockchain Network

### Architecture

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

### Prerequisites
- NodeJS (https://nodejs.org/en/)
- Git (https://desktop.github.com/) 
- Ganache (https://truffleframework.com/ganache) 
- Truffle (``` npm install -g truffle ``` )
- Chrome Browser (https://www.google.com/chrome/)
- Metamask (https://chrome.google.com/webstore/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn)


### Initialize the project
``` 
npm run prebuild
```


### Compile and Migrate
for first launch or restart
```
truffle migrate --reset
```
for other launches
```
truffle migrate
```
for uploading pre-defined Chargers (after migration):
```
truffle exec query.js
```

### Deploy User Interface
```
npm run dev
```
