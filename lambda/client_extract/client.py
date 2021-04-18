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
        print(req.content)
        if not req.content:
            return None
   except requests.exceptions.RequestException as e:
        raise SystemExit(e)
 
   return json.loads(req.content)[0]

def put_record(request):
    client = boto3.client('kinesis')
    event = api_request(request)

    try:
        response = client.put_record(
            StreamName=os.environ['STREAM_NAME'],
            Data=base64.b64encode(bytes(json.dumps(event), 'utf-8')),
            PartitionKey="1"
        )
        print(response)
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidArgumentException':
            print("Argument has invalid")

def lambda_handler(event, cont):
    try:
        url = os.environ['URL']
        put_record(url)

    except:
        print("error")
        