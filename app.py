# app.py
from flask import Flask, request, jsonify, make_response
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import jwt
import datetime
import uuid
from functools import wraps
import os
from database import db, User, Donor, BloodRequest, Donation
from config import Config

# Initialize Flask app
app = Flask(__name__)
app.config.from_object(Config)

# Enable CORS
CORS(app)

# Initialize database
db.init_app(app)

# Create tables
with app.app_context():
    db.create_all()

# Token authentication decorator
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Check if token is in headers
        if 'Authorization' in request.headers:
            token = request.headers['Authorization'].split(" ")[1]
        
        if not token:
            return jsonify({'message': 'Token is missing!'}), 401
        
        try:
            # Decode token
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            current_user = User.query.filter_by(id=data['user_id']).first()
        except:
            return jsonify({'message': 'Token is invalid!'}), 401
            
        return f(current_user, *args, **kwargs)
    
    return decorated

# Routes
@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.get_json()
    
    # Check if user already exists
    existing_user = User.query.filter_by(email=data['email']).first()
    if existing_user:
        return jsonify({'message': 'User already exists!'}), 400
    
    # Hash password
    hashed_password = generate_password_hash(data['password'], method='pbkdf2:sha256')
    
    # Create new user
    new_user = User(
        id=str(uuid.uuid4()),
        name=data['name'],
        email=data['email'],
        password=hashed_password,
        role=data.get('role', 'user'),
        created_at=datetime.datetime.now()
    )
    
    # Add user to database
    db.session.add(new_user)
    db.session.commit()
    
    # Create donor profile if role is donor
    if data.get('role') == 'donor':
        new_donor = Donor(
            id=str(uuid.uuid4()),
            user_id=new_user.id,
            blood_type=data.get('blood_type', ''),
            last_donation_date=None,
            medical_conditions=data.get('medical_conditions', ''),
            is_available=True
        )
        db.session.add(new_donor)
        db.session.commit()
    
    return jsonify({'message': 'User registered successfully!'}), 201

@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    
    # Find user by email
    user = User.query.filter_by(email=data['email']).first()
    
    if not user:
        return jsonify({'message': 'Invalid credentials!'}), 401
    
    # Check password
    if check_password_hash(user.password, data['password']):
        # Generate token
        token = jwt.encode({
            'user_id': user.id,
            'email': user.email,
            'role': user.role,
            'exp': datetime.datetime.utcnow() + datetime.timedelta(days=1)
        }, app.config['SECRET_KEY'], algorithm='HS256')
        
        user_data = {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'role': user.role
        }
        
        # Get donor details if user is a donor
        if user.role == 'donor':
            donor = Donor.query.filter_by(user_id=user.id).first()
            if donor:
                user_data['donor'] = {
                    'blood_type': donor.blood_type,
                    'is_available': donor.is_available,
                    'last_donation_date': donor.last_donation_date.isoformat() if donor.last_donation_date else None
                }
        
        return jsonify({
            'message': 'Login successful!',
            'token': token,
            'user': user_data
        }), 200
    
    return jsonify({'message': 'Invalid credentials!'}), 401

@app.route('/api/password-reset', methods=['POST'])
def password_reset_request():
    data = request.get_json()
    user = User.query.filter_by(email=data['email']).first()
    
    if not user:
        # Still return success even if email not found (security best practice)
        return jsonify({'message': 'Password reset link sent if email exists!'}), 200
    
    # In a real-world scenario, send an email with reset link
    # For demo purposes, just return success message
    
    return jsonify({'message': 'Password reset link sent if email exists!'}), 200

@app.route('/api/users/profile', methods=['GET'])
@token_required
def get_profile(current_user):
    user_data = {
        'id': current_user.id,
        'name': current_user.name,
        'email': current_user.email,
        'role': current_user.role,
        'created_at': current_user.created_at.isoformat()
    }
    
    # Get donor details if user is a donor
    if current_user.role == 'donor':
        donor = Donor.query.filter_by(user_id=current_user.id).first()
        if donor:
            user_data['donor'] = {
                'blood_type': donor.blood_type,
                'is_available': donor.is_available,
                'last_donation_date': donor.last_donation_date.isoformat() if donor.last_donation_date else None,
                'medical_conditions': donor.medical_conditions
            }
    
    return jsonify(user_data), 200

@app.route('/api/users/profile', methods=['PUT'])
@token_required
def update_profile(current_user):
    data = request.get_json()
    
    # Update user information
    if 'name' in data:
        current_user.name = data['name']
    
    # Update donor information if applicable
    if current_user.role == 'donor' and ('blood_type' in data or 'is_available' in data or 'medical_conditions' in data):
        donor = Donor.query.filter_by(user_id=current_user.id).first()
        
        if donor:
            if 'blood_type' in data:
                donor.blood_type = data['blood_type']
            
            if 'is_available' in data:
                donor.is_available = data['is_available']
            
            if 'medical_conditions' in data:
                donor.medical_conditions = data['medical_conditions']
    
    db.session.commit()
    
    return jsonify({'message': 'Profile updated successfully!'}), 200

@app.route('/api/donations', methods=['POST'])
@token_required
def create_donation(current_user):
    if current_user.role != 'donor':
        return jsonify({'message': 'Not authorized!'}), 403
    
    data = request.get_json()
    
    # Create new donation
    new_donation = Donation(
        id=str(uuid.uuid4()),
        donor_id=current_user.id,
        donation_date=datetime.datetime.now(),
        blood_type=data['blood_type'],
        quantity=data['quantity'],
        location=data['location'],
        notes=data.get('notes', '')
    )
    
    # Update last donation date
    donor = Donor.query.filter_by(user_id=current_user.id).first()
    if donor:
        donor.last_donation_date = datetime.datetime.now()
    
    db.session.add(new_donation)
    db.session.commit()
    
    return jsonify({'message': 'Donation recorded successfully!'}), 201

@app.route('/api/blood-requests', methods=['POST'])
@token_required
def create_blood_request(current_user):
    data = request.get_json()
    
    # Create new blood request
    new_request = BloodRequest(
        id=str(uuid.uuid4()),
        requester_id=current_user.id,
        blood_type=data['blood_type'],
        quantity=data['quantity'],
        urgency=data['urgency'],
        hospital=data['hospital'],
        contact_number=data['contact_number'],
        notes=data.get('notes', ''),
        request_date=datetime.datetime.now(),
        status='pending'
    )
    
    db.session.add(new_request)
    db.session.commit()
    
    return jsonify({'message': 'Blood request created successfully!'}), 201

@app.route('/api/blood-requests', methods=['GET'])
@token_required
def get_blood_requests(current_user):
    if current_user.role == 'admin':
        # Admin can see all requests
        requests = BloodRequest.query.order_by(BloodRequest.request_date.desc()).all()
    else:
        # Regular users see only their own requests
        requests = BloodRequest.query.filter_by(requester_id=current_user.id).order_by(BloodRequest.request_date.desc()).all()
    
    requests_data = []
    for request in requests:
        requests_data.append({
            'id': request.id,
            'blood_type': request.blood_type,
            'quantity': request.quantity,
            'urgency': request.urgency,
            'hospital': request.hospital,
            'contact_number': request.contact_number,
            'notes': request.notes,
            'request_date': request.request_date.isoformat(),
            'status': request.status
        })
    
    return jsonify(requests_data), 200

@app.route('/api/available-donors', methods=['GET'])
@token_required
def get_available_donors(current_user):
    if current_user.role != 'admin':
        return jsonify({'message': 'Not authorized!'}), 403
    
    blood_type = request.args.get('blood_type', '')
    
    # Get available donors filtered by blood type if specified
    query = Donor.query.filter_by(is_available=True)
    if blood_type:
        query = query.filter_by(blood_type=blood_type)
    
    donors = query.all()
    
    donors_data = []
    for donor in donors:
        user = User.query.filter_by(id=donor.user_id).first()
        if user:
            donors_data.append({
                'id': donor.id,
                'name': user.name,
                'blood_type': donor.blood_type,
                'last_donation_date': donor.last_donation_date.isoformat() if donor.last_donation_date else None,
                'contact': user.email
            })
    
    return jsonify(donors_data), 200

# Home route
@app.route('/')
def home():
    return jsonify({'message': 'Blood Donation Management System API'})

if __name__ == '__main__':
    app.run(debug=True)