from flask import Flask, request, jsonify
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import load_model
from tensorflow.keras.layers import InputLayer
import h5py
import logging
import json

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

# Load items list (make sure this matches your training data)
with open('Mobile_Application/IndoorGuide_App/items_v3.json', 'r') as f:
    item_data = json.load(f)
    items = item_data['items']

def safe_load_model(model_path):
    try:
        # First try standard loading
        return load_model(model_path)
    except Exception as e:
        logging.warning(f"Standard load failed: {e}")
        try:
            # Try with custom objects
            return load_model(model_path, custom_objects={'InputLayer': InputLayer})
        except Exception as e:
            logging.error(f"Failed to load model: {e}")
            return None

# Load model
model = safe_load_model(
    'C:/Users/Namina Wijetunga/Desktop/IndoorGuide/FYP20_IndoorGuide/Recommendation_Engine/For_the_Mobile_Application/grocery_model_v6.h5'
)

if model is None:
    logging.error("Could not load the model. Exiting.")
    exit(1)

@app.route('/recommend', methods=['POST'])
def recommend():
    try:
        data = request.json
        selected_items = data.get('items', [])
        
        # Create input vector
        input_vector = np.zeros(len(items))
        for item in selected_items:
            if item in items:
                input_vector[items.index(item)] = 1
                
        # Get predictions
        predictions = model.predict(input_vector.reshape(1, -1))[0]
        
        # Get top recommendations (excluding selected items)
        recommended_indices = np.argsort(predictions)[::-1]
        recommendations = [
            items[idx] for idx in recommended_indices 
            if items[idx] not in selected_items
        ][:3]  # Top 3
        
        return jsonify({
            'status': 'success',
            'recommendations': recommendations
        })
        
    except Exception as e:
        logging.error(f"Recommendation error: {e}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)