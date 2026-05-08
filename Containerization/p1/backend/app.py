from flask import Flask, jsonify
from flask_cors import CORS 
import os 

app = Flask(__name__)
CORS(app)

@app.route('/data', methods=['GET'])
def get_data():
    return jsonify({"message": "Hello from the backend!"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)