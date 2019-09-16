# ethplay

## install
yarn 

## run app

yarn start



todo List:
```
1.get code from
https://github.com/blockscout/evm-smart-contracts/tree/master/contracts
2.resave
hash source.sol become path name
save need info to hash/contact.json

3.use hypertrie to save key value

4.createListFromcontracts hashList.json and hash it 

5.dat share .  get dat address

6.use dat-store    node 11 up

7.dat-store run service  --expose-to-internet  && dat-store dat://address

8.


```




server shell script  auto update emv contract 

#!/bin/bash
rm -rf /home/ethplay/evm-smart-contracts/
rm -rf /home/evm-smart-contracts
rm -rf /home/ethplay/evm-smart-contracts
git clone git@github.com:polo13999/ethplay.git /home/ethplay
git clone git@github.com:blockscout/evm-smart-contracts.git /home/evm-smart-contracts
cp -rf /home/evm-smart-contracts/ /home/ethplay/evm-smart-contracts
cd /home/ethplay/ && npm install && npm run start   
cd /home/ethplay/ && npm install && npm run api


```

ci-cd script 

#!/bin/bash
rm -rf /home/sourcecode
mv -rf /home/ethplay/sourcecode /home/sourcecode
rm -rf /home/ethplay
rm -rf /home/blockscout
git clone git@github.com:polo13999/ethplay.git /home/ethplay
git clone git@github.com:blockscout/evm-smart-contracts.git /home/blockscout
cp -rf /home/blockscout/contracts /home/ethplay/evm-smart-contracts
mv /home/sourcecode /home/ethplay/sourcecode
cd /home/ethplay/ && npm install && npm run start
cd /home/ethplay/ && npm install && npm run api

```


