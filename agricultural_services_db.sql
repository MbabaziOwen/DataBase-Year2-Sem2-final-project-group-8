-- ============================================================
--  Agricultural Services Database
--  Ministry of Agriculture – Coffee Growers Management System
--  Based on EERD Design | MySQL 8.x
-- ============================================================

-- ────────────────────────────────────────────────────────────
--  0. DATABASE CREATION
-- ────────────────────────────────────────────────────────────
DROP DATABASE IF EXISTS agricultural_services_db;
CREATE DATABASE agricultural_services_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE agricultural_services_db;

-- ────────────────────────────────────────────────────────────
--  1. TABLES  (ordered to satisfy foreign-key dependencies)
-- ────────────────────────────────────────────────────────────

-- 1.1  DISTRICT
CREATE TABLE District (
    District_id   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    District_name VARCHAR(100)    NOT NULL,
    Region        VARCHAR(100)    NOT NULL,
    Country       VARCHAR(100)    NOT NULL DEFAULT 'Uganda',
    CONSTRAINT uq_district_name UNIQUE (District_name)
);

-- 1.2  PERSONS  (SUPERTYPE)
CREATE TABLE Persons (
    Person_id     INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    First_name    VARCHAR(60)     NOT NULL,
    Last_name     VARCHAR(60)     NOT NULL,
    Gender        ENUM('Male','Female','Other') NOT NULL,
    Date_of_birth DATE            NOT NULL,
    National_ID   VARCHAR(20)     NOT NULL,
    Phone         VARCHAR(20)     NOT NULL,
    Email         VARCHAR(120)    NULL,
    Address       VARCHAR(255)    NULL,
    CONSTRAINT uq_national_id UNIQUE (National_ID),
    CONSTRAINT chk_dob CHECK (Date_of_birth < '2026-01-01'),  
    CONSTRAINT chk_phone CHECK (Phone REGEXP '^[0-9+\\-() ]{7,20}$')
);

-- 1.3  FARMER  (SUBTYPE of Persons – disjoint specialisation)
CREATE TABLE Farmer (
    Farmer_id           INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Registration_number VARCHAR(30)     NOT NULL,
    Registration_date   DATE            NOT NULL DEFAULT (CURDATE()),
    Is_coop_member      TINYINT(1)      NOT NULL DEFAULT 0,
    Cooperative_name    VARCHAR(150)    NULL,           -- name of cooperative if member
    Total_trees         INT UNSIGNED    NOT NULL DEFAULT 0,  -- total coffee trees across all farms
    -- FK to supertype (shared primary key pattern — 1-to-1)
    Person_id           INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_farmer_person FOREIGN KEY (Person_id)
        REFERENCES Persons(Person_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_farmer_reg_num UNIQUE (Registration_number),
    CONSTRAINT uq_farmer_person  UNIQUE (Person_id)           -- disjoint
);

-- 1.4  EXTENSION WORKER  (SUBTYPE of Persons – disjoint specialisation)
CREATE TABLE ExtensionWorker (
    Worker_id       INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Employee_id     VARCHAR(20)     NOT NULL,
    Specialization  VARCHAR(100)    NOT NULL,
    Qualification   VARCHAR(100)    NOT NULL,
    Hire_date       DATE            NOT NULL,
    Is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    -- FK to supertype
    Person_id       INT UNSIGNED    NOT NULL,
    District_ID     INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_worker_person   FOREIGN KEY (Person_id)
        REFERENCES Persons(Person_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_worker_district FOREIGN KEY (District_ID)
        REFERENCES District(District_id) ON UPDATE CASCADE,
    CONSTRAINT uq_worker_emp_id   UNIQUE (Employee_id),
    CONSTRAINT uq_worker_person   UNIQUE (Person_id)          -- disjoint
);

-- 1.5  FARM
CREATE TABLE Farm (
    Farm_id           INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Farm_name         VARCHAR(150)    NOT NULL,
    Sub_county        VARCHAR(100)    NOT NULL,
    Village           VARCHAR(100)    NOT NULL,
    Size_acres        DECIMAL(8,2)    NOT NULL,
    Registration_date DATE            NOT NULL DEFAULT (CURDATE()),
    Is_active         TINYINT(1)      NOT NULL DEFAULT 1,
    Farmer_ID         INT UNSIGNED    NOT NULL,
    District_ID       INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_farm_farmer   FOREIGN KEY (Farmer_ID)
        REFERENCES Farmer(Farmer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_farm_district FOREIGN KEY (District_ID)
        REFERENCES District(District_id) ON UPDATE CASCADE,
    CONSTRAINT chk_farm_size CHECK (Size_acres > 0)
);

-- 1.6  COFFEE VARIETY
CREATE TABLE CoffeeVariety (
    Variety_id          INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Variety_name        VARCHAR(100)    NOT NULL,
    Variety_type        ENUM('Arabica','Robusta','Hybrid') NOT NULL,
    Maturity_months     TINYINT UNSIGNED NOT NULL,
    Avg_yield_kg_tree   DECIMAL(6,2)    NOT NULL,
    Drought_resistant   TINYINT(1)      NOT NULL DEFAULT 0,
    CONSTRAINT uq_variety_name UNIQUE (Variety_name),
    CONSTRAINT chk_maturity    CHECK (Maturity_months BETWEEN 6 AND 60),
    CONSTRAINT chk_yield       CHECK (Avg_yield_kg_tree > 0)
);

-- 1.7  FARM VARIETY  (resolves M:N between Farm and CoffeeVariety)
CREATE TABLE FarmVariety (
    Farm_varietyID  INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Trees_count     INT UNSIGNED    NOT NULL,
    Planting_date   DATE            NOT NULL,
    Farm_ID         INT UNSIGNED    NOT NULL,
    Variety_ID      INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_fv_farm    FOREIGN KEY (Farm_ID)
        REFERENCES Farm(Farm_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fv_variety FOREIGN KEY (Variety_ID)
        REFERENCES CoffeeVariety(Variety_id) ON UPDATE CASCADE,
    CONSTRAINT uq_farm_variety UNIQUE (Farm_ID, Variety_ID),
    CONSTRAINT chk_trees CHECK (Trees_count > 0)
);

-- 1.8  PRODUCTION RECORD
CREATE TABLE ProductionRecord (
    Production_id   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Season_year     YEAR            NOT NULL,
    Season_period   ENUM('First','Second') NOT NULL,
    Quantity_kg     DECIMAL(10,2)   NOT NULL,
    Quality_grade   ENUM('A','B','C','D') NOT NULL DEFAULT 'B',
    Record_date     DATE            NOT NULL DEFAULT (CURDATE()),
    Farm_varietyID  INT UNSIGNED    NOT NULL,
    Worker_ID       INT UNSIGNED    NOT NULL,
    Farm_ID         INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_pr_farmvariety FOREIGN KEY (Farm_varietyID)
        REFERENCES FarmVariety(Farm_varietyID) ON UPDATE CASCADE,
    CONSTRAINT fk_pr_worker      FOREIGN KEY (Worker_ID)
        REFERENCES ExtensionWorker(Worker_id) ON UPDATE CASCADE,
    CONSTRAINT fk_pr_farm        FOREIGN KEY (Farm_ID)
        REFERENCES Farm(Farm_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_qty CHECK (Quantity_kg > 0)
);

-- 1.9  PRODUCT  (seedlings, fertilisers, etc.)
CREATE TABLE Product (
    Product_id      INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Product_name    VARCHAR(150)    NOT NULL,
    Product_type    ENUM('Seedling','Fertiliser','Pesticide','Tool','Other') NOT NULL,
    Unit_of_measure VARCHAR(30)     NOT NULL,
    Current_stock   INT UNSIGNED    NOT NULL DEFAULT 0,
    Unit_cost_ugx   DECIMAL(12,2)  NOT NULL,
    CONSTRAINT uq_product_name UNIQUE (Product_name),
    CONSTRAINT chk_cost        CHECK (Unit_cost_ugx >= 0)
);

-- 1.10  DISTRIBUTION  (product distribution to farms)
CREATE TABLE Distribution (
    Distribution_id   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Distribution_date DATE            NOT NULL DEFAULT (CURDATE()),
    Quantity          INT UNSIGNED    NOT NULL,
    Product_ID        INT UNSIGNED    NOT NULL,
    Farm_ID           INT UNSIGNED    NOT NULL,
    Worker_ID         INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_dist_product FOREIGN KEY (Product_ID)
        REFERENCES Product(Product_id) ON UPDATE CASCADE,
    CONSTRAINT fk_dist_farm    FOREIGN KEY (Farm_ID)
        REFERENCES Farm(Farm_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_dist_worker  FOREIGN KEY (Worker_ID)
        REFERENCES ExtensionWorker(Worker_id) ON UPDATE CASCADE,
    CONSTRAINT chk_dist_qty    CHECK (Quantity > 0)
);

-- 1.11  FARM VISIT
CREATE TABLE FarmVisit (
    Visit_id          INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Visit_date        DATE            NOT NULL,
    Visit_purpose     VARCHAR(200)    NOT NULL,
    Findings          TEXT            NULL,
    Recommendations   TEXT            NULL,
    Follow_up_date    DATE            NULL,
    Worker_ID         INT UNSIGNED    NOT NULL,
    Farm_ID           INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_fv2_worker FOREIGN KEY (Worker_ID)
        REFERENCES ExtensionWorker(Worker_id) ON UPDATE CASCADE,
    CONSTRAINT fk_fv2_farm   FOREIGN KEY (Farm_ID)
        REFERENCES Farm(Farm_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_followup  CHECK (Follow_up_date IS NULL OR Follow_up_date > Visit_date)
);


-- ────────────────────────────────────────────────────────────
--  2. SAMPLE DATA
-- ────────────────────────────────────────────────────────────

-- Districts
INSERT INTO District (District_name, Region, Country) VALUES
('Kampala',  'Central',   'Uganda'),
('Mbarara',  'Western',   'Uganda'),
('Gulu',     'Northern',  'Uganda'),
('Jinja',    'Eastern',   'Uganda'),
('Masaka',   'Central',   'Uganda');

-- Persons (Farmers + Workers combined)
INSERT INTO Persons (First_name, Last_name, Gender, Date_of_birth, National_ID, Phone, Email, Address) VALUES
-- Farmers
('James',    'Okello',   'Male',   '1980-03-15', 'CM900001234A', '0701234567', 'james.okello@email.com',  'Kampala, Nakawa'),
('Grace',    'Namukasa', 'Female', '1975-07-20', 'CF750002345B', '0752345678', 'grace.n@email.com',       'Masaka, Nyendo'),
('Peter',    'Lubega',   'Male',   '1990-01-05', 'CM900003456C', '0703456789', 'peter.l@email.com',       'Mbarara, Kakika'),
('Sarah',    'Amoding',  'Female', '1985-11-30', 'CF850004567D', '0774567890', 'sarah.a@email.com',       'Jinja, Bugembe'),
('Robert',   'Mugisha',  'Male',   '1978-06-12', 'CM780005678E', '0705678901', NULL,                      'Gulu, Laroo'),
-- Extension Workers
('David',    'Ochieng',  'Male',   '1982-09-25', 'CM820006789F', '0706789012', 'david.o@moa.go.ug',       'Kampala, Kololo'),
('Lydia',    'Tumwine',  'Female', '1988-04-14', 'CF880007890G', '0707890123', 'lydia.t@moa.go.ug',       'Mbarara, Biharwe'),
('Samuel',   'Wamala',   'Male',   '1979-12-03', 'CM790008901H', '0708901234', 'samuel.w@moa.go.ug',      'Masaka, Kimaanya');

-- Farmers (subtypes)
INSERT INTO Farmer (Registration_number, Registration_date, Is_coop_member, Cooperative_name, Total_trees, Person_id) VALUES
('FRM-2020-0001', '2020-01-15', 1, 'Kampala Coffee Growers Coop',  800, 1),
('FRM-2019-0002', '2019-06-20', 0, NULL,                           800, 2),
('FRM-2021-0003', '2021-03-10', 1, 'Western Uganda Farmers Union', 400, 3),
('FRM-2018-0004', '2018-09-05', 1, 'Jinja Coffee Cooperative',    1600, 4),
('FRM-2022-0005', '2022-11-22', 0, NULL,                           200, 5);

-- Extension Workers (subtypes)
INSERT INTO ExtensionWorker (Employee_id, Specialization, Qualification, Hire_date, Is_active, Person_id, District_ID) VALUES
('EW-001', 'Crop Production',   'BSc Agriculture',       '2015-03-01', 1, 6, 1),
('EW-002', 'Soil Science',      'Diploma Agriculture',   '2017-08-15', 1, 7, 2),
('EW-003', 'Pest Management',   'MSc Agronomy',          '2013-01-10', 1, 8, 5);

-- Farms
INSERT INTO Farm (Farm_name, Sub_county, Village, Size_acres, Registration_date, Is_active, Farmer_ID, District_ID) VALUES
('Okello Coffee Estate', 'Nakawa',   'Kyambogo',   3.50, '2020-01-20', 1, 1, 1),
('Namukasa Gardens',     'Nyendo',   'Kibaswe',    5.00, '2019-07-01', 1, 2, 5),
('Lubega Farm',          'Kakika',   'Ruharo',     2.25, '2021-04-05', 1, 3, 2),
('Amoding Plantation',   'Bugembe',  'Kimaka',     7.00, '2018-09-15', 1, 4, 4),
('Mugisha Shamba',       'Laroo',    'Bardege',    1.75, '2022-12-01', 1, 5, 3);

-- Coffee Varieties
INSERT INTO CoffeeVariety (Variety_name, Variety_type, Maturity_months, Avg_yield_kg_tree, Drought_resistant) VALUES
('Robusta SL14',   'Robusta',  24, 1.50, 1),
('Arabica Bugisu', 'Arabica',  18, 0.80, 0),
('Hybrid KP532',   'Hybrid',   20, 1.20, 1),
('Robusta NACRRI', 'Robusta',  22, 1.35, 1),
('Arabica SL28',   'Arabica',  18, 0.90, 0);

-- Farm Varieties
INSERT INTO FarmVariety (Trees_count, Planting_date, Farm_ID, Variety_ID) VALUES
(500,  '2020-03-01', 1, 1),
(300,  '2020-03-01', 1, 3),
(800,  '2019-08-15', 2, 1),
(400,  '2021-05-10', 3, 2),
(1000, '2018-10-01', 4, 4),
(600,  '2018-10-01', 4, 5),
(200,  '2023-01-15', 5, 3);

-- Production Records
INSERT INTO ProductionRecord (Season_year, Season_period, Quantity_kg, Quality_grade, Record_date, Farm_varietyID, Worker_ID, Farm_ID) VALUES
(2022, 'First',  750.00, 'A', '2022-07-10', 1, 1, 1),
(2022, 'Second', 620.00, 'B', '2022-12-15', 1, 1, 1),
(2022, 'First',  1200.00,'A', '2022-07-20', 3, 2, 2),
(2023, 'First',  480.00, 'B', '2023-07-05', 4, 2, 3),
(2022, 'First',  1800.00,'A', '2022-07-25', 5, 3, 4),
(2022, 'Second', 1500.00,'B', '2022-12-20', 5, 3, 4);

-- Products
INSERT INTO Product (Product_name, Product_type, Unit_of_measure, Current_stock, Unit_cost_ugx) VALUES
('Robusta SL14 Seedlings',  'Seedling',    'Seedling',  5000,  500.00),
('NPK Fertiliser 50kg',     'Fertiliser',  'Bag',        200, 85000.00),
('Cypermethrin Pesticide',  'Pesticide',   'Litre',      150, 12000.00),
('Arabica Bugisu Seedlings','Seedling',    'Seedling',  3000,  600.00),
('Pruning Shears',          'Tool',        'Piece',      100, 25000.00);

-- Distributions
INSERT INTO Distribution (Distribution_date, Quantity, Product_ID, Farm_ID, Worker_ID) VALUES
('2022-02-10', 200,  1, 1, 1),
('2022-02-12', 500,  1, 2, 1),
('2022-03-01',   5,  2, 3, 2),
('2022-03-05',  10,  2, 4, 2),
('2022-04-20',   3,  3, 4, 3),
('2023-01-10', 100,  4, 5, 3);

-- Farm Visits
INSERT INTO FarmVisit (Visit_date, Visit_purpose, Findings, Recommendations, Follow_up_date, Worker_ID, Farm_ID) VALUES
('2022-06-15', 'Pre-harvest assessment',
 'Trees are healthy; minor aphid infestation on 10% of Robusta trees.',
 'Apply Cypermethrin pesticide. Prune affected branches.',
 '2022-07-01', 1, 1),
('2022-06-20', 'Pre-harvest assessment',
 'Farm in excellent condition. Soil pH within recommended range.',
 'Maintain current practices. Consider expanding Arabica section.',
 '2022-09-01', 2, 2),
('2022-07-01', 'Follow-up visit',
 'Aphid infestation under control after pesticide application.',
 'Continue monitoring. No further action required.',
 NULL, 1, 1),
('2023-02-10', 'Seedling distribution support',
 'New seedlings planted correctly. Spacing is adequate.',
 'Apply NPK fertiliser in 3 months.',
 '2023-05-10', 3, 5),
('2022-05-10', 'Annual farm inspection',
 'Large plantation well managed. Irrigation system functional.',
 'Add drainage channel on northern section.',
 '2022-11-01', 3, 4);


-- ────────────────────────────────────────────────────────────
--  3. VIEWS
-- ────────────────────────────────────────────────────────────

-- 3.1  Full farmer profile (joins Persons + Farmer)
CREATE OR REPLACE VIEW vw_FarmerProfile AS
SELECT
    f.Farmer_id,
    f.Registration_number,
    CONCAT(p.First_name, ' ', p.Last_name) AS Full_name,
    p.Gender,
    p.Date_of_birth,
    TIMESTAMPDIFF(YEAR, p.Date_of_birth, CURDATE()) AS Age,
    p.National_ID,
    p.Phone,
    p.Email,
    p.Address,
    f.Registration_date,
    f.Is_coop_member,
    f.Cooperative_name,
    f.Total_trees
FROM Farmer f
JOIN Persons p ON f.Person_id = p.Person_id;

-- 3.2  Full extension worker profile
CREATE OR REPLACE VIEW vw_WorkerProfile AS
SELECT
    w.Worker_id,
    w.Employee_id,
    CONCAT(p.First_name, ' ', p.Last_name) AS Full_name,
    p.Gender,
    p.Phone,
    p.Email,
    w.Specialization,
    w.Qualification,
    w.Hire_date,
    w.Is_active,
    d.District_name,
    d.Region
FROM ExtensionWorker w
JOIN Persons p ON w.Person_id = p.Person_id
JOIN District d ON w.District_ID = d.District_id;

-- 3.3  Farm summary with farmer details
CREATE OR REPLACE VIEW vw_FarmSummary AS
SELECT
    fm.Farm_id,
    fm.Farm_name,
    fm.Sub_county,
    fm.Village,
    fm.Size_acres,
    fm.Registration_date,
    fm.Is_active,
    d.District_name,
    CONCAT(p.First_name, ' ', p.Last_name) AS Farmer_name,
    f.Registration_number AS Farmer_reg_no
FROM Farm fm
JOIN Farmer  f ON fm.Farmer_ID    = f.Farmer_id
JOIN Persons p ON f.Person_id     = p.Person_id
JOIN District d ON fm.District_ID = d.District_id;

-- 3.4  Production per farm per season
CREATE OR REPLACE VIEW vw_ProductionSummary AS
SELECT
    pr.Season_year,
    pr.Season_period,
    fm.Farm_name,
    d.District_name,
    CONCAT(p.First_name, ' ', p.Last_name) AS Farmer_name,
    cv.Variety_name,
    cv.Variety_type,
    SUM(pr.Quantity_kg)  AS Total_kg,
    pr.Quality_grade,
    CONCAT(wp.First_name,' ', wp.Last_name) AS Recorded_by
FROM ProductionRecord pr
JOIN FarmVariety  fv ON pr.Farm_varietyID = fv.Farm_varietyID
JOIN CoffeeVariety cv ON fv.Variety_ID    = cv.Variety_id
JOIN Farm          fm ON pr.Farm_ID       = fm.Farm_id
JOIN Farmer        fa ON fm.Farmer_ID     = fa.Farmer_id
JOIN Persons        p ON fa.Person_id     = p.Person_id
JOIN District       d ON fm.District_ID   = d.District_id
JOIN ExtensionWorker w ON pr.Worker_ID    = w.Worker_id
JOIN Persons       wp ON w.Person_id      = wp.Person_id
GROUP BY pr.Season_year, pr.Season_period, fm.Farm_id, cv.Variety_id, pr.Quality_grade, pr.Worker_ID;

-- 3.5  Distribution log with full details
CREATE OR REPLACE VIEW vw_DistributionLog AS
SELECT
    dist.Distribution_id,
    dist.Distribution_date,
    pr.Product_name,
    pr.Product_type,
    dist.Quantity,
    pr.Unit_of_measure,
    fm.Farm_name,
    d.District_name,
    CONCAT(fp.First_name,' ', fp.Last_name) AS Farmer_name,
    CONCAT(wp.First_name,' ', wp.Last_name) AS Distributed_by
FROM Distribution dist
JOIN Product          pr ON dist.Product_ID = pr.Product_id
JOIN Farm             fm ON dist.Farm_ID    = fm.Farm_id
JOIN Farmer           fa ON fm.Farmer_ID    = fa.Farmer_id
JOIN Persons          fp ON fa.Person_id    = fp.Person_id
JOIN District          d ON fm.District_ID  = d.District_id
JOIN ExtensionWorker   w ON dist.Worker_ID  = w.Worker_id
JOIN Persons          wp ON w.Person_id     = wp.Person_id;

-- 3.6  Visit history
CREATE OR REPLACE VIEW vw_VisitHistory AS
SELECT
    fv.Visit_id,
    fv.Visit_date,
    fv.Visit_purpose,
    fv.Findings,
    fv.Recommendations,
    fv.Follow_up_date,
    fm.Farm_name,
    d.District_name,
    CONCAT(fp.First_name,' ', fp.Last_name) AS Farmer_name,
    CONCAT(wp.First_name,' ', wp.Last_name) AS Worker_name,
    w.Specialization
FROM FarmVisit        fv
JOIN Farm             fm ON fv.Farm_ID   = fm.Farm_id
JOIN Farmer           fa ON fm.Farmer_ID = fa.Farmer_id
JOIN Persons          fp ON fa.Person_id = fp.Person_id
JOIN District          d ON fm.District_ID = d.District_id
JOIN ExtensionWorker   w ON fv.Worker_ID = w.Worker_id
JOIN Persons          wp ON w.Person_id  = wp.Person_id;


-- ────────────────────────────────────────────────────────────
--  4. STORED PROCEDURES
-- ────────────────────────────────────────────────────────────

DELIMITER $$

-- 4.1  Register a new farmer (creates Persons + Farmer in one call)
CREATE PROCEDURE sp_RegisterFarmer(
    IN p_first_name      VARCHAR(60),
    IN p_last_name       VARCHAR(60),
    IN p_gender          ENUM('Male','Female','Other'),
    IN p_dob             DATE,
    IN p_national_id     VARCHAR(20),
    IN p_phone           VARCHAR(20),
    IN p_email           VARCHAR(120),
    IN p_address         VARCHAR(255),
    IN p_reg_number      VARCHAR(30),
    IN p_is_coop         TINYINT(1),
    IN p_coop_name       VARCHAR(150),
    IN p_total_trees     INT UNSIGNED,
    OUT p_farmer_id      INT UNSIGNED
)
BEGIN
    DECLARE v_person_id INT UNSIGNED;

    -- Validate National ID is unique
    IF EXISTS (SELECT 1 FROM Persons WHERE National_ID = p_national_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'National ID already registered.';
    END IF;

    INSERT INTO Persons (First_name, Last_name, Gender, Date_of_birth, National_ID, Phone, Email, Address)
    VALUES (p_first_name, p_last_name, p_gender, p_dob, p_national_id, p_phone, p_email, p_address);

    SET v_person_id = LAST_INSERT_ID();

    INSERT INTO Farmer (Registration_number, Registration_date, Is_coop_member, Cooperative_name, Total_trees, Person_id)
    VALUES (p_reg_number, CURDATE(), p_is_coop, p_coop_name, IFNULL(p_total_trees, 0), v_person_id);

    SET p_farmer_id = LAST_INSERT_ID();
END$$

-- 4.2  Record production (validates stock and links to farm variety)
CREATE PROCEDURE sp_RecordProduction(
    IN p_season_year    YEAR,
    IN p_season_period  ENUM('First','Second'),
    IN p_quantity_kg    DECIMAL(10,2),
    IN p_quality_grade  ENUM('A','B','C','D'),
    IN p_farm_variety   INT UNSIGNED,
    IN p_worker_id      INT UNSIGNED,
    IN p_farm_id        INT UNSIGNED,
    OUT p_production_id INT UNSIGNED
)
BEGIN
    -- Check that farm_variety belongs to the given farm
    IF NOT EXISTS (
        SELECT 1 FROM FarmVariety
        WHERE Farm_varietyID = p_farm_variety AND Farm_ID = p_farm_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Farm variety does not belong to the specified farm.';
    END IF;

    INSERT INTO ProductionRecord
        (Season_year, Season_period, Quantity_kg, Quality_grade, Record_date,
         Farm_varietyID, Worker_ID, Farm_ID)
    VALUES
        (p_season_year, p_season_period, p_quantity_kg, p_quality_grade,
         CURDATE(), p_farm_variety, p_worker_id, p_farm_id);

    SET p_production_id = LAST_INSERT_ID();
END$$

-- 4.3  Distribute product to farm (checks sufficient stock)
CREATE PROCEDURE sp_DistributeProduct(
    IN p_product_id   INT UNSIGNED,
    IN p_farm_id      INT UNSIGNED,
    IN p_worker_id    INT UNSIGNED,
    IN p_quantity     INT UNSIGNED,
    OUT p_dist_id     INT UNSIGNED
)
BEGIN
    DECLARE v_stock INT UNSIGNED;

    SELECT Current_stock INTO v_stock
    FROM Product WHERE Product_id = p_product_id;

    IF v_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient product stock for this distribution.';
    END IF;

    INSERT INTO Distribution (Distribution_date, Quantity, Product_ID, Farm_ID, Worker_ID)
    VALUES (CURDATE(), p_quantity, p_product_id, p_farm_id, p_worker_id);

    SET p_dist_id = LAST_INSERT_ID();
    -- Stock is reduced by trigger trg_AfterDistribution (see below)
END$$

-- 4.4  Get farmer production history (report procedure)
CREATE PROCEDURE sp_FarmerProductionReport(IN p_farmer_id INT UNSIGNED)
BEGIN
    SELECT
        p.Season_year,
        p.Season_period,
        fm.Farm_name,
        cv.Variety_name,
        p.Quantity_kg,
        p.Quality_grade,
        p.Record_date
    FROM ProductionRecord p
    JOIN FarmVariety  fv ON p.Farm_varietyID = fv.Farm_varietyID
    JOIN CoffeeVariety cv ON fv.Variety_ID   = cv.Variety_id
    JOIN Farm         fm ON p.Farm_ID        = fm.Farm_id
    WHERE fm.Farmer_ID = p_farmer_id
    ORDER BY p.Season_year DESC, p.Season_period;
END$$

-- 4.5  District production summary report
CREATE PROCEDURE sp_DistrictProductionSummary(IN p_district_id INT UNSIGNED)
BEGIN
    SELECT
        pr.Season_year,
        pr.Season_period,
        COUNT(DISTINCT fm.Farm_id)       AS Total_farms,
        COUNT(DISTINCT fa.Farmer_id)     AS Total_farmers,
        SUM(pr.Quantity_kg)              AS Total_kg_produced,
        AVG(pr.Quantity_kg)              AS Avg_kg_per_record,
        pr.Quality_grade
    FROM ProductionRecord pr
    JOIN Farm fm ON pr.Farm_ID = fm.Farm_id
    JOIN Farmer fa ON fm.Farmer_ID = fa.Farmer_id
    WHERE fm.District_ID = p_district_id
    GROUP BY pr.Season_year, pr.Season_period, pr.Quality_grade
    ORDER BY pr.Season_year DESC;
END$$

DELIMITER ;


-- ────────────────────────────────────────────────────────────
--  5. TRIGGERS
-- ────────────────────────────────────────────────────────────

DELIMITER $$

-- 5.1  Reduce product stock after a distribution is inserted
CREATE TRIGGER trg_AfterDistribution
AFTER INSERT ON Distribution
FOR EACH ROW
BEGIN
    UPDATE Product
    SET Current_stock = Current_stock - NEW.Quantity
    WHERE Product_id = NEW.Product_ID;
END$$

-- 5.2  Prevent distribution quantity exceeding current stock
CREATE TRIGGER trg_BeforeDistributionInsert
BEFORE INSERT ON Distribution
FOR EACH ROW
BEGIN
    DECLARE v_stock INT UNSIGNED;
    SELECT Current_stock INTO v_stock FROM Product WHERE Product_id = NEW.Product_ID;
    IF v_stock < NEW.Quantity THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot distribute: quantity exceeds current stock.';
    END IF;
END$$

-- 5.3  Log timestamp whenever a production record is inserted
CREATE TRIGGER trg_ProductionRecordDate
BEFORE INSERT ON ProductionRecord
FOR EACH ROW
BEGIN
    IF NEW.Record_date IS NULL THEN
        SET NEW.Record_date = CURDATE();
    END IF;
END$$

-- 5.4  Prevent deletion of a farmer who has active farms
CREATE TRIGGER trg_BeforeFarmerDelete
BEFORE DELETE ON Farmer
FOR EACH ROW
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count FROM Farm WHERE Farmer_ID = OLD.Farmer_id AND Is_active = 1;
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete farmer with active farms. Deactivate farms first.';
    END IF;
END$$

-- 5.5  Auto-generate farmer registration number if none provided
CREATE TRIGGER trg_FarmerRegNumber
BEFORE INSERT ON Farmer
FOR EACH ROW
BEGIN
    IF NEW.Registration_number IS NULL OR NEW.Registration_number = '' THEN
        SET NEW.Registration_number = CONCAT('FRM-', YEAR(CURDATE()), '-', LPAD(LAST_INSERT_ID() + 1, 4, '0'));
    END IF;
END$$

DELIMITER ;


-- ────────────────────────────────────────────────────────────
--  6. USER ROLES & PRIVILEGES
-- ────────────────────────────────────────────────────────────

-- Drop users if they already exist (safe re-run)
DROP USER IF EXISTS 'agri_admin'@'localhost';
DROP USER IF EXISTS 'extension_worker'@'localhost';
DROP USER IF EXISTS 'data_analyst'@'localhost';
DROP USER IF EXISTS 'readonly_user'@'localhost';

-- 6.1  Database Administrator – full control
CREATE USER 'agri_admin'@'localhost' IDENTIFIED BY 'Admin@Agri2024!';
GRANT ALL PRIVILEGES ON agricultural_services_db.* TO 'agri_admin'@'localhost' WITH GRANT OPTION;

-- 6.2  Extension Worker – can record visits, production and distributions
CREATE USER 'extension_worker'@'localhost' IDENTIFIED BY 'Worker@2024!';
GRANT SELECT ON agricultural_services_db.*                       TO 'extension_worker'@'localhost';
GRANT INSERT, UPDATE ON agricultural_services_db.FarmVisit       TO 'extension_worker'@'localhost';
GRANT INSERT, UPDATE ON agricultural_services_db.ProductionRecord TO 'extension_worker'@'localhost';
GRANT INSERT         ON agricultural_services_db.Distribution     TO 'extension_worker'@'localhost';
GRANT EXECUTE        ON PROCEDURE agricultural_services_db.sp_RecordProduction TO 'extension_worker'@'localhost';
GRANT EXECUTE        ON PROCEDURE agricultural_services_db.sp_DistributeProduct TO 'extension_worker'@'localhost';
GRANT EXECUTE        ON PROCEDURE agricultural_services_db.sp_FarmerProductionReport TO 'extension_worker'@'localhost';

-- 6.3  Data Analyst – read-only access + report procedures
CREATE USER 'data_analyst'@'localhost' IDENTIFIED BY 'Analyst@2024!';
GRANT SELECT ON agricultural_services_db.*                       TO 'data_analyst'@'localhost';
GRANT EXECUTE ON PROCEDURE agricultural_services_db.sp_FarmerProductionReport TO 'data_analyst'@'localhost';
GRANT EXECUTE ON PROCEDURE agricultural_services_db.sp_DistrictProductionSummary TO 'data_analyst'@'localhost';

-- 6.4  Read-only public user (e.g. ministry portal)
CREATE USER 'readonly_user'@'localhost' IDENTIFIED BY 'ReadOnly@2024!';
GRANT SELECT ON agricultural_services_db.vw_FarmerProfile   TO 'readonly_user'@'localhost';
GRANT SELECT ON agricultural_services_db.vw_FarmSummary     TO 'readonly_user'@'localhost';
GRANT SELECT ON agricultural_services_db.vw_ProductionSummary TO 'readonly_user'@'localhost';
GRANT SELECT ON agricultural_services_db.vw_DistributionLog TO 'readonly_user'@'localhost';
GRANT SELECT ON agricultural_services_db.vw_VisitHistory    TO 'readonly_user'@'localhost';

FLUSH PRIVILEGES;


-- ────────────────────────────────────────────────────────────
--  7. USEFUL QUERIES  (demonstration / testing)
-- ────────────────────────────────────────────────────────────

-- Q1: List all farmers with their farms and total production
SELECT
    fp.Full_name AS Farmer,
    fp.Registration_number,
    fs.Farm_name,
    fs.District_name,
    SUM(pr.Quantity_kg) AS Total_production_kg
FROM vw_FarmerProfile fp
JOIN Farm f ON fp.Farmer_id = f.Farmer_ID
LEFT JOIN ProductionRecord pr ON f.Farm_id = pr.Farm_ID
JOIN vw_FarmSummary fs ON f.Farm_id = fs.Farm_id
GROUP BY fp.Farmer_id, f.Farm_id
ORDER BY Total_production_kg DESC;

-- Q2: Production summary by variety type
SELECT
    cv.Variety_type,
    COUNT(DISTINCT fv.Farm_ID)   AS Farms_growing,
    SUM(fv.Trees_count)          AS Total_trees,
    SUM(pr.Quantity_kg)          AS Total_kg_produced
FROM CoffeeVariety cv
JOIN FarmVariety     fv ON cv.Variety_id = fv.Variety_ID
LEFT JOIN ProductionRecord pr ON fv.Farm_varietyID = pr.Farm_varietyID
GROUP BY cv.Variety_type;

-- Q3: Extension workers and number of farms they supervise
SELECT
    wp.Full_name AS Worker,
    wp.Specialization,
    wp.District_name,
    COUNT(DISTINCT fv.Farm_ID)  AS Farms_visited,
    COUNT(fv.Visit_id)          AS Total_visits
FROM vw_WorkerProfile wp
LEFT JOIN FarmVisit fv ON wp.Worker_id = fv.Worker_ID
GROUP BY wp.Worker_id;

-- Q4: Products running low (stock < 100)
SELECT Product_name, Product_type, Current_stock, Unit_of_measure
FROM Product
WHERE Current_stock < 100
ORDER BY Current_stock;

-- Q5: Call the farmer production report procedure
CALL sp_FarmerProductionReport(1);

-- Q6: District production summary
CALL sp_DistrictProductionSummary(1);


-- ────────────────────────────────────────────────────────────
--  END OF SCRIPT
-- ────────────────────────────────────────────────────────────
