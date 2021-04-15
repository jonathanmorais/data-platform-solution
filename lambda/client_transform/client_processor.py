from __future__ import print_function
import json
import base64
import csv
import re
import pandas as pd

print('Loading function')

def lambda_handler(event, context):
    get_transform(event)

def get_transform(event):

    output = []    
    succeeded_record_cnt = 0
    failed_record_cnt = 0

    r = re.compile(r'[A-Za-z0-9+/=]')
    m = r.match(event['records'][0]['data'])

    if m:
        for record in event['records']:
            print(record['recordId'])
            payload = json.loads(base64.b64decode(record['data']))
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
            print(json_csv)
        
            output_record = {
                'recordId': record['recordId'],
                'result': 'Ok',
                'data': base64.b64encode(json_csv.to_csv().encode('utf-8')).decode('utf-8')
            }

            output.append(output_record)

            succeeded_record_cnt = 1
        
        print(output_record)
        print('Processing completed.  Successful records {}, Failed records {}.'.format(succeeded_record_cnt, failed_record_cnt))
        return {'records': output}

    else:
        failed_record_cnt = 1

        print('Processing completed.  Successful records {}, Failed records {}.'.format(succeeded_record_cnt, failed_record_cnt))
        return
