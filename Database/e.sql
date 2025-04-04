-- Database: BloodDonationSystem

-- Table for managing blood donors
CREATE TABLE Donors (
    donor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    blood_type VARCHAR(3) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    email VARCHAR(100),
    address VARCHAR(255),
    last_donation_date DATE,
    is_eligible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for storing blood recipient requests
CREATE TABLE RecipientRequests (
    request_id VARCHAR(10) PRIMARY KEY,  -- Format: REQ001, REQ002, etc.
    patient_name VARCHAR(100) NOT NULL,
    hospital VARCHAR(100) NOT NULL,
    contact_number VARCHAR(15) NOT NULL,
    blood_type VARCHAR(3) NOT NULL,
    units_required INT NOT NULL,
    required_date DATE NOT NULL,
    purpose TEXT,
    status ENUM('Pending', 'Approved', 'Fulfilled', 'Rejected') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for tracking blood inventory
CREATE TABLE BloodInventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    blood_type VARCHAR(3) NOT NULL,
    units_available INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Table for recording donation transactions
CREATE TABLE DonationTransactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    donor_id INT,
    blood_type VARCHAR(3) NOT NULL,
    units_donated INT NOT NULL DEFAULT 1,
    donation_date DATE NOT NULL,
    FOREIGN KEY (donor_id) REFERENCES Donors(donor_id)
);

-- Table for tracking blood distribution
CREATE TABLE BloodDistribution (
    distribution_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id VARCHAR(10),
    blood_type VARCHAR(3) NOT NULL,
    units_distributed INT NOT NULL,
    distribution_date DATE NOT NULL,
    FOREIGN KEY (request_id) REFERENCES RecipientRequests(request_id)
);

-- Table for system users
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,  -- Should be hashed in real implementation
    full_name VARCHAR(100) NOT NULL,
    role ENUM('Admin', 'Staff', 'Donor') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for notifications
CREATE TABLE Notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Insert sample blood types into inventory
INSERT INTO BloodInventory (blood_type, units_available) VALUES
('A+', 25),
('A-', 10),
('B+', 15),
('B-', 5),
('AB+', 8),
('AB-', 3),
('O+', 30),
('O-', 12);