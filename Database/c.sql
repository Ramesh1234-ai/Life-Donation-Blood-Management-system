-- Create the Database
CREATE DATABASE IF NOT EXISTS blood_donation;
USE blood_donation;

-- Users Table for Authentication
CREATE TABLE User (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'staff', 'donor', 'recipient') NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    status ENUM('active', 'inactive', 'blocked') DEFAULT 'active'
);

-- Donors Table
CREATE TABLE Donor (
    donor_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    full_name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    gender ENUM('male', 'female', 'other') NOT NULL,
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    weight DECIMAL(5,2) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    last_donation_date DATE NULL,
    health_status ENUM('eligible', 'temporary_deferral', 'permanent_deferral') DEFAULT 'eligible',
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE SET NULL
);

-- Blood Inventory Table
CREATE TABLE Blood_Inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    units_available INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Recipients Table
CREATE TABLE Recipient (
    recipient_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    full_name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    gender ENUM('male', 'female', 'other') NOT NULL,
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    hospital_name VARCHAR(100),
    doctor_name VARCHAR(100),
    address TEXT NOT NULL,
    medical_condition TEXT,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE SET NULL
);

-- Blood Donation Records Table
CREATE TABLE Donation (
    donation_id INT AUTO_INCREMENT PRIMARY KEY,
    donor_id INT NOT NULL,
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    units INT NOT NULL DEFAULT 1,
    donation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    hemoglobin_level DECIMAL(4,2),
    pulse_rate INT,
    blood_pressure VARCHAR(10),
    temperature DECIMAL(4,2),
    donation_center VARCHAR(100) NOT NULL,
    staff_id INT,
    expiry_date DATE NOT NULL,
    status ENUM('collected', 'tested', 'available', 'discarded', 'transfused') DEFAULT 'collected',
    FOREIGN KEY (donor_id) REFERENCES Donor(donor_id),
    FOREIGN KEY (staff_id) REFERENCES User(user_id)
);

-- Blood Requests Table
CREATE TABLE Blood_Request (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    recipient_id INT NOT NULL,
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    units_required INT NOT NULL DEFAULT 1,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    required_by DATE NOT NULL,
    purpose TEXT NOT NULL,
    hospital_name VARCHAR(100) NOT NULL,
    doctor_name VARCHAR(100) NOT NULL,
    priority ENUM('normal', 'urgent', 'emergency') DEFAULT 'normal',
    status ENUM('pending', 'approved', 'fulfilled', 'cancelled') DEFAULT 'pending',
    fulfilled_date TIMESTAMP NULL,
    notes TEXT,
    FOREIGN KEY (recipient_id) REFERENCES Recipient(recipient_id)
);

-- Blood Transfusions Table
CREATE TABLE Transfusion (
    transfusion_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    donation_id INT NOT NULL,
    transfusion_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    performed_by INT, -- staff ID
    status ENUM('scheduled', 'completed', 'cancelled') DEFAULT 'scheduled',
    notes TEXT,
    FOREIGN KEY (request_id) REFERENCES Blood_Request(request_id),
    FOREIGN KEY (donation_id) REFERENCES Donation(donation_id),
    FOREIGN KEY (performed_by) REFERENCES User(user_id)
);

-- Notifications Table
CREATE TABLE Notification (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('alert', 'info', 'success', 'warning') DEFAULT 'info',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE CASCADE
);

-- Populate Blood Inventory with initial blood groups
INSERT INTO Blood_Inventory (blood_group, units_available) VALUES
('A+', 0),
('A-', 0),
('B+', 0),
('B-', 0),
('AB+', 0),
('AB-', 0),
('O+', 0),
('O-', 0);

-- Create Admin User
INSERT INTO User (full_name, email, password, role, status)
VALUES ('Admin User', 'admin@lifedrop.com', '$2y$10$ExampleHashedPasswordForAdmin123', 'admin', 'active');
SELECT * FROM Blood_Inventory

SELECT * FROM User