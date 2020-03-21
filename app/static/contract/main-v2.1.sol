// This code is modified from smart contract of ARTIFACTS
pragma experimental ABIEncoderV2;
pragma solidity ^0.4.21;
// version 2.1

// Ownership
contract Owned {
    struct Member {
        address mem_addr;
        bytes32 name;
    }
    mapping (address => Member) public owners;
    uint mem_num = 0;
      
    function Owned() public {
        owners[msg.sender].mem_addr = msg.sender;
        owners[msg.sender].name = "Admin";
        mem_num = 1;
    }
    
    modifier onlyOwners {
        require(owners[msg.sender].mem_addr == msg.sender);
        _;
    }
    
    function addMember(address[] _addr, bytes32[] _name) public onlyOwners {
        uint _memberNum = _addr.length;
        for (uint i = 0; i < _memberNum; i++) {
            owners[_addr[i]] = Member(_addr[i], _name[i]);
            mem_num++;
        }
    }
      
    function delMember(address[] _addr) public onlyOwners {
        uint _memberNum = _addr.length;
        for (uint i = 0; i < _memberNum; i++) {
            delete owners[_addr[i]];
            mem_num--;
        }
    }
}

contract Project is Owned {
    struct Phase {
        bytes32 phasename;
        bytes32 updater;
        bytes32[] parents;
        bytes32[] urls;
        uint deadline;
        bytes32 datahash;
        bool isverified;
    }
    
    uint phaseNum;
    mapping (bytes32 => Phase) phases;
      
    function addPhases(bytes32[] _names) public onlyOwners {
        phaseNum = _names.length;
        for (uint i = 0; i < phaseNum; i++) {
            phases[_names[i]] = Phase(_names[i], "", new bytes32[](0), new bytes32[](0), 0, 0, false);
        }
    }
    
    function addRelations(bytes32[] _names) public onlyOwners {
        uint tmp = _names.length;
        for (uint i = 1; i < tmp; i++) {
            phases[_names[0]].parents.push(_names[i]);
        }
    }
    
    function setdeadline(bytes32 _name, uint time) public onlyOwners {
        require(phases[_name].deadline == 0);
        phases[_name].deadline = time;
    }
    
    function time() public returns (uint) {
        return now;
    }
    
    function updatePhase(bytes32 _name, bytes32[] _urls, bytes32 _datahash) public onlyOwners {
          require(phases[_name].deadline == 0 || now < phases[_name].deadline);
          require(!phases[_name].isverified);
          uint parentsnum = phases[_name].parents.length;
          for (uint i = 0; i < parentsnum; i++) {
              require(phases[phases[_name].parents[i]].isverified);
          }
          uint urlnum = _urls.length;
          for (i = 0; i < urlnum; i++) {
              phases[_name].urls.push(_urls[i]);
          }
          phases[_name].updater = owners[msg.sender].name;
          phases[_name].datahash = _datahash;
          phases[_name].isverified = true;
    }
    
    function updater(bytes32 _name) public returns (bytes32) {
        return phases[_name].updater;    
    }
}
