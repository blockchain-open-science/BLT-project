const noCurrentProviderError = 'No currentProvider for web3';
const noContractError = 'Contract not provided';

function BLTProject(cb) {
  this.contractAddr = null;
  this.contractABI = null;
  this.contract = null;
  cb(null, 'Project initialized');
}

BLTProject.prototype.atAddress = function(addr, abi, cb) {
  if (typeof web3 !== 'undefined') {
    this.contract = web3.eth.contract(abi).at(addr);
    this.contractAddr = addr;
    this.contractABI = abi;
    cb(null, 'Contract initialized');
  }
  else cb(noCurrentProviderError);
}

BLTProject.prototype.deploy = function(args, abi, bytecode, cb) {
  var self = this;
  this.contractABI = abi;
  if (typeof web3 !== 'undefined') {
    this.contract = web3.eth.contract(abi).new(...args, {
      from: web3.eth.defaultAccount,
      data: bytecode,
    }, function (err, contract) {
      // note that this callback function will be called twice
      // and err === null in the first time
      if (!err && typeof contract.address !== 'undefined') {
        self.contractAddr = contract.address;
        cb(null, 'Contract deployed');
      }
      else cb(err);
    });
  }
  else cb(noCurrentProviderError);
}

function setFunc(fnName) {
  BLTProject.prototype[fnName] = function(args, cb) {
    if (typeof cb === 'undefined')
      cb = function() {};
    if (this.contract !== null) {
      this.contract[fnName](...args, cb);
    }
    else cb(noContractError);
  }
}

function setFuncWithEvent(fnName, evtFnName) {
  BLTProject.prototype[fnName] = function(args, cb, evtcb) {
    if (typeof cb === 'undefined')
      cb = function() {};
    var self = this;
    if (self.contract !== null) {
      self.contract[fnName](...args, function(err, txHash) {
        cb(err, txHash);
        if (!err && typeof evtcb === 'function') {
          var event = self.contract[evtFnName]();
          event.watch(function (err, res) {
            if (!err) {
              if (res.transactionHash === txHash) {
                event.stopWatching();
                evtcb(err, res);
              }
            }
            else evtcb(err);
          });
        }
      });
    }
    else cb(noContractError);
  }
}

/* methods from contract Owned */
setFunc('owners');
setFunc('getOwnerAddrs');
setFuncWithEvent('addMember', 'AddMember');
setFuncWithEvent('delMember', 'DelMember');

/* methods from contract Project */
/* public variables */
setFunc('projectName');
setFunc('phases');
setFunc('phaseDependencies');
setFunc('timeConstraints');
setFunc('isFrozen');
setFunc('isVerified');

/* phase operations */
setFuncWithEvent('addPhaseRecord', 'AddPhaseRecord');
setFuncWithEvent('commitPhase', 'CommitPhase');
setFuncWithEvent('addAgreement', 'AddAgreement');
setFunc('calculatePhaseHash');

/* project operations */
setFunc('getPhaseNames');
setFuncWithEvent('addPhase', 'AddPhase');
setFuncWithEvent('addPhaseDependency', 'AddPhaseDependency');
setFuncWithEvent('addTimeConstraint', 'AddTimeConstraint');

/* verify */
setFunc('verifyAgreement', 'VerifyAgreement');
setFunc('verifyPhaseDependencies', 'VerifyPhaseDependencies');
setFunc('verifyTimeConstraints', 'VerifyTimeConstraints');
