from __future__ import print_function
import json
import base64
import csv
import pandas as pd
import numpy

print('Loading function')


def lambda_handler(event, context):
    output = []    
    succeeded_record_cnt = 0
    failed_record_cnt = 0

    for record in event['records']:
        print(record['recordId'])
        payload = base64.b64decode(record['data']).decode('utf-8')
        payload = base64.b64decode(payload)
        payload = json.loads(payload)

        cleaned = {
            "id": payload['id'],
            "name": payload['name'],
            "abv": payload['abv'],
            "ibu": payload['ibu'],
            "target_fg": payload['target_fg'],
            "target_og": payload['target_og'],
            "ebc": payload['ebc'],
            "srm": payload['srm'],
            "ph": payload['ph']
        }

        json_csv = pd.json_normalize(cleaned)
     
        output_record = {
            'recordId': record['recordId'],
            'result': 'Ok',
            'data': base64.b64encode(json_csv.to_csv().encode('utf-8')).decode('utf-8')
        }
        
        output.append(output_record)
    print('Processing completed.  Successful records {}, Failed records {}.'.format(succeeded_record_cnt, failed_record_cnt))
    print(output)
    return {'records': output}
