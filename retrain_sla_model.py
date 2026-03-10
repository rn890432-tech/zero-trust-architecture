import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow import keras
import os

def load_data():
    # Load incidents and breaches
    incidents_df = pd.read_csv('automation/incidents.csv')
    breaches_df = pd.read_csv('automation/sla_breaches.csv')
    # Aggregate incidents per day
    incidents_df['Day'] = pd.to_datetime(incidents_df['Time'], format='%H:%M').dt.date
    incident_counts = incidents_df.groupby('Day').size()
    # Aggregate breaches per day
    breaches_df['Day'] = pd.to_datetime(breaches_df['Time'], format='%H:%M').dt.date
    breach_days = set(breaches_df['Day'])
    # Build labeled dataset
    days = sorted(set(incident_counts.index) | breach_days)
    X = np.array([incident_counts.get(day, 0) for day in days]).reshape(-1, 1)
    y = np.array([1 if day in breach_days else 0 for day in days]).reshape(-1, 1)
    return X, y, days

def retrain_model():
    X, y, days = load_data()
    model = keras.Sequential([
        keras.layers.Dense(1, input_shape=(1,), activation='sigmoid')
    ])
    model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
    model.fit(X, y, epochs=50, verbose=0)
    model.save('sla_model')
    # Evaluate accuracy
    loss, acc = model.evaluate(X, y, verbose=0)
    print(f"Model accuracy: {acc*100:.2f}%")
    # Log accuracy
    with open('sla_model_accuracy.txt', 'w') as f:
        f.write(f"{acc*100:.2f}")

if __name__ == '__main__':
    retrain_model()
