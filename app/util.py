import hashlib
import os

def sha256sum(s):
    m = hashlib.sha256()
    m.update(s.encode())
    return m.hexdigest()

def get_records(d):
    phase_name = d['phaseName']
    phase_dir = sha256sum(phase_name)[:8]
    phase_path = 'app/static/logs/{}'.format(phase_dir)
    if not os.path.exists(phase_path):
        return ''

    filename_l = os.listdir(phase_path)
    filename_l = sorted(map(int, filename_l))

    record_all_text = ''
    for record_dir in filename_l:
        record_path = '{}/{}'.format(phase_path, record_dir)
        with open('{}/text'.format(record_path), 'r') as f:
            record_text = f.read()
        with open('{}/metadata'.format(record_path), 'r') as f:
            record_metadata = f.read()
        record_all_text += '{}\n{}\n\n'.format(record_metadata, record_text)
    return record_all_text

def add_record(d):
    phase_name = d['phaseName']
    record_name = d['recordName']
    record_text = d['recordText']
    record_data_hash = d['recordDataHash']
    record_timestamp = d['recordTimestamp']
    record_author = d['recordAuthor'];

    phase_dir = sha256sum(phase_name)[:8]
    phase_path = 'app/static/logs/{}'.format(phase_dir)
    os.makedirs(phase_path, exist_ok=True)

    filename_l = os.listdir(phase_path)
    record_dir = str(len(filename_l))
    record_path = '{}/{}'.format(phase_path, record_dir)
    os.makedirs(record_path, exist_ok=True)

    record_metadata = '''Record name: {}
Record data hash: {}
Record timestamp: {}
Author: {}
'''.format(record_name, record_data_hash, record_timestamp, record_author)

    with open('{}/text'.format(record_path), 'w') as f:
        f.write(record_text)
    with open('{}/metadata'.format(record_path), 'w') as f:
        f.write(record_metadata)
    return 'logs/{}/{}/text'.format(phase_dir, record_dir)
