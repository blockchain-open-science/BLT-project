pragma solidity ^0.5.12;
// version 2.4

contract Owned {
    struct Member {
        bytes32 name;
        bool isValue;
    }
    
    address[] ownerAddrs;
    mapping (address => Member) public owners;
    
    event AddMember(address _addr, bytes32 _name);
    event DelMember(address _addr);
      
    constructor() public {
        owners[msg.sender] = Member("Admin", true);
        ownerAddrs.push(msg.sender);
    }
    
    modifier onlyOwners {
        require(owners[msg.sender].isValue, "sender should be in owner list");
        _;
    }
    
    function getOwnerAddrs() public view returns(address[] memory) {
        return ownerAddrs;
    }
    
    function addMember(address _addr, bytes32 _name) public onlyOwners {
        require(!owners[_addr].isValue, "address should not be in owner list");
        ownerAddrs.push(_addr);
        owners[_addr] = Member(_name, true);
        emit AddMember(_addr, _name);
    }
      
    function delMember(address _addr) public onlyOwners {
        require(owners[_addr].isValue, "address should be in owner list");
        for (uint i = 0; i < ownerAddrs.length; i++) {
            if (ownerAddrs[i] == _addr) {
                ownerAddrs[i] = ownerAddrs[ownerAddrs.length-1];
                break;
            }
        }
        ownerAddrs.length--;
        delete owners[_addr];
        emit DelMember(_addr);
    }
}

contract Project is Owned {
    struct Record {
        bytes32 recordName;
        
        /* Artifact */
        bytes32 dataHash;
        bytes32 dataUrl;
        
        /* Metadata */
        uint dataType;
        uint timestamp;
        bytes32 signature;
    }
    
    struct TimeConstraint {
        uint afterTime;
        uint beforeTime;
    }
    
    struct Agreement {
        address agreedAddr;
        uint8 signatureV;
        bytes32 signatureR;
        bytes32 signatureS;
    }
    
    struct Phase {
        bytes32 phaseName;
        bytes32 phaseHash;
        Record[] records;
        TimeConstraint[] timeConstraints;
        Agreement[] agreements;
        bytes32 committer;
        uint committedTime;
        bool isCommitted;
        bool isValue;
    }
    
    struct PhaseDependency {
        bytes32 phaseFirstName;
        bytes32 phaseSecondName;
        uint afterTime;
        uint beforeTime;
    }
    
    bytes32 public projectName;
    bytes32[] phaseNames;
    mapping (bytes32 => Phase) public phases;
    PhaseDependency[] public phaseDependencies;
    
    bool public isFrozen;
    bool public isVerified;
    
    event AddPhaseRecord(bytes32, bytes32, bytes32, bytes32, uint, uint, bytes32);
    event CommitPhase(bytes32);
    event AddAgreement(bytes32, uint8, bytes32, bytes32);
    event AddPhase(bytes32);
    event AddPhaseDependency(bytes32, bytes32, uint, uint);
    event AddTimeConstraint(uint, uint);
    
    constructor(bytes32 _name, bool _isFrozen) public onlyOwners {
        projectName = _name;
        isFrozen = _isFrozen;
        // initialize contract template here
    }
    
    /* Phase operations */
    function addPhaseRecord(bytes32 _phaseName, bytes32 _recordName, bytes32 _dataHash, bytes32 _dataURL, uint _dataType, uint _timestamp, bytes32 _signature) public onlyOwners {
        Phase storage p = phases[_phaseName];
        require(p.isValue, "phase should exist");
        require(!p.isCommitted, "phase should not be committed before");
        p.records.push(Record(_recordName, _dataHash, _dataURL, _dataType, _timestamp, _signature));
        emit AddPhaseRecord(_phaseName, _recordName, _dataHash, _dataURL, _dataType, _timestamp, _signature);
    }
    
    function commitPhase(bytes32 _name) public onlyOwners {
        Phase storage p = phases[_name];
        require(p.isValue, "phase should exist");
        require(!p.isCommitted, "phase should not be committed before");
        p.committer = owners[msg.sender].name;
        p.committedTime = now;
        p.isCommitted = true;
        emit CommitPhase(_name);
    }
    
    function addAgreement(bytes32 _name, uint8 _signatureV, bytes32 _signatureR, bytes32 _signatureS) public onlyOwners {
        Phase storage p = phases[_name];
        require(p.isValue, "phase should exist");
        require(!p.isCommitted, "phase should not be committed before");
        p.agreements.push(Agreement(msg.sender, _signatureV, _signatureR, _signatureS));
        emit AddAgreement(_name, _signatureV, _signatureR, _signatureS);
    }
    
    function calculatePhaseHash(bytes32 _name) public onlyOwners {
        Phase storage p = phases[_name];
        require(p.isValue, "phase should exist");
        bytes32[] memory recordHashes = new bytes32[](p.records.length);
        for (uint i = 0; i < p.records.length; i++) {
            recordHashes[i] = p.records[i].dataHash;
        }
        p.phaseHash = keccak256(abi.encodePacked(recordHashes));
    }
    
    /* Project operations */
    function getPhaseNames() public view returns(bytes32[] memory) {
        return phaseNames;
    }
    
    function addPhase(bytes32 _name) public onlyOwners {
        require(!isFrozen, "project should not be frozen");
        Phase storage p = phases[_name];
        require(!phases[_name].isValue, "phase should not exist before");
        phaseNames.push(_name);
        p.phaseName = _name;
        p.isValue = true;
        emit AddPhase(_name);
    }
    
    function addPhaseDependency(bytes32 _first, bytes32 _second, uint _after, uint _before) public onlyOwners {
        require(!isFrozen, "project should not be frozen");
        Phase storage p_first = phases[_first];
        Phase storage p_second = phases[_second];
        require(p_first.isValue, "phase should exist");
        require(p_second.isValue, "phase should exist");
        require(!p_second.isCommitted, "phase should not be committed before");
        phaseDependencies.push(PhaseDependency(_first, _second, _after, _before));
        emit AddPhaseDependency(_first, _second, _after, _before);
    }
    
    function addTimeConstraint(bytes32 _name, uint _after, uint _before) public onlyOwners {
        require(!isFrozen, "project should not be frozen");
        Phase storage p = phases[_name];
        require(p.isValue, "phase should exist");
        require(!p.isCommitted, "phase should not be committed before");
        p.timeConstraints.push(TimeConstraint(_after, _before));
        emit AddTimeConstraint(_after, _before);
    }
    
    /* Verify */
    function verifyPhaseDependencies() public view returns(bool) {
        for (uint i = 0; i < phaseDependencies.length; i++) {
            PhaseDependency storage pd = phaseDependencies[i];
            Phase storage p_first = phases[pd.phaseFirstName];
            Phase storage p_second = phases[pd.phaseSecondName];
            if (!p_second.isCommitted) {
                continue;
            }
            if (!p_first.isCommitted) {
                return false;
            }
            if (pd.afterTime > 0 && !(p_first.committedTime + pd.afterTime < p_second.committedTime)) {
                return false;
            }
            if (pd.beforeTime > 0 && !(p_first.committedTime + pd.beforeTime > p_second.committedTime)) {
                return false;
            }
        }
        return true;
    }
    
    function verifyTimeConstraints(bytes32 _name) public view returns(bool) {
        Phase storage p = phases[_name];
        if (!p.isCommitted) {
            return true;
        }
        for (uint i = 0; i < p.timeConstraints.length; i++) {
            TimeConstraint storage tc = p.timeConstraints[i];
            if (tc.afterTime > 0 && p.committedTime < tc.afterTime) {
                return false;
            }
            if (tc.beforeTime > 0 && p.committedTime > tc.beforeTime) {
                return false;
            }
        }
        return true;
    }
    
    function verifyAgreement(bytes32 _name) public view returns(bool) {
        Phase storage p = phases[_name];
        if (!p.isCommitted) {
            return true;
        }
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixHash = keccak256(abi.encodePacked(prefix, p.phaseHash));
        uint len = p.agreements.length;
        bool result = true;
        for (uint i = 0; i < len; i++) {
            address signedAddr = ecrecover(prefixHash, p.agreements[i].signatureV, p.agreements[i].signatureR, p.agreements[i].signatureS);
            if (signedAddr != p.agreements[i].agreedAddr) {
                result = false;
            }
        }
        return result;
    }
}
