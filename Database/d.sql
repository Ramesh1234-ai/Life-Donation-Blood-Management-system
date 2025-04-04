USE blood_donation_system;

-- Register a new blood donor
DELIMITER //
CREATE PROCEDURE AddNewDonor(
    IN name VARCHAR(100),
    IN age INT,
    IN gender VARCHAR(10),
    IN blood_type VARCHAR(3),
    IN weight DECIMAL(5,2),
    IN phone VARCHAR(20),
    IN email VARCHAR(100),
    IN address TEXT,
    IN last_donated DATE
)
BEGIN
    -- Add the donor to our system
    INSERT INTO donors (
        full_name, age, gender, blood_group, weight, 
        phone, email, address, last_donation_date
    ) VALUES (
        name, age, gender, blood_type, weight, 
        phone, email, address, last_donated
    );
    
    -- Create a user account automatically
    INSERT INTO users (full_name, email, password, role, phone)
    VALUES (name, email, CONCAT('$2y$10$', UUID()), 'donor', phone);
    
    -- Link the user account to the donor record
    UPDATE donors SET user_id = LAST_INSERT_ID() WHERE email = email;
    
    -- Return the new donor ID
    SELECT LAST_INSERT_ID() AS donor_id;
END //
DELIMITER ;

-- Record a new blood donation
DELIMITER //
CREATE PROCEDURE RecordBloodDonation(
    IN donor_id INT,
    IN amount INT,
    IN hemoglobin DECIMAL(4,2),
    IN pulse INT,
    IN bp VARCHAR(10),
    IN temp DECIMAL(4,2),
    IN center_name VARCHAR(100),
    IN staff_id INT
)
BEGIN
    DECLARE donor_blood_type VARCHAR(3);
    
    -- Get donor's blood type
    SELECT blood_group INTO donor_blood_type FROM donors WHERE donor_id = donor_id;
    
    -- Set expiry date (blood expires after 42 days)
    SET @expires_on = DATE_ADD(CURDATE(), INTERVAL 42 DAY);
    
    -- Save donation details
    INSERT INTO donations (
        donor_id, blood_group, units, hemoglobin_level, 
        pulse_rate, blood_pressure, temperature, 
        donation_center, staff_id, expiry_date
    ) VALUES (
        donor_id, donor_blood_type, amount, hemoglobin, 
        pulse, bp, temp, 
        center_name, staff_id, @expires_on
    );
    
    -- Update when the donor last donated
    UPDATE donors SET last_donation_date = CURDATE() WHERE donor_id = donor_id;
    
    -- Add blood to our inventory
    UPDATE blood_inventory 
    SET units_available = units_available + amount 
    WHERE blood_group = donor_blood_type;
    
    -- Create a notification about the donation
    INSERT INTO notifications (title, message, type)
    VALUES (
        'New Donation',
        CONCAT('Received ', amount, ' unit(s) of ', donor_blood_type, ' blood.'),
        'success'
    );
    
    -- Return the donation ID
    SELECT LAST_INSERT_ID() AS donation_id;
END //
DELIMITER ;

-- Request blood for a patient
DELIMITER //
CREATE PROCEDURE RequestBlood(
    IN patient_id INT,
    IN blood_type VARCHAR(3),
    IN units INT,
    IN needed_by DATE,
    IN reason TEXT,
    IN hospital VARCHAR(100),
    IN doctor VARCHAR(100),
    IN urgency VARCHAR(10)
)
BEGIN
    -- Create the blood request
    INSERT INTO blood_requests (
        recipient_id, blood_group, units_required, required_by,
        purpose, hospital_name, doctor_name, priority
    ) VALUES (
        patient_id, blood_type, units, needed_by,
        reason, hospital, doctor, urgency
    );
    
    -- Check if we have enough blood
    SELECT units_available INTO @available 
    FROM blood_inventory 
    WHERE blood_group = blood_type;
    
    -- Send appropriate notification
    IF @available < units THEN
        -- Not enough blood available
        INSERT INTO notifications (title, message, type)
        VALUES (
            'Blood Shortage Alert',
            CONCAT('Need ', units, ' unit(s) of ', blood_type, ' blood, but only ', @available, ' available.'),
            'warning'
        );
    ELSE
        -- We have enough blood
        INSERT INTO notifications (title, message, type)
        VALUES (
            'Blood Request',
            CONCAT('Request for ', units, ' unit(s) of ', blood_type, ' blood.'),
            'info'
        );
    END IF;
    
    -- Return the request ID
    SELECT LAST_INSERT_ID() AS request_id;
END //
DELIMITER ;

-- Provide blood for a request
DELIMITER //
CREATE PROCEDURE ProvideBlood(
    IN request_id INT,
    IN staff_id INT
)
BEGIN
    DECLARE request_blood_type VARCHAR(3);
    DECLARE units_needed INT;
    DECLARE units_we_have INT;
    
    -- Get details about the request
    SELECT blood_group, units_required INTO request_blood_type, units_needed
    FROM blood_requests
    WHERE request_id = request_id;
    
    -- Check how much blood we have
    SELECT units_available INTO units_we_have
    FROM blood_inventory
    WHERE blood_group = request_blood_type;
    
    -- Make sure we have enough blood
    IF units_we_have >= units_needed THEN
        -- Mark the request as complete
        UPDATE blood_requests
        SET status = 'fulfilled', fulfilled_date = NOW()
        WHERE request_id = request_id;
        
        -- Remove blood from inventory
        UPDATE blood_inventory
        SET units_available = units_available - units_needed
        WHERE blood_group = request_blood_type;
        
        -- Find suitable blood for this patient
        SELECT donation_id INTO @donation_id
        FROM donations
        WHERE blood_group = request_blood_type
          AND status = 'available'
          AND expiry_date > CURDATE()
        LIMIT 1;
        
        -- Record the blood transfusion
        INSERT INTO transfusions (
            request_id, donation_id, performed_by, status
        ) VALUES (
            request_id, @donation_id, staff_id, 'completed'
        );
        
        -- Mark the donated blood as used
        UPDATE donations
        SET status = 'transfused'
        WHERE donation_id = @donation_id;
        
        -- Send success notification
        INSERT INTO notifications (title, message, type)
        VALUES (
            'Request Completed',
            CONCAT('Blood request #', request_id, ' has been fulfilled.'),
            'success'
        );
        
        SELECT 'Success' AS result;
    ELSE
        SELECT 'Not enough blood available' AS result;
    END IF;
END //
DELIMITER ;

-- Check blood inventory levels
DELIMITER //
CREATE PROCEDURE CheckBloodInventory()
BEGIN
    SELECT 
        blood_group AS 'Blood Type',
        units_available AS 'Units Available',
        CASE
            WHEN units_available <= 5 THEN 'Critical - Need Donors!'
            WHEN units_available <= 10 THEN 'Low - More Donors Needed'
            ELSE 'Good Supply'
        END AS 'Status'
    FROM blood_inventory
    ORDER BY 
        FIELD(blood_group, 'O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+');
END //
DELIMITER ;

-- Find donors who can donate now
DELIMITER //
CREATE PROCEDURE FindEligibleDonors()
BEGIN
    SELECT 
        donor_id AS 'ID',
        full_name AS 'Name',
        blood_group AS 'Blood Type',
        phone AS 'Phone Number',
        email AS 'Email',
        last_donation_date AS 'Last Donated',
        CASE
            WHEN last_donation_date IS NULL THEN 'Can donate'
            WHEN DATEDIFF(CURDATE(), last_donation_date) > 56 THEN 'Can donate' 
            ELSE CONCAT('Wait ', 56 - DATEDIFF(CURDATE(), last_donation_date), ' more days')
        END AS 'Eligibility'
    FROM donors
    ORDER BY blood_group, last_donation_date;
END //
DELIMITER ;