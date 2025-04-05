# recommendation_server.py
from flask import Flask, request, jsonify
import numpy as np
from tensorflow.keras.models import load_model
from tensorflow.keras.layers import InputLayer
from tensorflow.keras import Input

def custom_input_layer(config):
    # Convert batch_shape to shape if present
    if 'batch_shape' in config:
        config['shape'] = config['batch_shape'][1:]
        del config['batch_shape']
    return Input(**config)

model_path = 'C:/Users/Namina Wijetunga/Desktop/IndoorGuide/FYP20_IndoorGuide/Recommendation_Engine/Recommendation_Server/grocery_model_v6.h5'
tolkenizer_path = 'C:/Users/Namina Wijetunga/Desktop/IndoorGuide/FYP20_IndoorGuide/Recommendation_Engine/Recommendation_Server/tokenizer_v6.json'

app = Flask(__name__)
try:
    model = load_model(model_path, custom_objects={'InputLayer': custom_input_layer})
            
except Exception as e:
    print(f"Error: {e}")

app = Flask(__name__)
@app.route('/recommend', methods=['POST'])
def recommend():
    data = request.json
    selected_items = data.get('items', [])
    
    # Create input vector
    input_vector = np.zeros(len(selected_items))  # You'll need to share the items list

    for item in selected_items:
        if item in selected_items:
            input_vector[selected_items.index(item)] = 1
            
    # Get predictions
    predictions = model.predict(input_vector.reshape(1, -1))[0]
    
    # Get top recommendations
    recommended_indices = np.argsort(predictions)[::-1]
    recommendations = []
    for idx in recommended_indices:
        item = selected_items[idx]
        if item not in selected_items and len(recommendations) < 3:
            recommendations.append(item)
        if len(recommendations) >= 3:
            break
            
    return jsonify({'recommendations': recommendations})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)