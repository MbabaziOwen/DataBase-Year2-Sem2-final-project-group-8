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
    ADD COLUMN worker_id INT UNSIGNED NOT NULL DEFAULT 1 AFTER Staff_ID,
    ADD COLUMN quantity  INT UNSIGNED NOT NULL DEFAULT 1 AFTER worker_id,
    ADD COLUMN notes     TEXT         NULL               AFTER quantity,
    ADD CONSTRAINT fk_dist_worker
        FOREIGN KEY (worker_id) REFERENCES ExtensionWorkers(Worker_id)
        ON UPDATE CASCADE;

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

-- Auto-generate Farmers Registration_number if blank on insert
CREATE TRIGGER trg_farmer_reg_number
BEFORE INSERT ON Farmers
FOR EACH ROW
BEGIN
    IF NEW.Registration_number IS NULL OR NEW.Registration_number = '' THEN
        SET NEW.Registration_number =
            CONCAT('FRM-', YEAR(CURDATE()), '-', LPAD(NEW.Farmer_id + 1, 4, '0'));
    END IF;
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
            SET MESSAGE_TEXT = 'Farms does not exist.';
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
    OUT p_dist_id      INT UNSIGNED
)
BEGIN
    DECLARE v_stock INT UNSIGNED;

    SELECT Quantity INTO v_stock
    FROM Products WHERE Product_id = p_product_id;

    IF v_stock < 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient stock for distribution.';
    END IF;

    INSERT INTO Distributions
        (Product_type, Distribution_date, Product_ID, Farmer_ID, Farm_id, Staff_ID)
    VALUES
        (p_product_type, CURDATE(), p_product_id, p_farmer_id, p_plot_id, p_staff_id);

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

DELIMITER ;

-- ============================================================
--  USER ROLES AND PRIVILEGES
-- ============================================================

DROP USER IF EXISTS 'g8_admin'@'localhost';
DROP USER IF EXISTS 'g8_ext_worker'@'localhost';
DROP USER IF EXISTS 'g8_analyst'@'localhost';
DROP USER IF EXISTS 'g8_readonly'@'localhost';

-- Database administrator — full control
CREATE USER 'g8_admin'@'localhost' IDENTIFIED BY 'Admin@G8_2024!';
GRANT ALL PRIVILEGES ON agricultural_services_db.* TO 'g8_admin'@'localhost' WITH GRANT OPTION;

-- Extension Worker — can record visits and production
CREATE USER 'g8_ext_worker'@'localhost' IDENTIFIED BY 'Worker@G8_2024!';
GRANT SELECT  ON agricultural_services_db.*                       TO 'g8_ext_worker'@'localhost';
GRANT INSERT, UPDATE ON agricultural_services_db.FarmVisits        TO 'g8_ext_worker'@'localhost';
GRANT INSERT, UPDATE ON agricultural_services_db.ProductionRecords TO 'g8_ext_worker'@'localhost';
GRANT EXECUTE ON PROCEDURE agricultural_services_db.sp_RecordProduction TO 'g8_ext_worker'@'localhost';
GRANT EXECUTE ON PROCEDURE agricultural_services_db.sp_FarmerProductionReport TO 'g8_ext_worker'@'localhost';

-- Data analyst — read only + report procedures
CREATE USER 'g8_analyst'@'localhost' IDENTIFIED BY 'Analyst@G8_2024!';
GRANT SELECT ON agricultural_services_db.* TO 'g8_analyst'@'localhost';
GRANT EXECUTE ON PROCEDURE agricultural_services_db.sp_FarmerProductionReport      TO 'g8_analyst'@'localhost';
GRANT EXECUTE ON PROCEDURE agricultural_services_db.sp_DistrictProductionSummary   TO 'g8_analyst'@'localhost';

-- Read-only portal user
CREATE USER 'g8_readonly'@'localhost' IDENTIFIED BY 'ReadOnly@G8_2024!';
GRANT SELECT ON agricultural_services_db.vw_FarmerProfile    TO 'g8_readonly'@'localhost';
GRANT SELECT ON agricultural_services_db.vw_FarmSummary      TO 'g8_readonly'@'localhost';
GRANT SELECT ON agricultural_services_db.vw_ProductionHistory TO 'g8_readonly'@'localhost';
GRANT SELECT ON agricultural_services_db.vw_DistributionLog  TO 'g8_readonly'@'localhost';
GRANT SELECT ON agricultural_services_db.vw_VisitHistory     TO 'g8_readonly'@'localhost';

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

