import json
import requests
import os
import boto3
import logging
import base64
from botocore.exceptions import ClientError

def api_request(request):
   try:
        req = requests.get(request)

        if not req.content:
            return None
   except requests.exceptions.RequestException as e:
        raise SystemExit(e)
 
   return json.loads(req.content)[0]

def put_record(request):
    client = boto3.client('firehose')
    event = api_request(request)

    try:
        response = client.put_record(
            DeliveryStreamName=os.environ['DELIVERY_STREAM'],
            Record={
                'Data': base64.urlsafe_b64encode(json.dumps(event).encode()).decode()
            }
        )
        print(response)
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidArgumentException':
            print("Argument has invalid")

def lambda_handler(event, context):
    req = os.environ['URL']
    put_record(req)
