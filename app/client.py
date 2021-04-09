import json
import requests

def api_request(request):
   try:
        req = requests.get(request)

        if not req.content:
            return None
   except requests.exceptions.RequestException as e:
        raise SystemExit(e)
 
   return json.loads(req.content)[0]

if __name__ == '__main__':
    request = 'https://api.punkapi.com/v2/beers/random'
    api_request(request)