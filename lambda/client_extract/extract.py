import json
import requests
import os
import boto3
import logging
import base64
import datetime
from botocore.exceptions import ClientError

def lambda_handler(event, cont):
    try:
        url = os.environ['URL']
        put_record(event)
    except Exception as e:
        print(e)

def api_request(request):
   try:
        req = requests.get(request)
        if not req.content:
            return None
   except requests.exceptions.RequestException as e:
        raise SystemExit(e)
 
   return json.loads(req.content)[0]

def generate_partition():
    time = str(datetime.datetime.now().timestamp())
    return time 

def put_record(request):
    client = boto3.client('kinesis')
    partition_key = generate_partition()
    request = api_request(request)
    event = json.dumps(event)
    
    ## usei isto para simular a entrada do evento pelo cloudwatch, pois a api punkapi, esta retornando erro    
    # event = request[0]
    # payload  = json.dumps(event)

    try:
        response = client.put_record(
            StreamName=os.environ['STREAM_NAME'],
            Data=event,
            PartitionKey=partition_key
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidArgumentException':
            print("Argument has invalid")