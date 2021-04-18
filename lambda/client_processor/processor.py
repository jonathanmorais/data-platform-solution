from __future__ import print_function
import json
import base64
import re
import csv
from io import StringIO
import sys

print('Loading function')

def lambda_handler(event, context):

    output = []    
    succeeded_record_cnt = 0
    failed_record_cnt = 0

    for record in event['records']:
        print(record['data'])
        payload = json.loads(base64.b64decode(record['data'].encode()).decode())
        
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
       
        data = []

        for key, value in cleaned.items():
            data.append(value)      
        
        payload = ','.join([str(elem) for elem in data])

        output_record = {
            'recordId': record['recordId'],
            'result': 'Ok',
            'data': base64.b64encode(payload.encode('utf-8')).decode('utf-8')
        }

        output.append(output_record)
        
        succeeded_record_cnt = 1
        
        print('Processing completed.  Successful records {}, Failed records {}.'.format(succeeded_record_cnt, failed_record_cnt))

        return {'records': output}