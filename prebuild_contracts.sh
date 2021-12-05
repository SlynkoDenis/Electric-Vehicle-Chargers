#!/bin/bash -ex

if [ ! -d "node_modules" ]; then
    npm install
fi
cp ./node_modules/@truffle/contract/dist/{truffle-contract.js,truffle-contract.js.map} ./src/js/
cp ./node_modules/web3/dist/{web3.min.js,web3.min.js.map} ./src/js/
cp ./node_modules/sjcl/sjcl.js ./src/js/
cp ./node_modules/sjcl/core/{sha1.js,codecHex.js} ./src/js/


truffle compile
cp build/contracts/Charger.json ./src/
