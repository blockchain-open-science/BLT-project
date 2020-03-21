pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;
// version 2.2

// Ownership
contract Owned {
    struct Member {
        address memAddr;
        bytes32 name;
        bool isValue;
    }
    
    mapping (address => Member) public owners;
    uint public memNum = 0;
    
    event AddMember(address _addr, bytes32 _name);
    event DelMember(address _addr);
      
    constructor() public {
        owners[msg.sender] = Member(msg.sender, "Admin", true);
        memNum += 1;
    }
    
    modifier onlyOwners {
        require(owners[msg.sender].memAddr == msg.sender);
        _;
    }
    
    function addMember(address _addr, bytes32 _name) public onlyOwners {
        require(!owners[_addr].isValue);
        owners[_addr] = Member(_addr, _name, true);
        memNum++;
        emit AddMember(_addr, _name);
    }
      
    function delMember(address _addr) public onlyOwners {
        require(owners[_addr].isValue);
        delete owners[_addr];
        memNum--;
        emit DelMember(_addr);
    }
}

contract Project is Owned {
    struct Phase {
        bytes32 phaseName;
        bytes32 updater;
        bytes32[] parents;
        bytes32[] urls;
        uint deadline;
        bytes32 dataHash;
        bool isUpdated;
        bool isValue;
    }
    
    mapping (bytes32 => Phase) public phases;
    uint public phaseNum = 0;
    
    event AddPhase(bytes32 _name);
    event AddRelations(bytes32 _name, bytes32[] _parents);
    event SetDeadline(bytes32 _name, uint _time);
    event UpdatePhase(bytes32 _name, bytes32[] _urls, bytes32 _dataHash);
      
    function addPhase(bytes32 _name) public onlyOwners {
        require(!phases[_name].isValue);
        phases[_name] = Phase(_name, "", new bytes32[](0), new bytes32[](0), 0, 0, false, true);
        phaseNum += 1;
        emit AddPhase(_name);
    }
    
    function addRelations(bytes32 _name, bytes32[] memory _parents) public onlyOwners {
        require(phases[_name].isValue && !phases[_name].isUpdated);
        uint parentsNum = _parents.length;
        for (uint i = 0; i < parentsNum; i++) {
            require(phases[_parents[i]].isValue);
            phases[_name].parents.push(_parents[i]);
        }
        emit AddRelations(_name, _parents);
    }
    
    function setDeadline(bytes32 _name, uint _time) public onlyOwners {
        require(phases[_name].isValue && !phases[_name].isUpdated);
        require(phases[_name].deadline == 0);
        phases[_name].deadline = _time;
        emit SetDeadline(_name, _time);
    }
    
    function updatePhase(bytes32 _name, bytes32[] memory _urls, bytes32 _dataHash) public onlyOwners {
          require(phases[_name].isValue && !phases[_name].isUpdated);
          require(phases[_name].deadline == 0 || now <= phases[_name].deadline);
          uint parentsNum = phases[_name].parents.length;
          for (uint i = 0; i < parentsNum; i++) {
              require(phases[phases[_name].parents[i]].isUpdated);
          }
          uint urlNum = _urls.length;
          for (uint i = 0; i < urlNum; i++) {
              phases[_name].urls.push(_urls[i]);
          }
          phases[_name].updater = owners[msg.sender].name;
          phases[_name].dataHash = _dataHash;
          phases[_name].isUpdated = true;
          emit UpdatePhase(_name, _urls, _dataHash);
    }
    
    function getUpdater(bytes32 _name) public view returns (bytes32) {
        return phases[_name].updater;    
    }
}

