-- ============================================================
--  GROUP 8 — Coffee Growers Management System
--  SQL generated directly from the EERD (v2)
--  MySQL 8.x compatible
-- ============================================================

DROP DATABASE IF EXISTS agricultural_services_db;
CREATE DATABASE agricultural_services_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE agricultural_services_db;

CREATE TABLE Region (
    region_ID   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    region_name VARCHAR(100)    NOT NULL,
    CONSTRAINT uq_region_name UNIQUE (region_name)
);

CREATE TABLE Districts (
    District_ID   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    district_name VARCHAR(100)    NOT NULL,
    region_ID     INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_district_region
        FOREIGN KEY (region_ID) REFERENCES Region(region_ID)
        ON UPDATE CASCADE,
    CONSTRAINT uq_district_name UNIQUE (district_name)
);

CREATE TABLE Subcounty (
    Subcounty_ID   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Subcounty_name VARCHAR(100)    NOT NULL,
    District_ID    INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_subcounty_district
        FOREIGN KEY (District_ID) REFERENCES Districts(District_ID)
        ON UPDATE CASCADE
);

CREATE TABLE Village (
    Village_ID   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Village_name VARCHAR(100)    NOT NULL,
    Subcounty_ID INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_village_subcounty
        FOREIGN KEY (Subcounty_ID) REFERENCES Subcounty(Subcounty_ID)
        ON UPDATE CASCADE
);

CREATE TABLE Persons (
    Person_id   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Name       VARCHAR(120)    NOT NULL,
    National_ID        VARCHAR(20)     NOT NULL,
    Gender     VARCHAR(10)     NOT NULL,
    Phone   VARCHAR(20)     NOT NULL,
    Email      VARCHAR(120)    NULL,
    Address    VARCHAR(255)    NULL,
    Village_ID INT UNSIGNED    NOT NULL,
    CONSTRAINT uq_person_nin UNIQUE (National_ID),
    CONSTRAINT fk_person_village
        FOREIGN KEY (Village_ID) REFERENCES Village(Village_ID)
        ON UPDATE CASCADE,
    CONSTRAINT chk_person_gender
        CHECK (Gender IN ('Male','Female','Other'))
);

CREATE TABLE MinistryStaff (
    StaffID   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Role      VARCHAR(100)    NOT NULL,
    Hire_date DATE            NOT NULL,
    Person_id  INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_staff_person
        FOREIGN KEY (Person_id) REFERENCES Persons(Person_id)
        ON DELETE CASCADE ON UPDATE CASCADE
 
);

CREATE TABLE SystemAdmin (
    AdminID      INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Access_level VARCHAR(50)     NOT NULL,
    Status       VARCHAR(30)     NOT NULL DEFAULT 'Active',
    Activity     VARCHAR(100)    NULL,
    Person_id     INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_admin_person
        FOREIGN KEY (Person_id) REFERENCES Persons(Person_id)
        ON DELETE CASCADE ON UPDATE CASCADE
 
);

CREATE TABLE ExtensionWorkers (
    Worker_id        INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Qualification VARCHAR(100)    NOT NULL,
    Hire_date     DATE            NOT NULL,
    Status        VARCHAR(30)     NOT NULL DEFAULT 'Active',
    District_ID    INT UNSIGNED    NOT NULL,
    Person_id      INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_extworker_person
        FOREIGN KEY (Person_id) REFERENCES Persons(Person_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_extworker_district
        FOREIGN KEY (District_ID) REFERENCES Districts(District_ID)
        ON UPDATE CASCADE,
    CONSTRAINT uq_extworker_person UNIQUE (Person_id)
);

CREATE TABLE Farmers (
    Farmer_id   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Registration_date   DATE            NOT NULL DEFAULT (CURDATE()),
    Registration_number VARCHAR(30)     NOT NULL,
    Person_id   INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_farmer_person
        FOREIGN KEY (Person_id) REFERENCES Persons(Person_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_farmer_person  UNIQUE (Person_id), 
    CONSTRAINT uq_farmer_reg_num UNIQUE (Registration_number)
);

CREATE TABLE SupportRequest (
    Request_ID   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    request_type VARCHAR(80)     NOT NULL,
    description  TEXT            NULL,
    status       VARCHAR(30)     NOT NULL DEFAULT 'Pending',
    assigned_to  INT UNSIGNED    NULL, 
    resolved_by  INT UNSIGNED    NULL, 
    Farmer_ID    INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_sr_farmer
        FOREIGN KEY (Farmer_ID) REFERENCES Farmers(Farmer_id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_sr_assigned
        FOREIGN KEY (assigned_to) REFERENCES MinistryStaff(StaffID)
        ON UPDATE CASCADE,
    CONSTRAINT fk_sr_resolved
        FOREIGN KEY (resolved_by) REFERENCES MinistryStaff(StaffID)
        ON UPDATE CASCADE,
    CONSTRAINT chk_sr_status
        CHECK (status IN ('Pending','Assigned','InProgress','Resolved','Closed'))
);

CREATE TABLE Farms (
    Farm_id     INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Farm_name   VARCHAR(150)    NOT NULL,
    Size_acres  DECIMAL(8,2)    NOT NULL,
    Coffee_Type VARCHAR(50)     NOT NULL,
    Start_Year  YEAR            NOT NULL,
    Farmer_id    INT UNSIGNED    NOT NULL,
    Village_ID   INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_plot_farmer
        FOREIGN KEY (Farmer_id)  REFERENCES Farmers(Farmer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_plot_village
        FOREIGN KEY (Village_ID) REFERENCES Village(Village_ID)
        ON UPDATE CASCADE,
    CONSTRAINT chk_plot_size CHECK (Size_acres > 0)
);

CREATE TABLE FarmVisits (
    Visit_id       INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Visit_purpose        VARCHAR(200)    NOT NULL,
    Visit_date     DATE            NOT NULL,
    Findings       TEXT            NULL,     
    Follow_up_date DATE            NULL,
    Worker_id         INT UNSIGNED    NOT NULL,
    Farmer_ID      INT UNSIGNED    NOT NULL,
    Farm_id        INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_fv_worker
        FOREIGN KEY (Worker_id)    REFERENCES ExtensionWorkers(Worker_id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_fv_farmer
        FOREIGN KEY (Farmer_ID) REFERENCES Farmers(Farmer_id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_fv_plot
        FOREIGN KEY (Farm_id)   REFERENCES Farms(Farm_id)
        ON UPDATE CASCADE,
    CONSTRAINT chk_fv_followup
        CHECK (Follow_up_date IS NULL OR Follow_up_date > Visit_date)
);

CREATE TABLE Products (
    Product_id    INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Product_type VARCHAR(80)     NOT NULL,
    Product_name VARCHAR(150)    NOT NULL,
    Quantity     INT UNSIGNED    NOT NULL DEFAULT 0,
    CONSTRAINT uq_product_name UNIQUE (Product_name),
    CONSTRAINT chk_product_qty CHECK (Quantity >= 0)
);

CREATE TABLE ProductionRecords (
    Production_id INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Season       VARCHAR(30)     NOT NULL,
    Record_date DATE            NOT NULL,
    Quantity     DECIMAL(10,2)   NOT NULL,
    Farm_id      INT UNSIGNED    NOT NULL,
    Worker_id       INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_pr_plot
        FOREIGN KEY (Farm_id) REFERENCES Farms(Farm_id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_pr_extworker
        FOREIGN KEY (Worker_id)  REFERENCES ExtensionWorkers(Worker_id)
        ON UPDATE CASCADE,
    CONSTRAINT chk_pr_qty CHECK (Quantity > 0)
);

CREATE TABLE Distributions (
    Distribution_id   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Product_type      VARCHAR(80)     NOT NULL,
    Distribution_date DATE            NOT NULL DEFAULT (CURDATE()),
    Product_ID        INT UNSIGNED    NOT NULL,
    Farmer_ID         INT UNSIGNED    NOT NULL,
    Farm_id           INT UNSIGNED    NOT NULL,
    Staff_ID          INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_dist_product
        FOREIGN KEY (Product_ID) REFERENCES Products(Product_id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_dist_farmer
        FOREIGN KEY (Farmer_ID)  REFERENCES Farmers(Farmer_id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_dist_plot
        FOREIGN KEY (Farm_id)    REFERENCES Farms(Farm_id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_dist_staff
        FOREIGN KEY (Staff_ID)   REFERENCES MinistryStaff(StaffID)
        ON UPDATE CASCADE
);

CREATE TABLE CoffeeVarieties (
    variety_id          INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    variety_name        VARCHAR(100)    NOT NULL,
    variety_type        ENUM('Arabica','Robusta','Liberica') NOT NULL,
    maturity_months     INT UNSIGNED    NULL,
    avg_yield_kg_tree   DECIMAL(6,2)    NULL,
    drought_resistant   TINYINT(1)      NOT NULL DEFAULT 0,
    description         TEXT            NULL,
    CONSTRAINT uq_variety_name UNIQUE (variety_name)
);

CREATE TABLE FarmVarieties (
    Farm_id         INT UNSIGNED    NOT NULL,
    variety_id      INT UNSIGNED    NOT NULL,
    trees_count     INT UNSIGNED    NOT NULL DEFAULT 0,
    planting_date   DATE            NULL,
    PRIMARY KEY (Farm_id, variety_id),
    CONSTRAINT fk_farmvar_farm
        FOREIGN KEY (Farm_id)    REFERENCES Farms(Farm_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_farmvar_variety
        FOREIGN KEY (variety_id) REFERENCES CoffeeVarieties(variety_id)
        ON UPDATE CASCADE
);

CREATE TABLE AuditLog (
    log_id          INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    table_name      VARCHAR(50)     NOT NULL,
    operation       ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    record_id       INT UNSIGNED    NOT NULL,
    old_value       JSON            NULL,
    new_value       JSON            NULL,
    performed_by    VARCHAR(100)    NULL,
    performed_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
--  ALTER TABLES — Add missing EERD columns
-- ============================================================

-- Persons: first_name, last_name, date_of_birth, district_id, person_type, created_at, updated_at
ALTER TABLE Persons
    ADD COLUMN first_name    VARCHAR(60)   NULL AFTER Name,
    ADD COLUMN last_name     VARCHAR(60)   NULL AFTER first_name,
    ADD COLUMN date_of_birth DATE          NULL AFTER last_name,
    ADD COLUMN district_id   INT UNSIGNED  NULL AFTER Village_ID,
    ADD COLUMN person_type   ENUM('Farmer','ExtensionWorker','MinistryStaff','SystemAdmin') NULL AFTER district_id,
    ADD COLUMN created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER person_type,
    ADD COLUMN updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at,
    ADD CONSTRAINT fk_person_district
        FOREIGN KEY (district_id) REFERENCES Districts(District_ID)
        ON UPDATE CASCADE;

-- Farmers: is_coop_member, cooperative_name, total_trees
ALTER TABLE Farmers
    ADD COLUMN is_coop_member   TINYINT(1)   NOT NULL DEFAULT 0   AFTER Registration_number,
    ADD COLUMN cooperative_name VARCHAR(150) NULL                  AFTER is_coop_member,
    ADD COLUMN total_trees      INT UNSIGNED NOT NULL DEFAULT 0    AFTER cooperative_name;

-- ExtensionWorkers: employee_id (AK), specialization, is_active
ALTER TABLE ExtensionWorkers
    ADD COLUMN employee_id    VARCHAR(30)  NULL AFTER Worker_id,
    ADD COLUMN specialization VARCHAR(100) NULL AFTER Qualification,
    ADD COLUMN is_active      TINYINT(1)   NOT NULL DEFAULT 1 AFTER Status,
    ADD CONSTRAINT uq_extworker_emp_id UNIQUE (employee_id);

-- Farms: district_id FK, sub_county text, village text, registration_date, is_active, GPS coords
ALTER TABLE Farms
    ADD COLUMN district_id       INT UNSIGNED  NULL AFTER Village_ID,
    ADD COLUMN sub_county        VARCHAR(100)  NULL AFTER district_id,
    ADD COLUMN village           VARCHAR(100)  NULL AFTER sub_county,
    ADD COLUMN registration_date DATE          NULL AFTER village,
    ADD COLUMN is_active         TINYINT(1)    NOT NULL DEFAULT 1  AFTER registration_date,
    ADD COLUMN gps_latitude      DECIMAL(9,6)  NULL AFTER is_active,
    ADD COLUMN gps_longitude     DECIMAL(9,6)  NULL AFTER gps_latitude,
    ADD CONSTRAINT fk_farm_district
        FOREIGN KEY (district_id) REFERENCES Districts(District_ID)
        ON UPDATE CASCADE;

-- FarmVisits: recommendations
ALTER TABLE FarmVisits
    ADD COLUMN recommendations TEXT NULL AFTER Findings;

-- ProductionRecords: variety_id FK, season_year, season_period, quantity_kg, quality_grade, recorded_by, notes
ALTER TABLE ProductionRecords
    ADD COLUMN variety_id     INT UNSIGNED                           NULL AFTER Farm_id,
    ADD COLUMN season_year    YEAR                                   NULL AFTER Season,
    ADD COLUMN season_period  ENUM('A','B','C')                     NULL AFTER season_year,
    ADD COLUMN quantity_kg    DECIMAL(10,2)                         NULL AFTER Quantity,
    ADD COLUMN quality_grade  ENUM('Grade A','Grade B','Grade C')   NULL AFTER quantity_kg,
    ADD COLUMN recorded_by    INT UNSIGNED                           NULL AFTER Worker_id,
    ADD COLUMN notes          TEXT                                   NULL AFTER quality_grade,
    ADD CONSTRAINT fk_pr_variety
        FOREIGN KEY (variety_id) REFERENCES CoffeeVarieties(variety_id)
        ON UPDATE CASCADE,
    ADD CONSTRAINT fk_pr_recorded_by
        FOREIGN KEY (recorded_by) REFERENCES Persons(Person_id)
        ON UPDATE CASCADE;

-- Products: unit_of_measure, unit_cost_ugx, description
ALTER TABLE Products
    ADD COLUMN unit_of_measure VARCHAR(30)   NOT NULL DEFAULT 'unit' AFTER Quantity,
    ADD COLUMN unit_cost_ugx   DECIMAL(12,2) NULL                    AFTER unit_of_measure,
    ADD COLUMN description     TEXT          NULL                    AFTER unit_cost_ugx;

-- Distributions: worker_id (nullable — EW who assisted), quantity, notes
ALTER TABLE Distributions
    ADD COLUMN worker_id INT UNSIGNED NULL AFTER Staff_ID,
    ADD COLUMN quantity  INT UNSIGNED NOT NULL DEFAULT 1 AFTER worker_id,
    ADD COLUMN notes     TEXT         NULL               AFTER quantity,
    ADD CONSTRAINT fk_dist_worker
        FOREIGN KEY (worker_id) REFERENCES ExtensionWorkers(Worker_id)
        ON UPDATE CASCADE;


-- ============================================================
--  VALIDATION CONSTRAINTS (operational rules)
-- ============================================================

-- Persons: name ≥2 chars, phone ≥10 chars, email must contain @ and a dot
ALTER TABLE Persons
    ADD CONSTRAINT chk_name_len   CHECK (LENGTH(TRIM(Name)) >= 2),
    ADD CONSTRAINT chk_phone_len  CHECK (LENGTH(TRIM(Phone)) >= 10),
    ADD CONSTRAINT chk_email_fmt  CHECK (Email IS NULL
                                          OR (Email LIKE '%@%.%' AND LENGTH(Email) >= 6));

-- ExtensionWorkers: Status restricted to known operational values
ALTER TABLE ExtensionWorkers
    MODIFY COLUMN Status ENUM('Active','Inactive','On Leave','Suspended')
                         NOT NULL DEFAULT 'Active';

-- SystemAdmin: Status and Access_level restricted to known values
ALTER TABLE SystemAdmin
    MODIFY COLUMN Status       ENUM('Active','Inactive','Suspended')
                               NOT NULL DEFAULT 'Active',
    MODIFY COLUMN Access_level ENUM('Administrator','Supervisor','Operator')
                               NOT NULL;

-- Farms: Coffee_Type restricted, size has upper bound, GPS ranges enforced
ALTER TABLE Farms
    ADD CONSTRAINT chk_coffee_type CHECK (Coffee_Type IN ('Arabica','Robusta','Liberica','Hybrid')),
    ADD CONSTRAINT chk_size_max    CHECK (Size_acres <= 5000),
    ADD CONSTRAINT chk_gps_lat     CHECK (gps_latitude  IS NULL
                                           OR gps_latitude  BETWEEN -90  AND  90),
    ADD CONSTRAINT chk_gps_lon     CHECK (gps_longitude IS NULL
                                           OR gps_longitude BETWEEN -180 AND 180);

-- FarmVarieties: at least 1 tree must be recorded
ALTER TABLE FarmVarieties
    ADD CONSTRAINT chk_trees_pos CHECK (trees_count > 0);

-- CoffeeVarieties: maturity realistic (1–60 months); yield must be positive
ALTER TABLE CoffeeVarieties
    ADD CONSTRAINT chk_var_maturity CHECK (maturity_months IS NULL
                                            OR maturity_months BETWEEN 1 AND 60),
    ADD CONSTRAINT chk_var_yield    CHECK (avg_yield_kg_tree IS NULL
                                            OR avg_yield_kg_tree > 0);

-- Products: price must be positive when provided
ALTER TABLE Products
    ADD CONSTRAINT chk_prod_cost CHECK (unit_cost_ugx IS NULL OR unit_cost_ugx > 0);

-- Distributions: quantity must be positive (worker_id is already nullable — optional EW)
ALTER TABLE Distributions
    ADD CONSTRAINT chk_dist_qty CHECK (quantity > 0);

-- ============================================================
--  TRIGGERS
-- ============================================================

DELIMITER $$

-- Reduce product stock after a distribution is recorded
CREATE TRIGGER trg_after_distribution
AFTER INSERT ON Distributions
FOR EACH ROW
BEGIN
    UPDATE Products
    SET Quantity = Quantity - NEW.quantity
    WHERE Product_id = NEW.Product_ID;

END$$

-- Block distribution if product is out of stock
CREATE TRIGGER trg_before_distribution
BEFORE INSERT ON Distributions
FOR EACH ROW
BEGIN
    DECLARE v_stock INT UNSIGNED;
    SELECT Quantity INTO v_stock
    FROM Products WHERE Product_id = NEW.Product_ID;
    IF v_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot distribute: insufficient stock.';
    END IF;
END$$

-- Prevent deleting a Farmers who still has active Plots
CREATE TRIGGER trg_before_farmer_delete
BEFORE DELETE ON Farmers
FOR EACH ROW
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count FROM Farms WHERE Farmer_id = OLD.Farmer_id;
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete farmer who still has registered plots.';
    END IF;
END$$

-- Auto-generate Registration_number; block future registration dates
CREATE TRIGGER trg_farmer_reg_number
BEFORE INSERT ON Farmers
FOR EACH ROW
BEGIN
    IF NEW.Registration_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Registration_date cannot be in the future.';
    END IF;
    IF NEW.Registration_number IS NULL OR NEW.Registration_number = '' THEN
        SET NEW.Registration_number =
            CONCAT('FRM-', YEAR(CURDATE()), '-', LPAD(NEW.Farmer_id + 1, 4, '0'));
    END IF;
END$$

-- Hire_date must not be in the future
CREATE TRIGGER trg_before_extworker_insert
BEFORE INSERT ON ExtensionWorkers
FOR EACH ROW
BEGIN
    IF NEW.Hire_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Hire_date cannot be in the future.';
    END IF;
END$$

CREATE TRIGGER trg_before_staff_insert
BEFORE INSERT ON MinistryStaff
FOR EACH ROW
BEGIN
    IF NEW.Hire_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Hire_date cannot be in the future.';
    END IF;
END$$

-- Visit_date must not be in the future
CREATE TRIGGER trg_before_visit_insert
BEFORE INSERT ON FarmVisits
FOR EACH ROW
BEGIN
    IF NEW.Visit_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Visit_date cannot be in the future.';
    END IF;
END$$

-- Record_date must not be in the future
CREATE TRIGGER trg_before_production_insert
BEFORE INSERT ON ProductionRecords
FOR EACH ROW
BEGIN
    IF NEW.Record_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Record_date cannot be in the future.';
    END IF;
END$$

-- ── AuditLog population triggers ──────────────────────────
-- Farmers: log INSERT and UPDATE
CREATE TRIGGER trg_audit_farmer_insert
AFTER INSERT ON Farmers
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, operation, record_id, new_value, performed_by)
    VALUES ('Farmers', 'INSERT', NEW.Farmer_id,
            JSON_OBJECT(
                'Farmer_id',          NEW.Farmer_id,
                'Registration_number',NEW.Registration_number,
                'Registration_date',  NEW.Registration_date,
                'Person_id',          NEW.Person_id
            ),
            CURRENT_USER());
END$$

CREATE TRIGGER trg_audit_farmer_update
AFTER UPDATE ON Farmers
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, operation, record_id, old_value, new_value, performed_by)
    VALUES ('Farmers', 'UPDATE', NEW.Farmer_id,
            JSON_OBJECT('Registration_number', OLD.Registration_number,
                        'is_coop_member',      OLD.is_coop_member,
                        'total_trees',         OLD.total_trees),
            JSON_OBJECT('Registration_number', NEW.Registration_number,
                        'is_coop_member',      NEW.is_coop_member,
                        'total_trees',         NEW.total_trees),
            CURRENT_USER());
END$$

-- ProductionRecords: log every new harvest entry
CREATE TRIGGER trg_audit_production_insert
AFTER INSERT ON ProductionRecords
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, operation, record_id, new_value, performed_by)
    VALUES ('ProductionRecords', 'INSERT', NEW.Production_id,
            JSON_OBJECT(
                'Farm_id',    NEW.Farm_id,
                'Season',     NEW.Season,
                'Quantity',   NEW.Quantity,
                'Worker_id',  NEW.Worker_id,
                'Record_date',NEW.Record_date
            ),
            CURRENT_USER());
END$$

-- Distributions: log every product distribution
CREATE TRIGGER trg_audit_dist_insert
AFTER INSERT ON Distributions
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, operation, record_id, new_value, performed_by)
    VALUES ('Distributions', 'INSERT', NEW.Distribution_id,
            JSON_OBJECT(
                'Product_ID',        NEW.Product_ID,
                'Farmer_ID',         NEW.Farmer_ID,
                'quantity',          NEW.quantity,
                'Staff_ID',          NEW.Staff_ID,
                'Distribution_date', NEW.Distribution_date
            ),
            CURRENT_USER());
END$$


DELIMITER ;

-- ============================================================
--  SAMPLE DATA  (follows FK dependency order)
-- ============================================================

-- Region
INSERT INTO Region (region_name) VALUES
('Central'), ('Western'), ('Northern'), ('Eastern');

-- Districts
INSERT INTO Districts (district_name, region_ID) VALUES
('Kampala',  1), ('Masaka',  1),
('Mbarara',  2), ('Gulu',    3),
('Jinja',    4), ('Mbale',   4);

-- Subcounty
INSERT INTO Subcounty (Subcounty_name, District_ID) VALUES
('Nakawa',   1), ('Makindye', 1),
('Nyendo',   2), ('Kakika',   3),
('Laroo',    4), ('Bugembe',  5);

-- Village
INSERT INTO Village (Village_name, Subcounty_ID) VALUES
('Kyambogo',  1), ('Kibuli',    2),
('Kibaswe',   3), ('Ruharo',    4),
('Bardege',   5), ('Kimaka',    6);

-- Persons
INSERT INTO Persons (Name, National_ID, Gender, Phone, Email, Address, Village_ID) VALUES
('James Okello',   'CM900001234A', 'Male',   '0701234567', 'james@mail.com',   'Nakawa',   1),
('Grace Namukasa', 'CF750002345B', 'Female', '0752345678', 'grace@mail.com',   'Nyendo',   3),
('Peter Lubega',   'CM900003456C', 'Male',   '0703456789', 'peter@mail.com',   'Kakika',   4),
('Sarah Amoding',  'CF850004567D', 'Female', '0774567890', 'sarah@mail.com',   'Bugembe',  6),
('Robert Mugisha', 'CM780005678E', 'Male',   '0705678901', NULL,               'Bardege',  5),
('David Ochieng',  'CM820006789F', 'Male',   '0706789012', 'david@moa.go.ug',  'Kyambogo', 1),
('Lydia Tumwine',  'CF880007890G', 'Female', '0707890123', 'lydia@moa.go.ug',  'Kakika',   4),
('Samuel Wamala',  'CM790008901H', 'Male',   '0708901234', 'samuel@moa.go.ug', 'Kibaswe',  3),
('Ruth Akello',    'CF830009012I', 'Female', '0709012345', 'ruth@moa.go.ug',   'Kyambogo', 1);

-- MinistryStaff (persons 7, 8, 9 — overlapping: person 9 will also be SystemAdmin)
INSERT INTO MinistryStaff (Role, Hire_date, Person_id) VALUES
('Senior Agricultural Officer', '2013-01-10', 8),
('Distributions Coordinator',    '2016-05-20', 9);

-- SystemAdmin (person 9 also a MinistryStaff — demonstrates overlapping 'o')
INSERT INTO SystemAdmin (Access_level, Status, Activity, Person_id) VALUES
('Administrator', 'Active', 'System configuration and user management', 9);

-- ExtensionWorkers (persons 6 & 7 — disjoint, different from Farmers)
INSERT INTO ExtensionWorkers (Qualification, Hire_date, Status, District_ID, Person_id) VALUES
('BSc Agriculture',    '2015-03-01', 'Active', 1, 6),
('Diploma Agriculture','2017-08-15', 'Active', 3, 7);

-- Farmers (persons 1–5 — disjoint from ExtensionWorkers)
INSERT INTO Farmers (Registration_date, Registration_number, Person_id) VALUES
('2020-01-15', 'FRM-2020-0001', 1),
('2019-06-20', 'FRM-2019-0002', 2),
('2021-03-10', 'FRM-2021-0003', 3),
('2018-09-05', 'FRM-2018-0004', 4),
('2022-11-22', 'FRM-2022-0005', 5);

-- SupportRequest (farmers submit, ministry staff approve)
INSERT INTO SupportRequest (request_type, description, status, assigned_to, Farmer_ID) VALUES
('Seedlings',   'Request for 200 Robusta seedlings for new plot',    'Assigned',  1, 1),
('Fertiliser',  'NPK fertiliser needed for 5-acre plot',             'Pending',   NULL, 2),
('Pesticide',   'Aphid infestation on Arabica section — need spray', 'Resolved',  2, 4);

-- Farms
INSERT INTO Farms (Farm_name, Size_acres, Coffee_Type, Start_Year, Farmer_id, Village_ID) VALUES
('Okello Coffee Estate', 3.50, 'Robusta',  2020, 1, 1),
('Namukasa Gardens',     5.00, 'Arabica',  2019, 2, 3),
('Lubega Farms',          2.25, 'Arabica',  2021, 3, 4),
('Amoding Plantation',   7.00, 'Robusta',  2018, 4, 6),
('Mugisha Shamba',       1.75, 'Hybrid',   2022, 5, 5);

-- CoffeeVarieties
INSERT INTO CoffeeVarieties (variety_name, variety_type, maturity_months, avg_yield_kg_tree, drought_resistant, description) VALUES
('SL14 Robusta',    'Robusta',  12, 2.50, 1, 'High-yielding Robusta variety, drought tolerant'),
('Bugisu Arabica',  'Arabica',  18, 1.80, 0, 'Premium Arabica from Mt. Elgon region'),
('Bourbon Arabica', 'Arabica',  20, 1.50, 0, 'Classic Arabica with excellent cup quality'),
('NEBBI Robusta',   'Robusta',  10, 3.00, 1, 'West Nile Robusta, high caffeine content'),
('Liberica Barako', 'Liberica', 24, 1.20, 1, 'Rare Liberica with distinctive bold flavour');

-- FarmVarieties (link existing Farms to varieties)
INSERT INTO FarmVarieties (Farm_id, variety_id, trees_count, planting_date) VALUES
(1, 1,  800, '2020-03-01'),   -- Okello Estate     : SL14 Robusta
(2, 2, 1200, '2019-05-15'),   -- Namukasa Gardens  : Bugisu Arabica
(3, 3,  500, '2021-04-10'),   -- Lubega Farms      : Bourbon Arabica
(4, 1, 1500, '2018-02-20'),   -- Amoding Plantation: SL14 Robusta
(4, 4,  600, '2019-06-01'),   -- Amoding Plantation: NEBBI Robusta (mixed farm)
(5, 1,  400, '2022-11-30');   -- Mugisha Shamba    : SL14 Robusta

-- FarmVisits (ExtWorker + Farmers + Farms — all three FKs as per EERD)
INSERT INTO FarmVisits (Visit_purpose, Visit_date, Findings, Follow_up_date, Worker_id, Farmer_ID, Farm_id) VALUES
('Pre-harvest assessment',    '2022-06-15',
 'Trees healthy; minor aphid infestation on 10% of Robusta.',
 '2022-07-01', 1, 1, 1),
('Pre-harvest assessment',    '2022-06-20',
 'Excellent condition. Soil pH within range.',
 '2022-09-01', 2, 2, 2),
('Follow-up visit',           '2022-07-01',
 'Infestation under control after treatment. No further action.',
 NULL,         1, 1, 1),
('Seedling distribution support', '2023-02-10',
 'New seedlings planted correctly. Spacing adequate.',
 '2023-05-10', 2, 5, 5),
('Annual farm inspection',    '2022-05-10',
 'Large plantation well managed. Irrigation functional.',
 '2022-11-01', 1, 4, 4);

-- Products
INSERT INTO Products (Product_type, Product_name, Quantity) VALUES
('Seedling',   'Robusta SL14 Seedlings',   5000),
('Seedling',   'Arabica Bugisu Seedlings',  3000),
('Fertiliser', 'NPK Fertiliser 50kg',        200),
('Pesticide',  'Cypermethrin Pesticide',      150),
('Tool',       'Pruning Shears',              100);

-- ProductionRecords (Farms yields a record, ExtWorker records it)
INSERT INTO ProductionRecords (Season, Record_date, Quantity, Farm_id, Worker_id) VALUES
('Season A 2022', '2022-07-10',  750.00, 1, 1),
('Season B 2022', '2022-12-15',  620.00, 1, 1),
('Season A 2022', '2022-07-20', 1200.00, 2, 2),
('Season A 2023', '2023-07-05',  480.00, 3, 2),
('Season A 2022', '2022-07-25', 1800.00, 4, 1),
('Season B 2022', '2022-12-20', 1500.00, 4, 1);

-- Distributions (Ministry Staff handles it — Staff_ID, not Worker_ID)
INSERT INTO Distributions (Product_type, Distribution_date, Product_ID, Farmer_ID, Farm_id, Staff_ID) VALUES
('Seedling',   '2022-02-10', 1, 1, 1, 1),
('Seedling',   '2022-02-12', 1, 2, 2, 1),
('Fertiliser', '2022-03-01', 3, 3, 3, 2),
('Fertiliser', '2022-03-05', 3, 4, 4, 2),
('Pesticide',  '2022-04-20', 4, 4, 4, 1),
('Seedling',   '2023-01-10', 2, 5, 5, 2);

-- ============================================================
--  VIEWS
-- ============================================================

-- Full person profile with geographic location
CREATE OR REPLACE VIEW vw_PersonProfile AS
SELECT
    p.Person_id,
    p.Name,
    p.National_ID,
    p.Gender,
    p.Phone,
    p.Email,
    p.Address,
    v.Village_name,
    sc.Subcounty_name,
    d.district_name,
    r.region_name
FROM Persons p
JOIN Village  v  ON p.Village_ID    = v.Village_ID
JOIN Subcounty sc ON v.Subcounty_ID = sc.Subcounty_ID
JOIN Districts  d  ON sc.District_ID = d.District_ID
JOIN Region    r  ON d.region_ID    = r.region_ID;

-- Farmers with full person and location detail
CREATE OR REPLACE VIEW vw_FarmerProfile AS
SELECT
    f.Farmer_id,
    f.Registration_number,
    f.Registration_date,
    pp.Name          AS Farmer_Name,
    pp.Phone,
    pp.Email,
    pp.Village_name,
    pp.district_name,
    pp.region_name
FROM Farmers f
JOIN vw_PersonProfile pp ON f.Person_id = pp.Person_id;

-- Farms summary with farmer and location
CREATE OR REPLACE VIEW vw_FarmSummary AS
SELECT
    pl.Farm_id,
    pl.Farm_name,
    pl.Size_acres,
    pl.Coffee_Type,
    pl.Start_Year,
    f.Registration_number     AS Farmer_Reg,
    pp.Name          AS Farmer_Name,
    v.Village_name,
    sc.Subcounty_name,
    d.district_name
FROM Farms pl
JOIN Farmers       f  ON pl.Farmer_id   = f.Farmer_id
JOIN Persons       p  ON f.Person_id    = p.Person_id
JOIN vw_PersonProfile pp ON f.Person_id = pp.Person_id
JOIN Village      v  ON pl.Village_ID  = v.Village_ID
JOIN Subcounty    sc ON v.Subcounty_ID = sc.Subcounty_ID
JOIN Districts     d  ON sc.District_ID = d.District_ID;

-- Production history per plot
CREATE OR REPLACE VIEW vw_ProductionHistory AS
SELECT
    pr.Production_id,
    pr.Season,
    pr.Record_date,
    pr.Quantity,
    pl.Farm_name,
    pl.Coffee_Type,
    d.district_name,
    p2.Name          AS Farmer_Name,
    p1.Name          AS Recorded_By
FROM ProductionRecords pr
JOIN Farms             pl ON pr.Farm_id  = pl.Farm_id
JOIN Farmers           fa ON pl.Farmer_id = fa.Farmer_id
JOIN Persons           p2 ON fa.Person_id = p2.Person_id
JOIN ExtensionWorkers  ew ON pr.Worker_id   = ew.Worker_id
JOIN Persons           p1 ON ew.Person_id = p1.Person_id
JOIN Village          v  ON pl.Village_ID = v.Village_ID
JOIN Subcounty        sc ON v.Subcounty_ID = sc.Subcounty_ID
JOIN Districts         d  ON sc.District_ID = d.District_ID;

-- Distributions log
CREATE OR REPLACE VIEW vw_DistributionLog AS
SELECT
    dist.Distribution_id,
    dist.Distribution_date,
    dist.Product_type,
    prod.Product_name,
    prod.Quantity       AS Stock_After,
    fp.Name             AS Farmer_Name,
    pl.Farm_name,
    d.district_name,
    sp.Name             AS Distributed_By
FROM Distributions      dist
JOIN Products           prod ON dist.Product_ID = prod.Product_id
JOIN Farmers            fa   ON dist.Farmer_ID  = fa.Farmer_id
JOIN Persons            fp   ON fa.Person_id     = fp.Person_id
JOIN Farms              pl   ON dist.Farm_id    = pl.Farm_id
JOIN Village           v    ON pl.Village_ID    = v.Village_ID
JOIN Subcounty         sc   ON v.Subcounty_ID  = sc.Subcounty_ID
JOIN Districts          d    ON sc.District_ID  = d.District_ID
JOIN MinistryStaff     ms   ON dist.Staff_ID   = ms.StaffID
JOIN Persons            sp   ON ms.Person_id     = sp.Person_id;

-- Farms visit history
CREATE OR REPLACE VIEW vw_VisitHistory AS
SELECT
    fv.Visit_id,
    fv.Visit_date,
    fv.Visit_purpose,
    fv.Findings,
    fv.Follow_up_date,
    pl.Farm_name,
    pl.Coffee_Type,
    fp.Name             AS Farmer_Name,
    wp.Name             AS Worker_Name,
    ew.Qualification,
    d.district_name
FROM FarmVisits         fv
JOIN ExtensionWorkers   ew ON fv.Worker_id    = ew.Worker_id
JOIN Persons            wp ON ew.Person_id  = wp.Person_id
JOIN Farmers            fa ON fv.Farmer_ID = fa.Farmer_id
JOIN Persons            fp ON fa.Person_id  = fp.Person_id
JOIN Farms              pl ON fv.Farm_id   = pl.Farm_id
JOIN Village           v  ON pl.Village_ID = v.Village_ID
JOIN Subcounty         sc ON v.Subcounty_ID = sc.Subcounty_ID
JOIN Districts          d  ON sc.District_ID = d.District_ID;


-- Farm activity summary — uses COALESCE, DATEDIFF, DATE_FORMAT, IF, UPPER
CREATE OR REPLACE VIEW vw_FarmActivitySummary AS
SELECT
    f.Farm_id,
    f.Farm_name,
    UPPER(f.Coffee_Type)                              AS Coffee_Type,
    f.Size_acres,
    COALESCE(SUM(pr.Quantity), 0)                    AS Total_kg_Produced,
    COUNT(DISTINCT pr.Production_id)                  AS Total_Harvests,
    DATE_FORMAT(MAX(pr.Record_date), '%d %b %Y')     AS Last_Harvest_Date,
    DATEDIFF(CURDATE(), MAX(pr.Record_date))          AS Days_Since_Harvest,
    COUNT(DISTINCT fv.Visit_id)                       AS Total_Visits,
    DATE_FORMAT(MAX(fv.Visit_date), '%d %b %Y')      AS Last_Visit_Date,
    IF(f.is_active = 1, 'Active', 'Inactive')        AS Farm_Status,
    pp.Name                                           AS Owner_Name
FROM Farms f
LEFT JOIN ProductionRecords pr ON f.Farm_id   = pr.Farm_id
LEFT JOIN FarmVisits fv        ON f.Farm_id   = fv.Farm_id
JOIN  Farmers fa               ON f.Farmer_id = fa.Farmer_id
JOIN  vw_PersonProfile pp      ON fa.Person_id = pp.Person_id
GROUP BY f.Farm_id, f.Farm_name, f.Coffee_Type, f.Size_acres, f.is_active, pp.Name;

-- ============================================================
--  STORED PROCEDURES
-- ============================================================

DELIMITER $$

-- Register a new farmer (creates Persons + Farmers in one call)
CREATE PROCEDURE sp_RegisterFarmer(
    IN  p_name       VARCHAR(120),
    IN  p_nin        VARCHAR(20),
    IN  p_gender     VARCHAR(10),
    IN  p_phone      VARCHAR(20),
    IN  p_email      VARCHAR(120),
    IN  p_address    VARCHAR(255),
    IN  p_village_id INT UNSIGNED,
    IN  p_reg_number VARCHAR(30),
    OUT p_farmer_id  INT UNSIGNED
)
BEGIN
    DECLARE v_person_id INT UNSIGNED;

    IF EXISTS (SELECT 1 FROM Persons WHERE National_ID = p_nin) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'National_ID already registered.';
    END IF;

    INSERT INTO Persons (Name, National_ID, Gender, Phone, Email, Address, Village_ID)
    VALUES (p_name, p_nin, p_gender, p_phone, p_email, p_address, p_village_id);

    SET v_person_id = LAST_INSERT_ID();

    INSERT INTO Farmers (Registration_date, Registration_number, Person_id)
    VALUES (CURDATE(), p_reg_number, v_person_id);

    SET p_farmer_id = LAST_INSERT_ID();
END$$

-- Record production on a plot
CREATE PROCEDURE sp_RecordProduction(
    IN  p_season      VARCHAR(30),
    IN  p_harvest     DATE,
    IN  p_quantity    DECIMAL(10,2),
    IN  p_plot_id     INT UNSIGNED,
    IN  p_ext_id      INT UNSIGNED,
    OUT p_prod_id     INT UNSIGNED
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Farms WHERE Farm_id = p_plot_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Farm does not exist.';
    END IF;

    INSERT INTO ProductionRecords (Season, Record_date, Quantity, Farm_id, Worker_id)
    VALUES (p_season, p_harvest, p_quantity, p_plot_id, p_ext_id);

    SET p_prod_id = LAST_INSERT_ID();
END$$

-- Distribute product (Ministry Staff only)
CREATE PROCEDURE sp_DistributeProduct(
    IN  p_product_type VARCHAR(80),
    IN  p_product_id   INT UNSIGNED,
    IN  p_farmer_id    INT UNSIGNED,
    IN  p_plot_id      INT UNSIGNED,
    IN  p_staff_id     INT UNSIGNED,
    IN  p_quantity     INT UNSIGNED,
    OUT p_dist_id      INT UNSIGNED
)
BEGIN
    DECLARE v_stock INT UNSIGNED;

    IF p_quantity < 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Quantity must be at least 1.';
    END IF;

    SELECT Quantity INTO v_stock
    FROM Products WHERE Product_id = p_product_id;

    IF v_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient stock for distribution.';
    END IF;

    INSERT INTO Distributions
        (Product_type, Distribution_date, Product_ID, Farmer_ID, Farm_id, Staff_ID, quantity)
    VALUES
        (p_product_type, CURDATE(), p_product_id, p_farmer_id, p_plot_id, p_staff_id, p_quantity);

    SET p_dist_id = LAST_INSERT_ID();
END$$

-- Farmers production report
CREATE PROCEDURE sp_FarmerProductionReport(IN p_farmer_id INT UNSIGNED)
BEGIN
    SELECT
        pr.Season,
        pr.Record_date,
        pr.Quantity,
        pl.Farm_name,
        pl.Coffee_Type,
        d.district_name
    FROM ProductionRecords pr
    JOIN Farms     pl ON pr.Farm_id    = pl.Farm_id
    JOIN Village   v ON pl.Village_ID  = v.Village_ID
    JOIN Subcounty sc ON v.Subcounty_ID = sc.Subcounty_ID
    JOIN Districts   d ON sc.District_ID = d.District_ID
    WHERE pl.Farmer_id = p_farmer_id
    ORDER BY pr.Record_date DESC;
END$$

-- Districts production summary
CREATE PROCEDURE sp_DistrictProductionSummary(IN p_district_id INT UNSIGNED)
BEGIN
    SELECT
        pr.Season,
        COUNT(DISTINCT pl.Farmer_id)   AS Total_Farmers,
        COUNT(DISTINCT pl.Farm_id)    AS Total_Plots,
        SUM(pr.Quantity)              AS Total_kg,
        AVG(pr.Quantity)              AS Avg_kg_per_record
    FROM ProductionRecords pr
    JOIN Farms      pl ON pr.Farm_id    = pl.Farm_id
    JOIN Village    v ON pl.Village_ID  = v.Village_ID
    JOIN Subcounty sc ON v.Subcounty_ID = sc.Subcounty_ID
    WHERE sc.District_ID = p_district_id
    GROUP BY pr.Season
    ORDER BY pr.Season DESC;
END$$

-- Register a new extension worker (creates Persons + ExtensionWorkers in one call)
CREATE PROCEDURE sp_RegisterExtensionWorker(
    IN  p_name        VARCHAR(120),
    IN  p_nin         VARCHAR(20),
    IN  p_gender      VARCHAR(10),
    IN  p_phone       VARCHAR(20),
    IN  p_email       VARCHAR(120),
    IN  p_address     VARCHAR(255),
    IN  p_village_id  INT UNSIGNED,
    IN  p_qual        VARCHAR(100),
    IN  p_hire_date   DATE,
    IN  p_district_id INT UNSIGNED,
    OUT p_worker_id   INT UNSIGNED
)
BEGIN
    DECLARE v_person_id INT UNSIGNED;

    IF EXISTS (SELECT 1 FROM Persons WHERE National_ID = p_nin) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'National_ID already registered.';
    END IF;

    IF p_hire_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Hire_date cannot be in the future.';
    END IF;

    INSERT INTO Persons (Name, National_ID, Gender, Phone, Email, Address, Village_ID)
    VALUES (p_name, p_nin, p_gender, p_phone, p_email, p_address, p_village_id);

    SET v_person_id = LAST_INSERT_ID();

    INSERT INTO ExtensionWorkers (Qualification, Hire_date, Status, District_ID, Person_id)
    VALUES (p_qual, p_hire_date, 'Active', p_district_id, v_person_id);

    SET p_worker_id = LAST_INSERT_ID();
END$$

-- Record a farm visit
CREATE PROCEDURE sp_RecordFarmVisit(
    IN  p_purpose      VARCHAR(200),
    IN  p_visit_date   DATE,
    IN  p_findings     TEXT,
    IN  p_followup     DATE,
    IN  p_worker_id    INT UNSIGNED,
    IN  p_farmer_id    INT UNSIGNED,
    IN  p_farm_id      INT UNSIGNED,
    OUT p_visit_id     INT UNSIGNED
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Farms WHERE Farm_id = p_farm_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Farm does not exist.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ExtensionWorkers WHERE Worker_id = p_worker_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Extension worker does not exist.';
    END IF;

    IF p_visit_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Visit_date cannot be in the future.';
    END IF;

    INSERT INTO FarmVisits (Visit_purpose, Visit_date, Findings, Follow_up_date,
                            Worker_id, Farmer_ID, Farm_id)
    VALUES (p_purpose, p_visit_date, p_findings, p_followup,
            p_worker_id, p_farmer_id, p_farm_id);

    SET p_visit_id = LAST_INSERT_ID();
END$$

-- Create timestamped in-database snapshot of critical tables
CREATE PROCEDURE sp_BackupKeyTables()
BEGIN
    DECLARE v_sfx VARCHAR(20) DEFAULT DATE_FORMAT(NOW(), '%Y%m%d_%H%i');

    SET @s = CONCAT('CREATE TABLE bkp_Farmers_',           v_sfx, ' AS SELECT * FROM Farmers');
    PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

    SET @s = CONCAT('CREATE TABLE bkp_Farms_',             v_sfx, ' AS SELECT * FROM Farms');
    PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

    SET @s = CONCAT('CREATE TABLE bkp_ProductionRecords_', v_sfx, ' AS SELECT * FROM ProductionRecords');
    PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

    SET @s = CONCAT('CREATE TABLE bkp_Distributions_',     v_sfx, ' AS SELECT * FROM Distributions');
    PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

    SELECT CONCAT('Snapshot created: ', v_sfx) AS backup_status;
END$$


DELIMITER ;

-- ============================================================
--  USER ROLES AND PRIVILEGES
-- ============================================================

-- ── Drop existing users and roles ────────────────────────────
DROP USER IF EXISTS 'g8_admin'@'localhost';
DROP USER IF EXISTS 'g8_ext_worker'@'localhost';
DROP USER IF EXISTS 'g8_analyst'@'localhost';
DROP USER IF EXISTS 'g8_readonly'@'localhost';

DROP ROLE IF EXISTS role_db_admin;
DROP ROLE IF EXISTS role_field_worker;
DROP ROLE IF EXISTS role_data_analyst;
DROP ROLE IF EXISTS role_portal_viewer;

-- ── Create user accounts with authentication policies ─────────
-- Password expires every 180 days; account created for each function
CREATE USER 'g8_admin'@'localhost'
    IDENTIFIED BY 'Admin@G8_2024!'
    PASSWORD EXPIRE INTERVAL 180 DAY;

CREATE USER 'g8_ext_worker'@'localhost'
    IDENTIFIED BY 'Worker@G8_2024!'
    PASSWORD EXPIRE INTERVAL 180 DAY;

CREATE USER 'g8_analyst'@'localhost'
    IDENTIFIED BY 'Analyst@G8_2024!'
    PASSWORD EXPIRE INTERVAL 180 DAY;

CREATE USER 'g8_readonly'@'localhost'
    IDENTIFIED BY 'ReadOnly@G8_2024!'
    PASSWORD EXPIRE INTERVAL 365 DAY;

-- ── Create roles ──────────────────────────────────────────────
CREATE ROLE role_db_admin;
CREATE ROLE role_field_worker;
CREATE ROLE role_data_analyst;
CREATE ROLE role_portal_viewer;

-- ── role_db_admin: full database control ─────────────────────
GRANT ALL PRIVILEGES ON agricultural_services_db.*
    TO role_db_admin WITH GRANT OPTION;

-- ── role_field_worker: write visits + production; read farm data only ─
-- (SELECT on raw Persons table is intentionally excluded — no access to
--  National_ID or private contact details of other staff)
GRANT SELECT ON agricultural_services_db.Farms             TO role_field_worker;
GRANT SELECT ON agricultural_services_db.Farmers           TO role_field_worker;
GRANT SELECT ON agricultural_services_db.FarmVisits        TO role_field_worker;
GRANT SELECT ON agricultural_services_db.ProductionRecords TO role_field_worker;
GRANT SELECT ON agricultural_services_db.CoffeeVarieties   TO role_field_worker;
GRANT SELECT ON agricultural_services_db.FarmVarieties     TO role_field_worker;
GRANT INSERT, UPDATE ON agricultural_services_db.FarmVisits        TO role_field_worker;
GRANT INSERT, UPDATE ON agricultural_services_db.ProductionRecords TO role_field_worker;
GRANT EXECUTE ON PROCEDURE agricultural_services_db.sp_RecordProduction       TO role_field_worker;
GRANT EXECUTE ON PROCEDURE agricultural_services_db.sp_RecordFarmVisit        TO role_field_worker;
GRANT EXECUTE ON PROCEDURE agricultural_services_db.sp_FarmerProductionReport TO role_field_worker;

-- ── role_data_analyst: read-only on views; no raw sensitive tables ──
GRANT SELECT ON agricultural_services_db.vw_PersonProfile       TO role_data_analyst;
GRANT SELECT ON agricultural_services_db.vw_FarmerProfile       TO role_data_analyst;
GRANT SELECT ON agricultural_services_db.vw_FarmSummary         TO role_data_analyst;
GRANT SELECT ON agricultural_services_db.vw_ProductionHistory   TO role_data_analyst;
GRANT SELECT ON agricultural_services_db.vw_DistributionLog     TO role_data_analyst;
GRANT SELECT ON agricultural_services_db.vw_VisitHistory        TO role_data_analyst;
GRANT SELECT ON agricultural_services_db.vw_FarmActivitySummary TO role_data_analyst;
GRANT EXECUTE ON PROCEDURE agricultural_services_db.sp_FarmerProductionReport    TO role_data_analyst;
GRANT EXECUTE ON PROCEDURE agricultural_services_db.sp_DistrictProductionSummary TO role_data_analyst;

-- ── role_portal_viewer: public-facing read-only on non-sensitive views only ─
GRANT SELECT ON agricultural_services_db.vw_FarmerProfile       TO role_portal_viewer;
GRANT SELECT ON agricultural_services_db.vw_FarmSummary         TO role_portal_viewer;
GRANT SELECT ON agricultural_services_db.vw_ProductionHistory   TO role_portal_viewer;
GRANT SELECT ON agricultural_services_db.vw_DistributionLog     TO role_portal_viewer;
GRANT SELECT ON agricultural_services_db.vw_VisitHistory        TO role_portal_viewer;
GRANT SELECT ON agricultural_services_db.vw_FarmActivitySummary TO role_portal_viewer;

-- ── Assign roles to users ─────────────────────────────────────
GRANT role_db_admin      TO 'g8_admin'@'localhost';
GRANT role_field_worker  TO 'g8_ext_worker'@'localhost';
GRANT role_data_analyst  TO 'g8_analyst'@'localhost';
GRANT role_portal_viewer TO 'g8_readonly'@'localhost';

-- ── Activate roles automatically on login ─────────────────────
SET DEFAULT ROLE role_db_admin      FOR 'g8_admin'@'localhost';
SET DEFAULT ROLE role_field_worker  FOR 'g8_ext_worker'@'localhost';
SET DEFAULT ROLE role_data_analyst  FOR 'g8_analyst'@'localhost';
SET DEFAULT ROLE role_portal_viewer FOR 'g8_readonly'@'localhost';

FLUSH PRIVILEGES;

-- ============================================================
--  SAMPLE QUERIES
-- ============================================================

-- Q1: All farmers with their plots and total production
SELECT
    fp.Farmer_Name,
    fp.Registration_number,
    pl.Farm_name,
    pl.Coffee_Type,
    fp.district_name,
    SUM(pr.Quantity)  AS Total_kg_Produced
FROM vw_FarmerProfile fp
JOIN Farms pl              ON fp.Farmer_id     = pl.Farmer_id
LEFT JOIN ProductionRecords pr ON pl.Farm_id  = pr.Farm_id
GROUP BY fp.Farmer_id, pl.Farm_id
ORDER BY Total_kg_Produced DESC;

-- Q2: Open support requests with assigned staff
SELECT
    sr.Request_ID,
    sr.request_type,
    sr.status,
    fp.Name          AS Farmers,
    sp.Name          AS Assigned_To
FROM SupportRequest sr
JOIN Farmers         fa ON sr.Farmer_ID  = fa.Farmer_id
JOIN Persons         fp ON fa.Person_id   = fp.Person_id
LEFT JOIN MinistryStaff ms ON sr.assigned_to = ms.StaffID
LEFT JOIN Persons    sp ON ms.Person_id   = sp.Person_id
WHERE sr.status != 'Closed'
ORDER BY sr.Request_ID;

-- Q3: Production by district and season
CALL sp_DistrictProductionSummary(1);

-- Q4: Farmers production report
CALL sp_FarmerProductionReport(1);

-- Q5: Products low on stock
SELECT Product_name, Product_type, Quantity
FROM Products
WHERE Quantity < 100
ORDER BY Quantity;

-- Q6: Persons 9 demonstrates overlapping roles
SELECT
    p.Name,
    ms.Role             AS Ministry_Role,
    sa.Access_level     AS Admin_Level,
    sa.Status           AS Admin_Status
FROM Persons p
LEFT JOIN MinistryStaff ms ON p.Person_id = ms.Person_id
LEFT JOIN SystemAdmin   sa ON p.Person_id = sa.Person_id
WHERE ms.StaffID IS NOT NULL OR sa.AdminID IS NOT NULL;

-- Q7: Farm activity summary (uses COALESCE, DATEDIFF, DATE_FORMAT, IF, UPPER)
SELECT Farm_name, Coffee_Type, Total_kg_Produced,
       Total_Harvests, Last_Harvest_Date, Days_Since_Harvest,
       Total_Visits, Farm_Status, Owner_Name
FROM vw_FarmActivitySummary
ORDER BY Total_kg_Produced DESC;


-- ============================================================
--  BACKUP AND RECOVERY
-- ============================================================

-- ── Strategy 1: Full database dump (run from OS terminal) ────
--
--   BACKUP:
--     mysqldump -u g8_admin -p agricultural_services_db \
--               > backup_$(date +%Y-%m-%d).sql
--
--   SELECTIVE (core tables only):
--     mysqldump -u g8_admin -p agricultural_services_db \
--               Farmers Farms ProductionRecords Distributions CoffeeVarieties \
--               > core_backup_$(date +%Y-%m-%d).sql
--
--   RESTORE:
--     mysql -u root -p agricultural_services_db \
--           < backup_2024-07-01.sql
--
-- ── Strategy 2: In-database snapshot (call anytime) ──────────
--
--   Creates timestamped copies of critical tables inside the DB:
--     CALL sp_BackupKeyTables();
--   This creates tables named e.g. bkp_Farmers_20240701_0900
--
-- ── Strategy 3: Scheduled AuditLog maintenance ───────────────
--   Requires Event Scheduler enabled on the server:
--     SET GLOBAL event_scheduler = ON;
--
--   The event below purges AuditLog rows older than 1 year weekly.

CREATE EVENT IF NOT EXISTS evt_auditlog_cleanup
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
COMMENT 'Remove AuditLog entries older than 1 year to control table growth'
DO DELETE FROM AuditLog
   WHERE performed_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);

-- ── Recovery checklist ───────────────────────────────────────
-- 1. Stop application connections before restoring.
-- 2. Run: DROP DATABASE IF EXISTS agricultural_services_db;
-- 3. Run: CREATE DATABASE agricultural_services_db ...
-- 4. Restore from the most recent .sql dump.
-- 5. Verify row counts match pre-failure state.
-- 6. Re-enable application connections.
