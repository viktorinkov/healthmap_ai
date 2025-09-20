-- PostgreSQL schema for health data
-- Run this script to set up the health monitoring database

CREATE DATABASE health_monitoring;
\c health_monitoring;

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fitbit_user_id VARCHAR(255) UNIQUE,
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Heart rate data (high frequency)
CREATE TABLE heart_rate_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    datetime TIMESTAMP NOT NULL,
    heart_rate INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Activity data
CREATE TABLE activity_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    datetime TIMESTAMP NOT NULL,
    steps INTEGER DEFAULT 0,
    distance DECIMAL(10,2) DEFAULT 0.0,
    calories INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- SpO2 data
CREATE TABLE spo2_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    datetime TIMESTAMP NOT NULL,
    spo2 DECIMAL(4,1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- HRV data
CREATE TABLE hrv_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    datetime TIMESTAMP NOT NULL,
    rmssd INTEGER,
    lf DECIMAL(10,2),
    hf DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Breathing rate data (daily summaries)
CREATE TABLE breathing_rate_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    date DATE NOT NULL,
    deep_sleep_br DECIMAL(4,1),
    rem_sleep_br DECIMAL(4,1),
    light_sleep_br DECIMAL(4,1),
    full_sleep_br DECIMAL(4,1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, date)
);

-- Create indexes for performance
CREATE INDEX idx_heart_rate_user_datetime ON heart_rate_data(user_id, datetime);
CREATE INDEX idx_activity_user_datetime ON activity_data(user_id, datetime);
CREATE INDEX idx_spo2_user_datetime ON spo2_data(user_id, datetime);
CREATE INDEX idx_hrv_user_datetime ON hrv_data(user_id, datetime);
CREATE INDEX idx_breathing_rate_user_date ON breathing_rate_data(user_id, date);