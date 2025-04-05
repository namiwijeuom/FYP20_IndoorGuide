from flask import Flask, request, jsonify
import tensorflow as tf
from tensorflow.keras.layers import Input, Embedding, MultiHeadAttention, LayerNormalization, Dense, Dropout, GlobalAveragePooling1D
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
import numpy as np
import json
from tensorflow.keras.models import load_model

model_path = 'C:/Users/Namina Wijetunga/Desktop/IndoorGuide/FYP20_IndoorGuide/Recommendation_Engine/Recommendation_Server/grocery_model_v6.h5'
config_path = 'C:/Users/Namina Wijetunga/Desktop/IndoorGuide/FYP20_IndoorGuide/Recommendation_Engine/Recommendation_Server/config_file_v6.json'

app = Flask(__name__)

class RecommendationServer:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.max_len = 113 # Placeholder values
        self.num_items = 382 # Placeholder values

    def build_model(self):
        """Build the model architecture from scratch"""
        inputs = Input(shape=(self.max_len,))
        
        # Embedding layer
        embedding = Embedding(
            input_dim=self.num_items,
            output_dim=128,
            mask_zero=False
        )(inputs)
        
        # Attention mask
        mask = tf.cast(tf.math.not_equal(inputs, 0), tf.float32)
        mask = mask[:, tf.newaxis, tf.newaxis, :]
        
        # Multi-head attention
        attn_output = MultiHeadAttention(
            num_heads=4,
            key_dim=32  # 128/4
        )(embedding, embedding, attention_mask=mask)
        
        attn_output = Dropout(0.2)(attn_output)
        out1 = LayerNormalization(epsilon=1e-6)(embedding + attn_output)
        
        # Feed forward
        ffn_output = Dense(256, activation="gelu")(out1)
        ffn_output = Dense(128)(ffn_output)
        out2 = LayerNormalization(epsilon=1e-6)(out1 + ffn_output)
        
        # Output
        pooled_output = GlobalAveragePooling1D()(out2)
        outputs = Dense(self.num_items, activation="softmax")(pooled_output)
        
        model = Model(inputs=inputs, outputs=outputs)
        model.compile(optimizer=Adam(0.001), loss='categorical_crossentropy')
        return model

    def load_model(self):
        try:
            # 1. Load the configuration file
            with open(config_path) as f:
                config = json.load(f)

            self.max_len = config['max_len']
            self.num_items = config['num_items']

            print(f"[INFO] Loaded tokenizer config: max_len={self.max_len}, num_items={self.num_items}")

            # 2. Load tokenizer
            self.tokenizer = tf.keras.preprocessing.text.tokenizer_from_json(
                config['tokenizer']
            )

            # 3. Build and load model architecture
            self.model = self.build_model()

            # 4. Load model weights
            self.model.load_weights(model_path)

            print(f"Model built and weights loaded! Input shape: {self.model.input_shape}")
            return True

        except Exception as e:
            print(f"Error loading model: {str(e)}")
            return False


    def recommend(self, items, top_k=5):
        if not items or not self.model or not self.tokenizer:
            return []
        
        try:
            seq = self.tokenizer.texts_to_sequences([' '.join(items)])
            if not seq or not seq[0]:
                return []
            
            padded_seq = pad_sequences(seq, maxlen=self.max_len, padding='pre')
            preds = self.model.predict(padded_seq, verbose=0)[0]
            top_indices = np.argsort(preds)[-top_k:][::-1]
            return [
                self.tokenizer.index_word[i] 
                for i in top_indices 
                if i in self.tokenizer.index_word and i != 0
            ]
        except Exception as e:
            print(f"Recommendation error: {str(e)}")
            return []

# Initialize server
server = RecommendationServer()

@app.route('/recommend', methods=['POST'])
def recommend():
    data = request.get_json()
    items = data.get('items', [])
    recommendations = server.recommend(items)
    return jsonify({
        "input_items": items,
        "recommendations": recommendations
    })

if __name__ == '__main__':
    if server.load_model():
        app.run(host='0.0.0.0', port=5000)
    else:
        print("Server failed to start due to model loading error")