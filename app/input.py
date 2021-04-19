import boto3
import pandas as pd
import os

def athena_query_to_dataframe(db, s3Bucket, query):
    
    
    listOfStatus = ['SUCCEEDED', 'FAILED', 'CANCELLED']
    listOfInitialStatus = ['RUNNING', 'QUEUED']

    print('Starting Query Execution:')

    tempS3Path = 's3://{}'.format(s3Bucket)

    client   = boto3.client('athena', region_name='us-east-1', aws_access_key_id=os.environ['ACCESS_KEY'],
                                aws_secret_access_key=os.environ['ACCESS_SECRET_KEY'])


    response = client.start_query_execution(
        QueryString = query,
        QueryExecutionContext = {
            'Database': db
        },
        ResultConfiguration = {
            'OutputLocation': tempS3Path,
        }
    )

    queryExecutionId = response['QueryExecutionId']

    status = client.get_query_execution(QueryExecutionId = queryExecutionId)['QueryExecution']['Status']['State']

    while status in listOfInitialStatus:
        status = client.get_query_execution(QueryExecutionId = queryExecutionId)['QueryExecution']['Status']['State']
        if status in listOfStatus:
            if status == 'SUCCEEDED':
                print('Query Succeeded!')
                paginator = client.get_paginator('get_query_results')
                query_results = paginator.paginate(
                    QueryExecutionId = queryExecutionId,
                    PaginationConfig = {'PageSize': 1000}
                )
            elif status == 'FAILED':
                print('Query Failed!')
            elif status == 'CANCELLED':
                print('Query Cancelled!')
            break

    results = []
    rows = []

    print('Processing Response')

    for page in query_results:
        for row in page['ResultSet']['Rows']:
            rows.append(row['Data'])

    columns = rows[0]
    rows = rows[1:]

    columns_list = []
    for column in columns:
        columns_list.append(column['VarCharValue'])
        
    print('Creating Dataframe')

    dataframe = pd.DataFrame(columns = columns_list)

    for row in rows:
        df_row = []
        try:
            for data in row:
                df_row.append(data['VarCharValue'])
            dataframe.loc[len(dataframe)] = df_row
        except:
            pass
        
    return dataframe  