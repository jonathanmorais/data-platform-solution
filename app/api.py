from flask import Flask
from flask_restful import Api, Resource, reqparse
import joblib
import numpy as np

APP = Flask(__name__)
API = Api(APP)

MODEL = joblib.load('docker/workspace/model_punkbeer.sav')

class Predict(Resource):

    @staticmethod
    def post():
        parser = reqparse.RequestParser()
        parser.add_argument('petal_length')
        parser.add_argument('petal_width')
        parser.add_argument('sepal_length')
        parser.add_argument('sepal_width')

        args = parser.parse_args()  # creates dict

        X_new = np.fromiter(args.values(), dtype=float)  # convert input to array

        out = {'Prediction': MODEL}

        return out, 200


API.add_resource(Predict, '/predict')

if __name__ == '__main__':
    APP.run(debug=True, port='1080')