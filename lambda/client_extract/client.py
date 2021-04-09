import json
import requests
import os
import boto3
import logging

def api_request(request):
   try:
        req = requests.get(request)

        if not req.content:
            return None
   except requests.exceptions.RequestException as e:
        raise SystemExit(e)
 
   return json.loads(req.content)[0]

def put_record():
    client = boto3.client('firehose')
    event = api_request()

    try:
        response = client.put_record(
            DeliveryStreamName=os.environ['DELIVERY_STREAM'],
            Record={
                'Data': event.encode('base64', 'strict')
            }
        )
    except client.Firehose.Client.exceptions.InvalidArgumentException:
            logging.exception("Argument not found")

if __name__ == '__main__':
    request = os.environ['URL']
    api_request(request)