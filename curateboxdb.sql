-- ===================================================================
-- CurateBox: A Personalized Subscription Box Management Platform
-- Full Database Setup Script
-- ===================================================================

-- -------------------------------------------------------------------
-- Section 1: Schema and Table Creation
-- -------------------------------------------------------------------

-- Create the database if it doesn't exist
CREATE SCHEMA IF NOT EXISTS `curatebox_db` DEFAULT CHARACTER SET utf8 ;
USE `curatebox_db` ;

-- Table for storing customer information
CREATE TABLE IF NOT EXISTS `Customers` (
  `customer_id` INT NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(50) NOT NULL,
  `last_name` VARCHAR(45) NOT NULL,
  `email` VARCHAR(100) NOT NULL,
  `shipping_address` TEXT NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`customer_id`),
  UNIQUE INDEX `email_UNIQUE` (`email` ASC)
) ENGINE = InnoDB;

-- Table for storing supplier information
CREATE TABLE IF NOT EXISTS `Suppliers` (
  `supplier_id` INT NOT NULL AUTO_INCREMENT,
  `supplier_name` VARCHAR(100) NOT NULL,
  `contact_email` VARCHAR(100) NULL,
  PRIMARY KEY (`supplier_id`)
) ENGINE = InnoDB;

-- Table for storing product inventory
CREATE TABLE IF NOT EXISTS `Products` (
  `product_id` INT NOT NULL AUTO_INCREMENT,
  `product_name` VARCHAR(100) NOT NULL,
  `description` TEXT NULL,
  `category` VARCHAR(50) NULL,
  `stock_quantity` INT NOT NULL,
  `supplier_id` INT NOT NULL,
  PRIMARY KEY (`product_id`),
  INDEX `fk_Products_Suppliers_idx` (`supplier_id` ASC),
  CONSTRAINT `fk_Products_Suppliers`
    FOREIGN KEY (`supplier_id`)
    REFERENCES `Suppliers` (`supplier_id`)
) ENGINE = InnoDB;

-- Table for defining all possible preference options (e.g., roast types, allergies)
CREATE TABLE IF NOT EXISTS `Preference_Options` (
  `preference_id` INT NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(50) NOT NULL,
  `preference_value` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`preference_id`)
) ENGINE = InnoDB;

-- Table for managing customer subscriptions
CREATE TABLE IF NOT EXISTS `Subscriptions` (
  `subscription_id` INT NOT NULL AUTO_INCREMENT,
  `customer_id` INT NOT NULL,
  `plan_type` ENUM('Basic', 'Premium') NOT NULL,
  `status` ENUM('Active', 'Paused', 'Cancelled') NOT NULL,
  PRIMARY KEY (`subscription_id`),
  INDEX `fk_Subscriptions_Customers_idx` (`customer_id` ASC),
  CONSTRAINT `fk_Subscriptions_Customers`
    FOREIGN KEY (`customer_id`)
    REFERENCES `Customers` (`customer_id`)
) ENGINE = InnoDB;

-- Junction table to link customers to their preferences (many-to-many)
CREATE TABLE IF NOT EXISTS `Customers_Preferences` (
  `customer_id` INT NOT NULL,
  `preference_id` INT NOT NULL,
  `is_like` TINYINT NOT NULL COMMENT '1 for like, 0 for dislike',
  PRIMARY KEY (`customer_id`, `preference_id`),
  INDEX `fk_Customers_Preferences_Preference_Options_idx` (`preference_id` ASC),
  CONSTRAINT `fk_Customers_Preferences_Customers`
    FOREIGN KEY (`customer_id`)
    REFERENCES `Customers` (`customer_id`),
  CONSTRAINT `fk_Customers_Preferences_Preference_Options`
    FOREIGN KEY (`preference_id`)
    REFERENCES `Preference_Options` (`preference_id`)
) ENGINE = InnoDB;

-- Table to store records of each monthly box curated for a customer
CREATE TABLE IF NOT EXISTS `Monthly_Boxes` (
  `box_id` INT NOT NULL AUTO_INCREMENT,
  `customer_id` INT NOT NULL,
  `curation_date` DATE NOT NULL,
  `shipping_status` VARCHAR(45) NULL,
  `shipped_at` DATE NULL,
  PRIMARY KEY (`box_id`),
  INDEX `fk_Monthly_Boxes_Customers_idx` (`customer_id` ASC),
  CONSTRAINT `fk_Monthly_Boxes_Customers`
    FOREIGN KEY (`customer_id`)
    REFERENCES `Customers` (`customer_id`)
) ENGINE = InnoDB;

-- Junction table to list the contents of each monthly box (many-to-many)
CREATE TABLE IF NOT EXISTS `Box_Contents` (
  `box_id` INT NOT NULL,
  `product_id` INT NOT NULL,
  `quantity` INT NOT NULL DEFAULT 1,
  PRIMARY KEY (`box_id`, `product_id`),
  INDEX `fk_Box_Contents_Products_idx` (`product_id` ASC),
  CONSTRAINT `fk_Box_Contents_Monthly_Boxes`
    FOREIGN KEY (`box_id`)
    REFERENCES `Monthly_Boxes` (`box_id`),
  CONSTRAINT `fk_Box_Contents_Products`
    FOREIGN KEY (`product_id`)
    REFERENCES `Products` (`product_id`)
) ENGINE = InnoDB;

USE `curatebox_db`;

CREATE TABLE IF NOT EXISTS `Admins` (
  `admin_id` INT NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(50) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL, -- Always store hashed passwords, never plain text!
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`admin_id`),
  UNIQUE INDEX `username_UNIQUE` (`username` ASC)
) ENGINE = InnoDB;



-- -------------------------------------------------------------------
-- Section 2: Sample Data Insertion
-- -------------------------------------------------------------------
INSERT INTO `Customers` (`first_name`, `last_name`, `email`, `shipping_address`) VALUES
('Priya', 'Patel', 'priya.p@example.com', '101 Palm Grove, Mumbai'),
('Rohan', 'Sharma', 'rohan.s@example.com', '123 Tech Park, Bengaluru'),
('Anjali', 'Verma', 'anjali.v@example.com', '456 Cyber City, Gurgaon');

INSERT INTO `Suppliers` (`supplier_name`, `contact_email`) VALUES
('Blue Tokai Coffee', 'sales@bluetokai.com'),
('Third Wave Coffee Roasters', 'contact@thirdwave.com'),
('The Snack Company', 'orders@snackco.in');

INSERT INTO `Preference_Options` (`category`, `preference_value`) VALUES
('Roast Type', 'Dark Roast'), ('Roast Type', 'Medium Roast'), ('Roast Type', 'Light Roast'),
('Category', 'Coffee'), ('Category', 'Snacks'), ('Allergies', 'Nuts');

INSERT INTO `Products` (`product_name`, `category`, `stock_quantity`, `supplier_id`) VALUES
('Attikan Estate Coffee', 'Dark Roast', 100, 1),
('Vienna Roast Coffee', 'Dark Roast', 80, 2),
('Monsoon Malabar', 'Medium Roast', 120, 1),
('Masala Chai Snack Mix', 'Snacks', 200, 3),
('Spicy Murukku', 'Snacks', 150, 3);

INSERT INTO `Subscriptions` (`customer_id`, `plan_type`, `status`) VALUES 
(1, 'Premium', 'Active'), (2, 'Basic', 'Active'), (3, 'Premium', 'Paused');

INSERT INTO `Customers_Preferences` (`customer_id`, `preference_id`, `is_like`) VALUES
(1, 1, 1), (1, 4, 1), (1, 6, 0), -- Priya likes Dark Roast Coffee, dislikes Nuts
(2, 2, 1), (2, 5, 1); -- Rohan likes Medium Roast and Snacks

-- Sample historical data
INSERT INTO `Monthly_Boxes` (`customer_id`, `curation_date`, `shipping_status`, `shipped_at`) VALUES
(1, '2025-08-01', 'Shipped', '2025-08-05'), (2, '2025-08-01', 'Shipped', '2025-08-05'),
(1, '2025-07-01', 'Delivered', '2025-07-06'), (2, '2025-07-01', 'Delivered', '2025-07-06');

INSERT INTO `Box_Contents` (`box_id`, `product_id`, `quantity`) VALUES
(1, 1, 1), -- Box 1 (Priya, Aug) gets Attikan Estate Coffee
(2, 3, 1), (2, 4, 1), -- Box 2 (Rohan, Aug) gets Monsoon Malabar and Snack Mix
(3, 2, 1), -- Box 3 (Priya, Jul) gets Vienna Roast Coffee
(4, 3, 1), (4, 5, 1); -- Box 4 (Rohan, Jul) gets Monsoon Malabar and Spicy Murukku

-- Add a sample admin user (for a real app, the password would be hashed)
INSERT INTO `Admins` (`username`, `password_hash`) VALUES ('admin', 'hashed_password_here');


-- -------------------------------------------------------------------
-- Section 3: Stored Procedure for Curation
-- -------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `GenerateMonthlyBoxes`;

DELIMITER $$
CREATE PROCEDURE `GenerateMonthlyBoxes`(IN p_curation_date DATE)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE current_customer_id INT;
    DECLARE new_box_id INT;
    DECLARE box_exists INT DEFAULT 0;

    -- Cursor to get all active customers
    DECLARE cur_active_customers CURSOR FOR
        SELECT c.customer_id FROM Customers c
        JOIN Subscriptions s ON c.customer_id = s.customer_id
        WHERE s.status = 'Active';
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Create a temporary table to hold product selections for one customer
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_selected_products (
        product_id INT
    );
    
    OPEN cur_active_customers;
    
    customer_loop: LOOP
        FETCH cur_active_customers INTO current_customer_id;
        IF done THEN
            LEAVE customer_loop;
        END IF;

        -- Check if a box already exists for this customer for the given month/year
        SELECT COUNT(*) INTO box_exists FROM Monthly_Boxes
        WHERE customer_id = current_customer_id AND YEAR(curation_date) = YEAR(p_curation_date) AND MONTH(curation_date) = MONTH(p_curation_date);

        -- Only proceed if no box exists
        IF box_exists = 0 THEN

            -- Create a new box
            INSERT INTO Monthly_Boxes (customer_id, curation_date, shipping_status)
            VALUES (current_customer_id, p_curation_date, 'Pending');
            SET new_box_id = LAST_INSERT_ID();
            
            TRUNCATE TABLE temp_selected_products;

            -- Find 2 suitable products based on 'likes' and not 'dislikes'
            INSERT INTO temp_selected_products (product_id)
            SELECT p.product_id
            FROM Products p
            WHERE 
                p.stock_quantity > 0 AND
                p.category IN (
                    SELECT po.preference_value 
                    FROM Customers_Preferences cp 
                    JOIN Preference_Options po ON cp.preference_id = po.preference_id 
                    WHERE cp.customer_id = current_customer_id AND cp.is_like = 1
                ) AND
                p.category NOT IN (
                    SELECT po.preference_value 
                    FROM Customers_Preferences cp 
                    JOIN Preference_Options po ON cp.preference_id = po.preference_id 
                    WHERE cp.customer_id = current_customer_id AND cp.is_like = 0
                )
            ORDER BY RAND()
            LIMIT 2;
            
            -- Insert selected products into the box
            INSERT INTO Box_Contents (box_id, product_id, quantity)
            SELECT new_box_id, product_id, 1
            FROM temp_selected_products;

        END IF;
        
    END LOOP;
    
    CLOSE cur_active_customers;
    
    DROP TEMPORARY TABLE temp_selected_products;
    
END$$
DELIMITER ;


-- -------------------------------------------------------------------
-- Section 4: Trigger for Automatic Inventory Update
-- -------------------------------------------------------------------
DROP TRIGGER IF EXISTS `After_Box_Content_Insert_Update_Stock`;

DELIMITER $$
CREATE TRIGGER `After_Box_Content_Insert_Update_Stock`
AFTER INSERT ON `Box_Contents`
FOR EACH ROW
BEGIN
    UPDATE Products
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
END$$
DELIMITER ;


-- -------------------------------------------------------------------
-- Section 5: Complex Queries for Reporting (for GUI implementation)
-- -------------------------------------------------------------------


-- Query 1 (JOIN): Find the complete order history for a specific customer.
SELECT
    c.first_name,
    c.last_name,
    mb.curation_date,
    p.product_name
FROM Customers c
JOIN Monthly_Boxes mb ON c.customer_id = mb.customer_id
JOIN Box_Contents bc ON mb.box_id = bc.box_id
JOIN Products p ON bc.product_id = p.product_id
WHERE c.customer_id = 1
ORDER BY mb.curation_date DESC;

-- Query 2 (NESTED): Find products that have NEVER been sent to any customer who dislikes 'Nuts'.
SELECT product_name, category
FROM Products
WHERE product_id NOT IN (
    -- Subquery: Find all products that HAVE been sent to customers who dislike nuts
    SELECT DISTINCT bc.product_id
    FROM Box_Contents bc
    JOIN Monthly_Boxes mb ON bc.box_id = mb.box_id
    WHERE mb.customer_id IN (
        -- Subquery: Find all customers who dislike nuts
        SELECT cp.customer_id
        FROM Customers_Preferences cp
        JOIN Preference_Options po ON cp.preference_id = po.preference_id 
        WHERE po.preference_value = 'Nuts' AND cp.is_like = 0
    )
);

-- Query 3 (AGGREGATE): Find the top 3 most frequently shipped products.
SELECT
    p.product_name,
    COUNT(bc.product_id) AS times_shipped
FROM Box_Contents bc
JOIN Products p ON bc.product_id = p.product_id
GROUP BY p.product_name
ORDER BY times_shipped DESC
LIMIT 3;



-- ===================================================================
-- End of Script
-- ===================================================================