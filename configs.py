# config.py
import os

class Config:
    # Database configuration
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'sqlite:///bloodbank.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Secret key for JWT
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev_secret_key_change_in_production')
    
    # Debug mode
    DEBUG = os.environ.get('FLASK_ENV') == 'development'