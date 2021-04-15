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
 
   return json.loads(req.content)

def put_record(request):
    client = boto3.client('kinesis')
    event = api_request(request)

    try:
        response = client.put_record(
            StreamName=os.environ['STREAM_NAME'],
            Data=base64.b64encode(json.dumps(event[0]).encode('utf-8')),
            PartitionKey="1"
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidArgumentException':
            print("Argument has invalid")

def lambda_handler(event, cont):
    try:
        url = os.environ['URL']
        put_record(url)
        print(api_request(url))
    except Exception as inst:
        print(inst)
        