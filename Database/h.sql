-- Creating the Blood Bank System Database
CREATE DATABASE BloodBankSystem;

-- Select the database to use
USE BloodBankSystem;

-- Users Table: Stores all user accounts
CREATE TABLE Users (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(20),
    Password VARCHAR(100) NOT NULL,
    UserType ENUM('Admin', 'Regular', 'BloodBankStaff') DEFAULT 'Regular',
    DateRegistered DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Donors Table: Stores information about blood donors
CREATE TABLE Donors (
    DonorID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT,
    BloodType ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    Age INT CHECK (Age >= 18 AND Age <= 65),
    Gender ENUM('Male', 'Female', 'Other'),
    Address TEXT,
    LastDonationDate DATE,
    IsEligible BOOLEAN DEFAULT TRUE,
    TotalDonations INT DEFAULT 0,
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- Recipients Table: Stores information about people who need blood
CREATE TABLE Recipients (
    RecipientID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT,
    BloodTypeNeeded ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    Hospital TEXT NOT NULL,
    UnitsRequired INT NOT NULL,
    UrgencyLevel ENUM('Emergency', 'Urgent', 'Scheduled') NOT NULL,
    RequestStatus ENUM('Pending', 'Fulfilled', 'Cancelled') DEFAULT 'Pending',
    RequestDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- BloodBanks Table: Stores information about blood banks
CREATE TABLE BloodBanks (
    BankID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    LicenseNumber VARCHAR(50) NOT NULL UNIQUE,
    Email VARCHAR(100) NOT NULL,
    Phone VARCHAR(20) NOT NULL,
    Address TEXT NOT NULL,
    ContactPerson VARCHAR(100) NOT NULL,
    StorageCapacity INT NOT NULL,
    ServicesOffered TEXT,
    DateRegistered DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- BloodInventory Table: Tracks blood units in each blood bank
CREATE TABLE BloodInventory (
    InventoryID INT AUTO_INCREMENT PRIMARY KEY,
    BankID INT,
    BloodType ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    Units INT NOT NULL,
    CollectionDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL,
    Status ENUM('Available', 'Reserved', 'Used') DEFAULT 'Available',
    FOREIGN KEY (BankID) REFERENCES BloodBanks(BankID)
);

-- Donations Table: Records of blood donations
CREATE TABLE Donations (
    DonationID INT AUTO_INCREMENT PRIMARY KEY,
    DonorID INT,
    BankID INT,
    DonationDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    BloodType ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    Units INT DEFAULT 1,
    Status ENUM('Completed', 'Rejected') DEFAULT 'Completed',
    FOREIGN KEY (DonorID) REFERENCES Donors(DonorID),
    FOREIGN KEY (BankID) REFERENCES BloodBanks(BankID)
);

-- BloodRequests Table: Records requests for blood
CREATE TABLE BloodRequests (
    RequestID INT AUTO_INCREMENT PRIMARY KEY,
    RecipientID INT,
    BankID INT,
    RequestDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    BloodType ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    UnitsRequested INT NOT NULL,
    Status ENUM('Pending', 'Approved', 'Fulfilled', 'Rejected') DEFAULT 'Pending',
    FOREIGN KEY (RecipientID) REFERENCES Recipients(RecipientID),
    FOREIGN KEY (BankID) REFERENCES BloodBanks(BankID)
);

-- Messages Table: For communication between users
CREATE TABLE Messages (
    MessageID INT AUTO_INCREMENT PRIMARY KEY,
    SenderID INT,
    ReceiverID INT,
    Subject VARCHAR(200),
    Content TEXT,
    DateSent DATETIME DEFAULT CURRENT_TIMESTAMP,
    IsRead BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (SenderID) REFERENCES Users(UserID),
    FOREIGN KEY (ReceiverID) REFERENCES Users(UserID)
);

-- Adding some sample data

-- Sample Users
INSERT INTO Users (Name, Email, Phone, Password, UserType) VALUES
('Admin User', 'admin@bloodconnect.org', '555-1000', 'hashed_password_here', 'Admin'),
('John Donor', 'john@example.com', '555-1001', 'hashed_password_here', 'Regular'),
('Sarah Patient', 'sarah@example.com', '555-1002', 'hashed_password_here', 'Regular'),
('City Blood Bank', 'citybb@example.com', '555-2000', 'hashed_password_here', 'BloodBankStaff');

-- Sample Blood Bank
INSERT INTO BloodBanks (Name, LicenseNumber, Email, Phone, Address, ContactPerson, StorageCapacity, ServicesOffered) VALUES
('City Blood Bank', 'BBL-12345', 'citybb@example.com', '555-2000', '123 Medical Plaza, Healthcare City', 'Dr. Michael Smith', 1000, 'Blood collection, testing, component separation, storage, distribution');

-- Sample Donor
INSERT INTO Donors (UserID, BloodType, Age, Gender, Address) VALUES
(2, 'O+', 28, 'Male', '456 Oak Street, Anytown');

-- Sample Recipient
INSERT INTO Recipients (UserID, BloodTypeNeeded, Hospital, UnitsRequired, UrgencyLevel) VALUES
(3, 'AB-', 'General Hospital', 2, 'Urgent');

-- Sample Blood Inventory
INSERT INTO BloodInventory (BankID, BloodType, Units, CollectionDate, ExpiryDate) VALUES
(1, 'O+', 50, '2025-03-01', '2025-04-01'),
(1, 'A+', 35, '2025-03-05', '2025-04-05'),
(1, 'B+', 25, '2025-03-08', '2025-04-08'),
(1, 'AB-', 10, '2025-03-10', '2025-04-10');

SELECT * FROM Donors