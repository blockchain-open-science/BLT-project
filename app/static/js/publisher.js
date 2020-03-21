var myProject = null;

$(document).ready(function () {
  // initialize web3
  if (typeof web3 !== 'undefined') {
    web3 = new Web3(web3.currentProvider);
    console.log('web3 initialized');

    // initialize project
    myProject = new BLTProject(function(err, res) {
      if (!err) console.log(res);
    });

    // debug
    if (0) {
      const contractAddr = '';
      $('#contract_addr').text(contractAddr);
      myProject.atAddress(contractAddr, contractABI, function(err, res) {
        if (!err) console.log(res);
      });
    }

    // show user's ethereum address
    $('#eth_addr').text(web3.eth.defaultAccount);

    // deploy a new contract
    $('#deploy_default_btn').click(function () {
      var projectName = $('#deploy_name_input').val();
      var isFrozen = $('#deploy_is_frozen_cb').prop('checked');
      console.log(isFrozen);
      myProject.deploy([projectName, isFrozen], contractABI, contractBytecode, function(err, res) {
        if (!err) {
          $('#contract_addr').text(myProject.contractAddr);
        }
      });
    });
  }
  else {
    alert('No currentProvider for web3');
  }

});
