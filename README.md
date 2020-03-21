# BLT - Blockchain for Lifecycle Transparency

### About

This is a demonstration of how third-party web applications can integrate with the BLT (Blockchain for Lifecycle Transparency) system with the BLT client [JS library](app/static/js/blt-lib.js).

* [Publisher](app/static/js/publisher.js): A simulated real-world publisher.
* [Logger](app/static/js/logger.js): A simulated online platform (e.g. Github, OSF) that logs the activities of a project. See the source files for more details of how to use the BLT client APIs.

The program component of the BLT system is implemented by Ethereum smart contracts ([Source](app/static/contract/)).

### Instructions

1. Install pip and flask (Python3)

```
$ pip install flask
```

2. Start the server

```
$ bash ./run.sh [--host=0.0.0.0]
```

3. To create a new project, visit [Publisher](app/static/js/publisher.js). To log or view the activities of your or others' projects, visit [Logger](app/static/js/logger.js).

### Fun Facts

The BLT project also uses the BLT system (with an older version) to log its activities! The contract address of the BLT project is at [0xbe01c49471327716FEA9394dA92F975b8176078C](https://ropsten.etherscan.io/address/0xbe01c49471327716fea9394da92f975b8176078c) on Ropsten Testnet.
