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

    // display user's ethereum address
    setInterval(function () {
      if (web3.eth.defaultAccount === undefined) {
        web3.eth.defaultAccount = web3.eth.accounts[0];
      }
      $('#eth_addr').text(web3.eth.defaultAccount);

      // get name or role of current user
      myProject.owners([web3.eth.defaultAccount], function(err, res) {
        if (!err) {
          var ownerName = null;
          if (res[1]) {
            ownerName = web3.toAscii(res[0]);
          }
          $('#owner_name').text(ownerName);
        }
      });
    }, 1000);

    // display current project name
    function showProjectName() {
      myProject.projectName([], function(err, res) {
        if (!err) {
          var projectName = web3.toAscii(res);
          $('#project_name').text(projectName);
        }
      });
    }

    // display all existing phase names in the current project
    function showPhaseNames() {
      myProject.getPhaseNames([], function(err, res) {
        if (!err) {
          $('#cur_phase_select').empty();
          $('#cur_phase_select').append(
            $('<option>').attr('value', '').text('Select a phase')
          );
          var phaseNames = res.map(s => web3.toAscii(s));
          phaseNames.forEach(function(name) {
            $('#cur_phase_select').append(
              $('<option>').attr('value', name).text(name)
            );
          });
          phaseNames = phaseNames.join(', ');
          if (phaseNames == '') {
            phaseNames = 'No existing phases';
          }
          $('#phase_names').text(phaseNames);
        }
      });
    }

    // set the address of contract
    // TODO: contract ABI should be given
    $('#contract_addr_btn').click(function() {
      contractAddr = $('#contract_addr_input').val();
      myProject.atAddress(contractAddr, contractABI, function(err, res) {
        if (!err) {
          console.log(res);
          $('#contract_addr_input').val('');
          $('#contract_addr').text(contractAddr);
        }
      });
      showProjectName();
      showPhaseNames();
    });

    // debug
    if (0) {
      const contractAddr = '';
      $('#contract_addr_input').val(contractAddr);
      $('#contract_addr_btn').click();
    }

    function showPhaseRecords(node, phaseName) {
      $.ajax({
        'type': 'GET',
        url: '/logger/get_records',
        data: {
          'phaseName': phaseName
        },
        success: function(data) {
          if (data === '') {
            data = 'No existing records';
          }
          node.text(data);
        },
        error: function() {
          alert('Server error!');
        }
      });
    }

    // get records of current working phase
    $('#cur_phase_btn').click(function() {
      var phaseName = $('#cur_phase_select').val();
      showPhaseRecords($('#phase_records'), phaseName);
    });

    // calculate record hash by record data
    $('#cal_record_hash_btn').click(function() {
      var recordText = $('#add_record_input').val();
      var recordDataHash = sha256(recordText);
      $('#record_hash').text(recordDataHash);
    });

    // add a new record to a chosen phase
    $('#add_record_btn').click(function() {
      var recordText = $('#add_record_input').val();
      var phaseName = $('#cur_phase_select').val();
      var recordName = $('#add_record_name_input').val();
      var recordDataHash = sha256(recordText);
      var recordDataURL = '';
      var recordDataType = 0; // static data
      var recordTimestamp = Math.floor(Date.now() / 1000);
      var recordSignature = '';
      var recordAuthor = $('#owner_name').text();
      $('#record_hash').text(recordDataHash);

      // sanity check
      if (phaseName === '') {
        alert('Please select current working phase');
        return;
      }
      else if (recordName === '') {
        alert('Please input record name');
        return;
      }

      // post record data to server
      $.ajax({
        'type': 'POST',
        url: '/logger/add_record',
        data: {
          'phaseName': phaseName,
          'recordName': recordName,
          'recordText': recordText,
          'recordDataHash': recordDataHash,
          'recordTimestamp': recordTimestamp,
          'recordAuthor': recordAuthor
        },
        success: function(data) {
          showPhaseRecords($('#phase_records'), phaseName);
          $('#add_record_name_input').val('');
          $('#add_record_input').val('')
          recordDataURL = data;

          // send transaction to contract
          myProject.addPhaseRecord([phaseName, recordName, recordDataHash, recordDataURL, recordDataType, recordTimestamp, recordSignature], function(err, res) {
            if (!err) {
              console.log(res);
            }
          }, function(err, res) {
            if (!err) {
              console.log(res);
            }
          });
        },
        error: function() {
          alert('Server error!');
        }
      });
    });

    // commit a phase
    $('#commit_phase_btn').click(function() {
      var phaseName = $('#commit_phase_input').val();
      myProject.commitPhase([phaseName], function(err, res) {
        if (!err) {
          console.log(res);
          $('#commit_phase_input').val('');
        }
      }, function(err, res) {
        if (!err) {
          console.log(res);
        }
      });
    });

    // add a new phase to the project
    $('#add_phase_btn').click(function() {
      var phaseName = $('#add_phase_input').val();
      myProject.addPhase([phaseName], function(err, res) {
        if (!err) {
          console.log(res);
          $('#add_phase_input').val('');
        }
      }, function(err, res) {
        if (!err) {
          console.log(res);
          showPhaseNames();
        }
      });
    });

    // calculate the hash of a phase according to its records' data hash
    $('#cal_phase_hash_btn').click(function() {
      var phaseName = $('#cal_phase_hash_input').val();
      myProject.calculatePhaseHash([phaseName], function(err, res) {
        if (!err) {
          console.log(res);
        }
      });
    });

    function genPhaseInfo(data) {
      var text = '';
      text += 'Name: ' + web3.toAscii(data[0]) + '<br>';
      text += 'Hash: ' + data[1] + '<br>';
      text += 'Committer: ' + web3.toAscii(data[2]) + '<br>';
      text += 'Committed time: ' + data[3] + '<br>';
      text += 'Committed: ' + data[4] + '<br>';
      text += 'Exists: ' + data[5] + '<br>';
      return text
    }

    // Get the information of a phase
    $('#phase_info_btn').click(function() {
      var phaseName = $('#phase_info_input').val();
      myProject.phases([phaseName], function(err, res) {
        if (!err) {
          console.log(res);
          $('#phase_info').html(genPhaseInfo(res));
        }
      });
    });

    // Connect to MetaMask
    $('#eth_enable').click(function() {
      window.ethereum.enable();
    });
  }
  else {
    alert('No currentProvider for web3');
  }
});
