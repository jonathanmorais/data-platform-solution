from flask import request
from flask import Flask
from flask_restful import Api, Resource, reqparse
import numpy as np
import requests
import json
import pickle
import requests
import pandas as pd
import joblib
from sklearn.model_selection import train_test_split
from app.input import athena_query_to_dataframe
import traceback

app = Flask(__name__)

lr = joblib.load('docker/workspace/model_punkbeer.pkl')
  
@app.route('/predict', methods=['POST'])
def predict():
    if lr:
        try:
            content = request.get_json()

            print(content)

            df = athena_query_to_dataframe(content["database"], content["prefix"], content["query"])

            X = df[['abv', 'target_fg', 'target_og', 'ebc', 'srm', 'ph']]
            y = df['ibu']
    
    
            X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.33)   
            
            prediction = list(lr.predict(X_test))

            return {'prediction': prediction}

        except:

            return {'trace': traceback.format_exc()}
    else:
        print ('Train the model first')
        return ('No model here to use')

    return 400

if __name__ == '__main__':
    app.run(debug=True, port='5001')