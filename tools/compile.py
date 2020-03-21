from solcx import get_solc_version, compile_source
import sys

# Install solc first
# >>> import solcx
# >>> solcx.install_solc('v0.5.12')
# solc, the solidity compiler commandline interface
# Version: 0.5.12+commit.7709ece9.Linux.g++

if len(sys.argv) < 4:
    print('Compile a contract and output its ABI and bytecode to a js file')
    print('Usage: python3 {} src_file cont_ver js_file'.format(sys.argv[0]))
    exit()

src_file, cont_ver, js_file = sys.argv[1:]
print('Compile version: {}'.format(get_solc_version()))

with open(src_file, 'r') as f:
    source = f.read()
compiled_sol = compile_source(source)
_, cont_if = compiled_sol.popitem()

js_content = '''
const contractVersion = '{}';
const contractABI = {};
const contractBytecode = "{}";
'''.format(cont_ver, cont_if['abi'], cont_if['bin'])

js_content = js_content.replace('True', 'true')
js_content = js_content.replace('False', 'false')

with open(js_file, 'w') as f:
    f.write(js_content)
