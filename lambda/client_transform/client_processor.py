from __future__ import print_function
import json
import base64
import dask as dd

print('Loading function')


def lambda_handler(event, context):
    output = []

    for record in event['records']:
        payload = base64.b64decode(record['data'])
        pay = json.loads(base64.b64decode(payload).decode('ascii'))

        cleaned = {
            "id": pay['id'],
            "name": pay['name'],
            "abv": pay['abv'],
            "ibu": pay['ibu'],
            "target_fg": pay['target_fg'],
            "target_og": pay['target_og'],
            "ebc": pay['ebc'],
            "srm": pay['srm'],
            "ph": pay['ph']
        }

        print(cleaned)

        df = dd.read_json(cleaned).to_csv("cleaned.csv", index = None)

        output_record = {
            'recordId': record['recordId'],
            'result': 'Ok',
            'data': base64.b64encode(payload)
        }
        output.append(output_record)

    print('Successfully processed {} records.'.format(len(event['records'])))

    return df