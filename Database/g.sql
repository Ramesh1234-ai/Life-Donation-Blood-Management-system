-- Users table - Stores information about system users
CREATE TABLE Users2 (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    user_type VARCHAR(20) NOT NULL, -- Admin, Donor, Hospital Staff, etc.
    date_registered DATE NOT NULL
);

-- Donors table - Stores information about blood donors
CREATE TABLE Donors2 (
    donor_id INT PRIMARY KEY,
    user_id INT,
    blood_type VARCHAR(5) NOT NULL, -- A+, B-, O+, etc.
    birth_date DATE NOT NULL,
    weight DECIMAL(5,2), -- in kg
    last_donation_date DATE,
    is_eligible BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Hospitals table - Stores information about hospitals in the system
CREATE TABLE Hospitals (
    hospital_id INT PRIMARY KEY,
    hospital_name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100)
);

-- Blood Inventory table - Tracks available blood units
CREATE TABLE BloodInventory2 (
    inventory_id INT PRIMARY KEY,
    blood_type VARCHAR(5) NOT NULL,
    quantity INT NOT NULL,
    collection_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL -- Available, Reserved, Expired
);

-- Donation Drives table - Information about blood donation events
CREATE TABLE DonationDrives (
    drive_id INT PRIMARY KEY,
    drive_name VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    organizer VARCHAR(100) NOT NULL,
    description TEXT
);

-- Donations table - Records of individual blood donations
CREATE TABLE Donations (
    donation_id INT PRIMARY KEY,
    donor_id INT NOT NULL,
    drive_id INT,
    donation_date DATE NOT NULL,
    blood_type VARCHAR(5) NOT NULL,
    quantity DECIMAL(5,2) NOT NULL, -- in units
    status VARCHAR(20) NOT NULL, -- Completed, Rejected, Processing
    FOREIGN KEY (donor_id) REFERENCES Donors(donor_id),
    FOREIGN KEY (drive_id) REFERENCES DonationDrives(drive_id)
);

-- Blood Requests table - Requests for blood from hospitals
CREATE TABLE BloodRequests (
    request_id INT PRIMARY KEY,
    hospital_id INT NOT NULL,
    blood_type VARCHAR(5) NOT NULL,
    quantity INT NOT NULL,
    request_date DATETIME NOT NULL,
    required_by DATE NOT NULL,
    status VARCHAR(20) NOT NULL, -- Pending, Fulfilled, Partially Fulfilled, Cancelled
    priority VARCHAR(20) NOT NULL, -- Normal, Urgent, Emergency
    FOREIGN KEY (hospital_id) REFERENCES Hospitals(hospital_id)
);

-- Notifications table - Stores system notifications
CREATE TABLE Notifications2 (
    notification_id INT PRIMARY KEY,
    type VARCHAR(20) NOT NULL, -- emergency, drive, update
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    created_at DATETIME NOT NULL,
    action_text VARCHAR(50),
    action_url VARCHAR(255)
);

-- User Notifications table - Links notifications to users
CREATE TABLE UserNotifications (
    id INT PRIMARY KEY,
    user_id INT NOT NULL,
    notification_id INT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    delivered_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (notification_id) REFERENCES Notifications(notification_id)
);

-- Notification Preferences table - User preferences for notifications
CREATE TABLE NotificationPreferences (
    preference_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    emergency_alerts BOOLEAN DEFAULT TRUE,
    donation_drives BOOLEAN DEFAULT TRUE,
    inventory_updates BOOLEAN DEFAULT TRUE,
    system_updates BOOLEAN DEFAULT TRUE,
    in_app_notifications BOOLEAN DEFAULT TRUE,
    email_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    frequency VARCHAR(20) DEFAULT 'real_time', -- real_time, daily, weekly
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);