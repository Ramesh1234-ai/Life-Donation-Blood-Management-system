# models.py
from flask_sqlalchemy import SQLAlchemy
import datetime

db = SQLAlchemy()

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.String(36), primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), default='user')  # user, donor, admin
    created_at = db.Column(db.DateTime, default=datetime.datetime.now)
    
    def __repr__(self):
        return f"<User {self.email}>"

class Donor(db.Model):
    __tablename__ = 'donors'
    
    id = db.Column(db.String(36), primary_key=True)
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    blood_type = db.Column(db.String(10))
    last_donation_date = db.Column(db.DateTime)
    medical_conditions = db.Column(db.Text)
    is_available = db.Column(db.Boolean, default=True)
    
    def __repr__(self):
        return f"<Donor {self.id}>"

class BloodRequest(db.Model):
    __tablename__ = 'blood_requests'
    
    id = db.Column(db.String(36), primary_key=True)
    requester_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    blood_type = db.Column(db.String(10), nullable=False)
    quantity = db.Column(db.Float, nullable=False)
    urgency = db.Column(db.String(20), nullable=False)  # high, medium, low
    hospital = db.Column(db.String(200), nullable=False)
    contact_number = db.Column(db.String(20), nullable=False)
    notes = db.Column(db.Text)
    request_date = db.Column(db.DateTime, default=datetime.datetime.now)
    status = db.Column(db.String(20), default='pending')  # pending, fulfilled, cancelled
    
    def __repr__(self):
        return f"<BloodRequest {self.id}>"

class Donation(db.Model):
    __tablename__ = 'donations'
    
    id = db.Column(db.String(36), primary_key=True)
    donor_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    donation_date = db.Column(db.DateTime, nullable=False)
    blood_type = db.Column(db.String(10), nullable=False)
    quantity = db.Column(db.Float, nullable=False)
    location = db.Column(db.String(200), nullable=False)
    notes = db.Column(db.Text)
    
    def __repr__(self):
        return f"<Donation {self.id}>"