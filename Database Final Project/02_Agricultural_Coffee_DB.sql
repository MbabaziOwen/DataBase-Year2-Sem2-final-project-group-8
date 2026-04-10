-- ============================================================
--  AGRICULTURAL SERVICES DATABASE
--  Ministry of Agriculture – Coffee Growers Management System
--  Database Name : agri_coffee_db
--  Platform      : MySQL 8.0+
--  Author        : Group Project – Database Programming
--  Date          : April 2026
-- ============================================================
--  This file covers:
--    MILESTONE 3 – Table Structure & Data Validation
--    MILESTONE 4 – Security & Automation
-- ============================================================
--  HOW TO RUN THIS FILE
--  In MySQL Workbench or VS Code (SQLTools):
--    1. Open this file
--    2. Run the whole script top to bottom
--    3. All tables, data, views, procedures, and triggers
--       will be created automatically.
-- ============================================================


-- ============================================================
--  STEP 0: SET UP THE DATABASE
-- ============================================================

-- Remove the old database if it exists, then create a fresh one.
-- utf8mb4 supports all characters including emoji.
DROP DATABASE IF EXISTS agri_coffee_db;

CREATE DATABASE agri_coffee_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Tell MySQL to use this database for all commands below.
USE agri_coffee_db;

-- Allow tables to be created in any order (we turn this back on at the end).
SET FOREIGN_KEY_CHECKS = 0;

-- Use strict mode so bad data is rejected instead of silently changed.
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';


-- ============================================================
--  STEP 1: CREATE TABLES
--  Order: Districts → Persons → Farmers → ExtensionWorkers
--         → CoffeeVarieties → Farms → FarmVarieties
--         → ProductionRecords → Products → Distributions
--         → FarmVisits → AuditLog
-- ============================================================


-- ------------------------------------------------------------
-- TABLE 1: Districts
-- Stores the geographic districts where farmers and workers live.
-- Every person and every farm must belong to a district.
-- ------------------------------------------------------------
CREATE TABLE Districts (
    district_id   INT          NOT NULL AUTO_INCREMENT,  -- unique ID, auto-numbered
    district_name VARCHAR(120) NOT NULL,                 -- e.g. "Masaka"
    region        VARCHAR(50)  NOT NULL,                 -- e.g. "Central", "Western"
    country       VARCHAR(70)  NOT NULL DEFAULT 'Uganda',-- default country is Uganda

    CONSTRAINT pk_districts      PRIMARY KEY (district_id),
    CONSTRAINT uq_district_name  UNIQUE (district_name)  -- no two districts with same name
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- TABLE 2: Persons  [SUPERTYPE]
-- Stores shared information for ALL people in the system.
-- Both Farmers and Extension Workers are sub-types of Person.
-- The column person_type tells us which sub-type a row belongs to.
-- (This is called DISJOINT SPECIALISATION in EERD – a person
--  can only be one type at a time: Farmer OR ExtensionWorker.)
-- ------------------------------------------------------------
CREATE TABLE Persons (
    person_id    INT          NOT NULL AUTO_INCREMENT,
    first_name   VARCHAR(50)  NOT NULL,
    last_name    VARCHAR(50)  NOT NULL,
    gender       ENUM('Male','Female','Other') NOT NULL,
    date_of_birth DATE,
    national_id  VARCHAR(20)  NOT NULL,           -- national ID card number
    phone   VARCHAR(20),      --small update on phone number
CONSTRAINT chk_phone CHECK (phone IS NULL OR phone REGEXP '^[0-9+][0-9 ]{6,19}$'),
    email        VARCHAR(100),
    district_id  INT          NOT NULL,            -- which district this person lives in
    address      TEXT,
    -- Disjoint discriminator: tells the system if this is a Farmer or an Extension Worker
    person_type  ENUM('Farmer','ExtensionWorker') NOT NULL,
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_persons       PRIMARY KEY (person_id),
    CONSTRAINT uq_national_id   UNIQUE (national_id),       -- each national ID is unique

    -- A person must live in a real district
    CONSTRAINT fk_person_district
        FOREIGN KEY (district_id) REFERENCES Districts(district_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    -- Basic email validation: must have @ and a dot
    CONSTRAINT chk_email  CHECK (email IS NULL OR email LIKE '%@%.%'),
    -- Date of birth must be in the past
    CONSTRAINT chk_dob    CHECK (date_of_birth IS NULL OR date_of_birth < CURRENT_DATE)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- TABLE 3: Farmers  [SUBTYPE of Persons]
-- Extra details that apply ONLY to farmers.
-- Linked to Persons via person_id (ISA / Generalisation link).
-- ------------------------------------------------------------
CREATE TABLE Farmers (
    farmer_id           INT         NOT NULL AUTO_INCREMENT,
    person_id           INT         NOT NULL,  -- link to Persons table (ISA relationship)
    registration_number VARCHAR(20) NOT NULL,  -- e.g. "FARM-2024-0001"
    registration_date   DATE        NOT NULL,
    is_coop_member      TINYINT(1)  NOT NULL DEFAULT 0,  -- 1 = yes, 0 = no
    cooperative_name    VARCHAR(60),           -- name of cooperative (if member)
    total_trees         INT                  DEFAULT 0,   -- total coffee trees owned

    CONSTRAINT pk_farmers       PRIMARY KEY (farmer_id),
    CONSTRAINT uq_farmer_person UNIQUE (person_id),        -- one person = one farmer record
    CONSTRAINT uq_reg_number    UNIQUE (registration_number),

    -- Must link to a real person
    CONSTRAINT fk_farmer_person
        FOREIGN KEY (person_id) REFERENCES Persons(person_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT chk_total_trees CHECK (total_trees >= 0),
    CONSTRAINT chk_reg_date    CHECK (registration_date <= CURRENT_DATE)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- TABLE 4: ExtensionWorkers  [SUBTYPE of Persons]
-- Extra details that apply ONLY to Ministry extension workers.
-- Also linked to Persons via person_id (ISA / Generalisation link).
-- ------------------------------------------------------------
CREATE TABLE ExtensionWorkers (
    worker_id            INT         NOT NULL AUTO_INCREMENT,
    person_id            INT         NOT NULL,  -- link to Persons table (ISA relationship)
    employee_id          VARCHAR(20) NOT NULL,  -- staff ID e.g. "EW-2021-005"
    specialization       VARCHAR(100),          -- e.g. "Coffee Agronomy"
    qualification        VARCHAR(100) NOT NULL, -- e.g. "Bachelor's in Agriculture"
    hire_date            DATE         NOT NULL,
    assigned_district_id INT,                   -- which district they are assigned to (nullable)
    is_active            TINYINT(1)  NOT NULL DEFAULT 1,  -- 1 = active, 0 = inactive

    CONSTRAINT pk_workers        PRIMARY KEY (worker_id),
    CONSTRAINT uq_worker_person  UNIQUE (person_id),     -- one person = one worker record
    CONSTRAINT uq_employee_id    UNIQUE (employee_id),

    CONSTRAINT fk_worker_person
        FOREIGN KEY (person_id) REFERENCES Persons(person_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    -- Worker may or may not be assigned to a district
    CONSTRAINT fk_worker_district
        FOREIGN KEY (assigned_district_id) REFERENCES Districts(district_id)
        ON UPDATE CASCADE ON DELETE SET NULL,

    CONSTRAINT chk_hire_date CHECK (hire_date <= CURRENT_DATE)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- TABLE 5: CoffeeVarieties
-- Catalogue of all coffee types/varieties supported.
-- Farms can grow multiple varieties (see FarmVarieties table).
-- ------------------------------------------------------------
CREATE TABLE CoffeeVarieties (
    variety_id        INT          NOT NULL AUTO_INCREMENT,
    variety_name      VARCHAR(120) NOT NULL,  -- e.g. "Robusta SL14"
    variety_type      ENUM('Arabica','Robusta','Liberica') NOT NULL,
    maturity_months   INT          NOT NULL DEFAULT 36,   -- months from planting to first harvest
    avg_yield_kg_tree DECIMAL(5,2),                       -- average kg per tree per season
    drought_resistant TINYINT(1)   NOT NULL DEFAULT 0,    -- 1 = tolerates drought
    description       TEXT,

    CONSTRAINT pk_varieties    PRIMARY KEY (variety_id),
    CONSTRAINT uq_variety_name UNIQUE (variety_name),
    CONSTRAINT chk_maturity    CHECK (maturity_months > 0),
    CONSTRAINT chk_yield       CHECK (avg_yield_kg_tree IS NULL OR avg_yield_kg_tree > 0)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- TABLE 6: Farms
-- A farmer can own one or more farms.
-- Each farm is located in a district.
-- ------------------------------------------------------------
CREATE TABLE Farms (
    farm_id           INT           NOT NULL AUTO_INCREMENT,
    farmer_id         INT           NOT NULL,  -- owner of this farm
    farm_name         VARCHAR(150),
    district_id       INT           NOT NULL,  -- location district
    sub_county        VARCHAR(100),
    village           VARCHAR(100),
    size_acres        DECIMAL(8,2)  NOT NULL,  -- farm area in acres
    gps_latitude      DECIMAL(10,7),           -- GPS coordinates (optional)
    gps_longitude     DECIMAL(10,7),
    registration_date DATE          NOT NULL DEFAULT (CURRENT_DATE),
    is_active         TINYINT(1)    NOT NULL DEFAULT 1,  -- 1 = active farm

    CONSTRAINT pk_farms        PRIMARY KEY (farm_id),

    CONSTRAINT fk_farm_farmer
        FOREIGN KEY (farmer_id)   REFERENCES Farmers(farmer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_farm_district
        FOREIGN KEY (district_id) REFERENCES Districts(district_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT chk_size      CHECK (size_acres > 0),
    CONSTRAINT chk_latitude  CHECK (gps_latitude  IS NULL OR gps_latitude  BETWEEN -90  AND 90),
    CONSTRAINT chk_longitude CHECK (gps_longitude IS NULL OR gps_longitude BETWEEN -180 AND 180)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- TABLE 7: FarmVarieties  [ASSOCIATIVE ENTITY]
-- This table links Farms and CoffeeVarieties.
-- It exists because one farm can grow many varieties,
-- and one variety can be grown on many farms (Many-to-Many).
-- The EERD calls this an "Associative Entity" (double border).
-- ------------------------------------------------------------
CREATE TABLE FarmVarieties (
    farm_id       INT  NOT NULL,
    variety_id    INT  NOT NULL,
    trees_count   INT  NOT NULL,   -- number of trees of this variety on this farm
    planting_date DATE,            -- when these trees were planted

    -- Composite primary key: a farm+variety combination must be unique
    CONSTRAINT pk_farm_varieties PRIMARY KEY (farm_id, variety_id),

    CONSTRAINT fk_fv_farm
        FOREIGN KEY (farm_id)    REFERENCES Farms(farm_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT fk_fv_variety
        FOREIGN KEY (variety_id) REFERENCES CoffeeVarieties(variety_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT chk_trees CHECK (trees_count > 0)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- TABLE 8: ProductionRecords
-- Records how much coffee was harvested from a farm
-- in a particular season.
-- Linked to Farms and CoffeeVarieties.
-- recorded_by is nullable – some records may not have a worker.
-- ------------------------------------------------------------
CREATE TABLE ProductionRecords (
    production_id  INT           NOT NULL AUTO_INCREMENT,
    farm_id        INT           NOT NULL,
    variety_id     INT           NOT NULL,   -- which variety was harvested
    season_year    YEAR          NOT NULL,
    season_period  ENUM('First','Second') NOT NULL,  -- Uganda has two coffee seasons
    quantity_kg    DECIMAL(10,2) NOT NULL,
    quality_grade  ENUM('AA','A','B','C','Ungraded') NOT NULL DEFAULT 'Ungraded',
    record_date    DATE          NOT NULL,
    recorded_by    INT,                      -- the extension worker who recorded this (nullable)
    notes          TEXT,

    CONSTRAINT pk_production       PRIMARY KEY (production_id),
    -- A farm can only have ONE record per variety per season
    CONSTRAINT uq_production_entry UNIQUE (farm_id, variety_id, season_year, season_period),

    CONSTRAINT fk_prod_farm
        FOREIGN KEY (farm_id)    REFERENCES Farms(farm_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_prod_variety
        FOREIGN KEY (variety_id) REFERENCES CoffeeVarieties(variety_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_prod_worker
        FOREIGN KEY (recorded_by) REFERENCES ExtensionWorkers(worker_id)
        ON UPDATE CASCADE ON DELETE SET NULL,

    CONSTRAINT chk_quantity CHECK (quantity_kg >= 0),
    CONSTRAINT chk_year     CHECK (season_year >= 2000)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- TABLE 9: Products
-- The catalogue of items the Ministry can distribute to farmers
-- (seedlings, fertilizers, pesticides, equipment, etc.).
-- ------------------------------------------------------------
CREATE TABLE Products (
    product_id      INT           NOT NULL AUTO_INCREMENT,
    product_name    VARCHAR(120)  NOT NULL,
    product_type    ENUM('Seedling','Fertilizer','Pesticide','Equipment','Other') NOT NULL,
    unit_of_measure VARCHAR(20)   NOT NULL,  -- e.g. "kg", "litre", "Seedling", "Unit"
    current_stock   INT           NOT NULL DEFAULT 0,
    unit_cost_ugx   DECIMAL(12,2),           -- cost in Uganda Shillings (nullable)
    description     TEXT,

    CONSTRAINT pk_products     PRIMARY KEY (product_id),
    CONSTRAINT uq_product_name UNIQUE (product_name),
    CONSTRAINT chk_stock       CHECK (current_stock >= 0),
    CONSTRAINT chk_cost        CHECK (unit_cost_ugx IS NULL OR unit_cost_ugx >= 0)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- TABLE 10: Distributions
-- Records every time a product is given to a farmer.
-- Links Farmers, Products, Farms, and ExtensionWorkers.
-- farm_id and worker_id are nullable (not always recorded).
-- ------------------------------------------------------------
CREATE TABLE Distributions (
    distribution_id   INT  NOT NULL AUTO_INCREMENT,
    farmer_id         INT  NOT NULL,
    product_id        INT  NOT NULL,
    farm_id           INT,                -- which farm the product was delivered to (optional)
    worker_id         INT,                -- which worker handled the distribution (optional)
    distribution_date DATE NOT NULL,
    quantity          INT  NOT NULL,
    notes             TEXT,

    CONSTRAINT pk_distributions PRIMARY KEY (distribution_id),

    CONSTRAINT fk_dist_farmer
        FOREIGN KEY (farmer_id)  REFERENCES Farmers(farmer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_dist_product
        FOREIGN KEY (product_id) REFERENCES Products(product_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_dist_farm
        FOREIGN KEY (farm_id)    REFERENCES Farms(farm_id)
        ON UPDATE CASCADE ON DELETE SET NULL,

    CONSTRAINT fk_dist_worker
        FOREIGN KEY (worker_id)  REFERENCES ExtensionWorkers(worker_id)
        ON UPDATE CASCADE ON DELETE SET NULL,

    CONSTRAINT chk_dist_qty  CHECK (quantity > 0),
    CONSTRAINT chk_dist_date CHECK (distribution_date <= CURRENT_DATE)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- TABLE 11: FarmVisits
-- Records every farm visit made by an extension worker.
-- An extension worker visits a farm to give advice,
-- check crop health, or follow up on previous recommendations.
-- ------------------------------------------------------------
CREATE TABLE FarmVisits (
    visit_id         INT          NOT NULL AUTO_INCREMENT,
    farm_id          INT          NOT NULL,
    worker_id        INT          NOT NULL,
    visit_date       DATE         NOT NULL,
    visit_purpose    VARCHAR(200),
    findings         TEXT,
    recommendations  TEXT,
    follow_up_date   DATE,         -- date for next follow-up visit (nullable)

    CONSTRAINT pk_visits      PRIMARY KEY (visit_id),

    CONSTRAINT fk_visit_farm
        FOREIGN KEY (farm_id)   REFERENCES Farms(farm_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_visit_worker
        FOREIGN KEY (worker_id) REFERENCES ExtensionWorkers(worker_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT chk_visit_date  CHECK (visit_date    <= CURRENT_DATE),
    CONSTRAINT chk_follow_up   CHECK (follow_up_date IS NULL OR follow_up_date >= visit_date)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- TABLE 12: AuditLog
-- Automatically records who changed what and when.
-- Triggers (defined below) write to this table whenever
-- important data is inserted, updated, or deleted.
-- ------------------------------------------------------------
CREATE TABLE AuditLog (
    log_id       INT            NOT NULL AUTO_INCREMENT,
    table_name   VARCHAR(60)    NOT NULL,                            -- which table was changed
    operation    ENUM('INSERT','UPDATE','DELETE') NOT NULL,          -- what action was done
    record_id    INT,                                                -- ID of the affected row
    old_value    TEXT,                                               -- what the data looked like before
    new_value    TEXT,                                               -- what the data looks like after
    performed_by VARCHAR(80)    NOT NULL DEFAULT (USER()),           -- MySQL user who made the change
    performed_at TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- exact date and time

    CONSTRAINT pk_audit PRIMARY KEY (log_id)
) ENGINE=InnoDB;


-- Re-enable foreign key checks now that all tables exist.
SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================
--  STEP 2: SAMPLE DATA
--  Insert example rows into every table.
--  ORDER MATTERS: parent tables must have data before children.
-- ============================================================


-- ---- Districts ----
-- Seven districts across Uganda where the system operates.
INSERT INTO Districts (district_name, region) VALUES
('Kampala',  'Central'),
('Masaka',   'Central'),
('Mbarara',  'Western'),
('Kabale',   'Western'),
('Jinja',    'Eastern'),
('Mbale',    'Eastern'),
('Gulu',     'Northern');


-- ---- Persons (Farmers) ----
-- Ten people who are farmers. person_type = 'Farmer'.
INSERT INTO Persons (first_name, last_name, gender, date_of_birth, national_id,
                     phone, email, district_id, address, person_type) VALUES
('James',   'Ochieng',   'Male',   '1978-03-15', 'CM78031501', '0772100001', 'james.ochieng@mail.ug',   2, 'Masaka Town',  'Farmer'),
('Grace',   'Nakato',    'Female', '1985-07-22', 'CF85072201', '0754200002', 'g.nakato@mail.ug',        2, 'Nyendo',       'Farmer'),
('Robert',  'Mugisha',   'Male',   '1972-11-05', 'CM72110501', '0703300003', 'r.mugisha@mail.ug',       3, 'Mbarara City', 'Farmer'),
('Agnes',   'Atim',      'Female', '1990-01-30', 'CF90013001', '0772400004', NULL,                      4, 'Kabale Town',  'Farmer'),
('Peter',   'Ssemakula', 'Male',   '1968-09-12', 'CM68091201', '0754500005', 'p.ssemakula@mail.ug',     2, 'Kalungu',      'Farmer'),
('Mary',    'Namaganda', 'Female', '1983-05-17', 'CF83051701', '0703600006', NULL,                      3, 'Ibanda',       'Farmer'),
('John',    'Okello',    'Male',   '1975-12-28', 'CM75122801', '0772700007', 'j.okello@mail.ug',        5, 'Jinja City',   'Farmer'),
('Sarah',   'Nantege',   'Female', '1992-04-09', 'CF92040901', '0754800008', NULL,                      6, 'Mbale Town',   'Farmer'),
('David',   'Tumwine',   'Male',   '1980-08-24', 'CM80082401', '0703900009', 'd.tumwine@mail.ug',       3, 'Kiruhura',     'Farmer'),
('Esther',  'Ayella',    'Female', '1988-06-14', 'CF88061401', '0772010010', NULL,                      1, 'Kawempe',      'Farmer');


-- ---- Persons (Extension Workers) ----
-- Five ministry staff. person_type = 'ExtensionWorker'.
INSERT INTO Persons (first_name, last_name, gender, date_of_birth, national_id,
                     phone, email, district_id, address, person_type) VALUES
('Samuel',   'Wasswa',    'Male',   '1985-02-18', 'CM85021801', '0772011001', 's.wasswa@moa.go.ug',    2, 'Masaka',  'ExtensionWorker'),
('Patricia', 'Nabukenya', 'Female', '1990-09-25', 'CF90092501', '0754012002', 'p.nabukenya@moa.go.ug', 3, 'Mbarara', 'ExtensionWorker'),
('Henry',    'Lutalo',    'Male',   '1978-07-11', 'CM78071101', '0703013003', 'h.lutalo@moa.go.ug',    4, 'Kabale',  'ExtensionWorker'),
('Ruth',     'Adong',     'Female', '1987-03-04', 'CF87030401', '0772014004', 'r.adong@moa.go.ug',     5, 'Jinja',   'ExtensionWorker'),
('Michael',  'Kato',      'Male',   '1982-11-19', 'CM82111901', '0754015005', 'm.kato@moa.go.ug',      6, 'Mbale',   'ExtensionWorker');


-- ---- Farmers ----
-- One row per farmer. Linked to Persons by person_id.
-- person_id 1–10 were inserted as Farmers above.
INSERT INTO Farmers (person_id, registration_number, registration_date,
                     is_coop_member, cooperative_name, total_trees) VALUES
(1,  'FARM-2020-0001', '2020-02-10', 1, 'Masaka Coffee Cooperative', 3200),
(2,  'FARM-2020-0002', '2020-03-15', 1, 'Masaka Coffee Cooperative', 1500),
(3,  'FARM-2019-0003', '2019-11-20', 0, NULL,                        4000),
(4,  'FARM-2021-0004', '2021-01-08', 0, NULL,                        800),
(5,  'FARM-2018-0005', '2018-06-30', 1, 'Kalungu Farmers Group',     5500),
(6,  'FARM-2022-0006', '2022-04-22', 0, NULL,                        2100),
(7,  'FARM-2020-0007', '2020-09-14', 1, 'Jinja Coffee Union',        1800),
(8,  'FARM-2023-0008', '2023-02-01', 0, NULL,                        600),
(9,  'FARM-2019-0009', '2019-07-17', 1, 'Kiruhura Coffee Group',     3700),
(10, 'FARM-2021-0010', '2021-10-05', 0, NULL,                        950);


-- ---- ExtensionWorkers ----
-- One row per worker. Linked to Persons by person_id.
-- person_id 11–15 were inserted as ExtensionWorkers above.
INSERT INTO ExtensionWorkers (person_id, employee_id, specialization,
                               qualification, hire_date, assigned_district_id) VALUES
(11, 'EW-2018-001', 'Coffee Agronomy',           "Bachelor's in Agriculture",            '2018-01-15', 2),
(12, 'EW-2019-002', 'Soil Science',               "Master's in Soil Science",             '2019-03-01', 3),
(13, 'EW-2017-003', 'Pest and Disease Management',"Bachelor's in Agriculture",            '2017-06-20', 4),
(14, 'EW-2020-004', 'Coffee Processing',          "Diploma in Agricultural Technology",   '2020-08-10', 5),
(15, 'EW-2021-005', 'Farm Management',            "Bachelor's in Agricultural Economics", '2021-11-01', 6);


-- ---- CoffeeVarieties ----
-- Five varieties of coffee the ministry supports.
INSERT INTO CoffeeVarieties (variety_name, variety_type, maturity_months,
                              avg_yield_kg_tree, drought_resistant, description) VALUES
('Robusta SL14',      'Robusta', 30, 0.85, 1, 'Hardy lowland variety, disease resistant'),
('Arabica Ruiru 11',  'Arabica', 36, 0.65, 0, 'High quality Arabica, susceptible to CBD'),
('Arabica CIFC 7963', 'Arabica', 42, 0.70, 0, 'CBD resistant Arabica with excellent cup quality'),
('Robusta CABI 3',    'Robusta', 28, 0.90, 1, 'High yielding Robusta, suited to espresso market'),
('Arabica K7',        'Arabica', 38, 0.60, 0, 'Traditional Arabica, popular in highland areas');


-- ---- Farms ----
-- Twelve farms owned by the farmers above.
-- farmer_id 1 has two farms, farmer_id 9 has two farms.
INSERT INTO Farms (farmer_id, farm_name, district_id, sub_county, village,
                   size_acres, gps_latitude, gps_longitude, registration_date) VALUES
(1,  'Ochieng Farm A',  2, 'Nyendo-Ssenyange', 'Kisunga',   4.50, -0.3500, 31.7300, '2020-02-12'),
(1,  'Ochieng Farm B',  2, 'Buwunga',          'Kaliiti',   3.00, -0.3800, 31.7500, '2020-02-12'),
(2,  'Nakato Estate',   2, 'Nyendo-Ssenyange', 'Bukakata',  2.00, -0.3600, 31.7400, '2020-03-20'),
(3,  'Mugisha Coffee',  3, 'Kashari',          'Rutooma',   6.50, -0.6100, 30.6500, '2019-12-01'),
(4,  'Atim Garden',     4, 'Kabale Town',      'Kitabi',    1.50, -1.2500, 29.9800, '2021-01-15'),
(5,  'Ssemakula Farm',  2, 'Kalungu',          'Kiyumba',   8.00, -0.4200, 31.8100, '2018-07-05'),
(6,  'Namaganda Plot',  3, 'Ibanda Town',      'Kikoni',    3.20, -0.1300, 30.4900, '2022-05-10'),
(7,  'Okello Coffee',   5, 'Jinja City',       'Masese',    2.80,  0.4300, 33.2000, '2020-09-20'),
(8,  'Nantege Shamba',  6, 'Mbale City',       'Namatala',  1.10,  1.0700, 34.1700, '2023-02-15'),
(9,  'Tumwine Estate',  3, 'Kiruhura',         'Sanga',     5.40, -0.2400, 30.8600, '2019-07-20'),
(9,  'Tumwine Annex',   3, 'Kiruhura',         'Rwembogo',  2.60, -0.2600, 30.8800, '2020-03-01'),
(10, 'Ayella Plot',     1, 'Kawempe',          'Makerere',  1.30,  0.3400, 32.5700, '2021-10-10');


-- ---- FarmVarieties (Associative Entity) ----
-- Each row says: "Farm X grows Variety Y, with N trees, planted on date D."
INSERT INTO FarmVarieties (farm_id, variety_id, trees_count, planting_date) VALUES
(1,  1, 1800, '2018-04-01'),
(1,  4, 1400, '2019-06-15'),
(2,  1, 1200, '2017-03-10'),
(3,  2, 1000, '2018-08-20'),
(3,  3,  500, '2019-01-10'),
(4,  1, 2500, '2016-05-05'),
(4,  4, 1500, '2017-09-20'),
(5,  2,  500, '2020-03-15'),
(5,  3,  300, '2020-03-15'),
(6,  1, 3000, '2015-02-10'),
(6,  4, 2500, '2016-07-01'),
(7,  3, 1500, '2019-11-20'),
(7,  5,  600, '2020-01-05'),
(8,  2, 1500, '2018-06-30'),
(8,  4, 1300, '2019-03-12'),
(9,  2,  600, '2022-04-01'),
(10, 1, 1800, '2017-08-15'),
(10, 5, 1000, '2018-02-20'),
(11, 1, 2000, '2019-05-10'),
(11, 4,  700, '2019-05-10'),
(12, 3,  800, '2020-09-15'),
(12, 5,  150, '2021-01-20');


-- ---- Products ----
-- Eight products the Ministry can distribute to farmers.
INSERT INTO Products (product_name, product_type, unit_of_measure,
                      current_stock, unit_cost_ugx, description) VALUES
('Robusta SL14 Seedlings',       'Seedling',   'Seedling', 50000,   500.00, 'Certified Robusta seedlings from NACORI'),
('Arabica Ruiru 11 Seedlings',   'Seedling',   'Seedling', 30000,   700.00, 'Certified Arabica seedlings from NACORI'),
('NPK 17-17-17 Fertilizer',      'Fertilizer', 'kg',       15000,  3500.00, 'Balanced fertilizer for coffee'),
('Calcium Ammonium Nitrate',     'Fertilizer', 'kg',       20000,  2800.00, 'Nitrogen-rich fertilizer for top dressing'),
('Dimethoate Pesticide',         'Pesticide',  'litre',     3000, 18000.00, 'Contact pesticide for aphids and CBB'),
('Copper Oxychloride Fungicide', 'Pesticide',  'kg',        5000, 12000.00, 'Fungicide for CBD and leaf rust control'),
('Sprayer 20L',                  'Equipment',  'Unit',       500, 85000.00, 'Manual knapsack sprayer'),
('Pruning Shears',               'Equipment',  'Unit',      1200, 15000.00, 'Stainless steel pruning shears');


-- ---- ProductionRecords ----
-- Harvest data for farms across seasons 2022 and 2023.
-- recorded_by references worker_id in ExtensionWorkers.
INSERT INTO ProductionRecords (farm_id, variety_id, season_year, season_period,
                                quantity_kg, quality_grade, record_date, recorded_by, notes) VALUES
(1,  1, 2022, 'First',  2100.00, 'A',       '2022-07-15', 1, 'Good yield, some CBD observed'),
(1,  4, 2022, 'First',  1850.00, 'AA',      '2022-07-15', 1, 'Excellent quality'),
(1,  1, 2022, 'Second',  980.00, 'A',       '2022-12-10', 1, NULL),
(1,  4, 2022, 'Second',  820.00, 'A',       '2022-12-10', 1, NULL),
(2,  1, 2022, 'First',  1300.00, 'A',       '2022-07-20', 1, NULL),
(3,  2, 2022, 'First',   550.00, 'AA',      '2022-08-01', 2, 'Premium Arabica quality'),
(3,  3, 2022, 'First',   280.00, 'AA',      '2022-08-01', 2, NULL),
(4,  1, 2022, 'First',  3200.00, 'A',       '2022-07-10', 2, 'Highest yield in the district'),
(4,  4, 2022, 'First',  1900.00, 'AA',      '2022-07-10', 2, NULL),
(6,  1, 2022, 'First',  4100.00, 'B',       '2022-07-25', 1, 'Late harvesting affected quality'),
(6,  4, 2022, 'First',  3200.00, 'A',       '2022-07-25', 1, NULL),
(7,  3, 2022, 'First',   750.00, 'AA',      '2022-08-05', 2, NULL),
(8,  2, 2022, 'First',  1100.00, 'A',       '2022-07-30', 4, NULL),
(10, 1, 2022, 'First',  2300.00, 'A',       '2022-07-18', 2, NULL),
(10, 5, 2022, 'First',   480.00, 'AA',      '2022-07-18', 2, 'Highland Arabica, excellent aroma'),
(4,  1, 2023, 'First',  3350.00, 'AA',      '2023-07-12', 2, 'Improved following pest management'),
(6,  1, 2023, 'First',  4250.00, 'A',       '2023-07-26', 1, NULL),
(1,  1, 2023, 'First',  2250.00, 'AA',      '2023-07-16', 1, NULL),
(3,  2, 2023, 'First',   620.00, 'AA',      '2023-08-02', 2, NULL),
(10, 1, 2023, 'First',  2400.00, 'A',       '2023-07-19', 2, NULL);


-- ---- Distributions ----
-- Records of products given to farmers.
-- Stock deduction is handled automatically by a trigger below.
INSERT INTO Distributions (farmer_id, product_id, farm_id, worker_id,
                            distribution_date, quantity, notes) VALUES
(1,  1,  1,  1, '2023-02-10', 500, 'Seedling replacement programme'),
(2,  2,  3,  1, '2023-02-15', 300, 'New planting block'),
(3,  3,  4,  2, '2023-03-01', 200, '2023 fertilizer support'),
(4,  6,  5,  3, '2023-03-05',  50, 'CBD prevention spray'),
(5,  1,  6,  1, '2023-02-20', 800, 'Gap-filling seedlings'),
(5,  4,  6,  1, '2023-04-10', 300, 'Top dressing fertilizer'),
(6,  5,  7,  2, '2023-05-01',  10, 'CBB control pesticide'),
(7,  7,  8,  4, '2023-03-20',   5, 'Sprayer provision'),
(8,  2,  9,  4, '2023-03-12', 200, 'Seedling distribution'),
(9,  3, 10,  2, '2023-04-05', 150, 'Fertilizer support'),
(10, 8, 12,  5, '2023-04-18',  20, 'Pruning tools distribution');


-- ---- FarmVisits ----
-- Advisory visits by extension workers to farms.
INSERT INTO FarmVisits (farm_id, worker_id, visit_date, visit_purpose,
                         findings, recommendations, follow_up_date) VALUES
(1,  1, '2023-01-15', 'Routine agronomic inspection',
         'Moderate CBD on older trees; pruning needed',
         'Apply copper oxychloride; prune shaded branches', '2023-02-15'),
(4,  2, '2023-01-20', 'Soil fertility assessment',
         'Low pH in lower field sections',
         'Apply lime at 500kg/acre before rainy season',   '2023-03-20'),
(6,  1, '2023-02-05', 'Yield improvement advisory',
         'Weeding delayed; inter-row spacing too narrow',
         'Staggered weeding schedule; remove excess plants','2023-03-05'),
(8,  4, '2023-02-12', 'New farmer orientation',
         'Farm layout good but no mulching',
         'Introduce organic mulching to conserve moisture', '2023-03-12'),
(3,  2, '2023-03-08', 'Post-harvest review',
         'Processing is manual; losses at fermentation stage',
         'Consider joining a processing cooperative',       '2023-05-08'),
(10, 2, '2023-03-15', 'Pest scouting',
         'Antestia bug infestation in upper plots',
         'Apply Dimethoate spray; set pheromone traps',    '2023-04-15'),
(2,  1, '2023-04-02', 'Fertilizer application check',
         'Fertilizer applied correctly after training',
         'Continue programme; monitor leaf colour',         '2023-07-02'),
(5,  3, '2023-04-10', 'CBD management review',
         'CBD levels reduced significantly after fungicide',
         'Good progress; continue preventive spraying',     NULL),
(7,  4, '2023-05-05', 'Harvesting guidance',
         'Some immature cherry picked early',
         'Train labourers on selective picking',            '2023-06-05'),
(12, 5, '2023-05-18', 'New farm registration visit',
         'Small but well-maintained plot',
         'Expand shade tree cover and begin composting',    '2023-08-18');


-- ============================================================
--  STEP 3: VIEWS
--  Views are saved SELECT queries that act like virtual tables.
--  They make it easy to get common reports without writing
--  long queries each time.
-- ============================================================


-- ---- View 1: Complete Farmer Profile ----
-- Shows farmer details combined with their person and district info.
CREATE OR REPLACE VIEW FarmerDetailsView AS
SELECT
    f.farmer_id,
    f.registration_number,
    CONCAT(p.first_name, ' ', p.last_name)  AS full_name,
    p.gender,
    p.phone,
    p.email,
    p.national_id,
    d.district_name,
    d.region,
    p.address,
    f.registration_date,
    f.is_coop_member,
    f.cooperative_name,
    f.total_trees,
    COUNT(DISTINCT fa.farm_id)              AS number_of_farms,
    ROUND(SUM(fa.size_acres), 2)            AS total_farm_size_acres
FROM Farmers    f
JOIN Persons    p  ON p.person_id   = f.person_id
JOIN Districts  d  ON d.district_id = p.district_id
LEFT JOIN Farms fa ON fa.farmer_id  = f.farmer_id AND fa.is_active = 1
GROUP BY f.farmer_id, f.registration_number,
         p.first_name, p.last_name, p.gender, p.phone, p.email, p.national_id,
         d.district_name, d.region, p.address,
         f.registration_date, f.is_coop_member, f.cooperative_name, f.total_trees;


-- ---- View 2: Production Summary per Farmer per Season ----
-- Useful for seeing total harvest per farmer per year.
CREATE OR REPLACE VIEW ProductionSummaryView AS
SELECT
    f.farmer_id,
    CONCAT(p.first_name, ' ', p.last_name)          AS farmer_name,
    d.district_name,
    pr.season_year,
    pr.season_period,
    SUM(pr.quantity_kg)                             AS total_kg,
    COUNT(DISTINCT pr.farm_id)                      AS farms_producing,
    GROUP_CONCAT(DISTINCT cv.variety_name ORDER BY cv.variety_name SEPARATOR ', ')
                                                    AS varieties_grown
FROM ProductionRecords pr
JOIN Farms           fa ON fa.farm_id    = pr.farm_id
JOIN Farmers         f  ON f.farmer_id  = fa.farmer_id
JOIN Persons         p  ON p.person_id  = f.person_id
JOIN Districts       d  ON d.district_id= p.district_id
JOIN CoffeeVarieties cv ON cv.variety_id= pr.variety_id
GROUP BY f.farmer_id, farmer_name, d.district_name, pr.season_year, pr.season_period;


-- ---- View 3: Distribution History ----
-- Shows every product distribution with full details.
CREATE OR REPLACE VIEW DistributionHistoryView AS
SELECT
    di.distribution_id,
    di.distribution_date,
    CONCAT(pf.first_name, ' ', pf.last_name)        AS farmer_name,
    fm.registration_number,
    pr.product_name,
    pr.product_type,
    pr.unit_of_measure,
    di.quantity,
    ROUND(di.quantity * pr.unit_cost_ugx, 2)        AS total_value_ugx,
    CONCAT(pw.first_name, ' ', pw.last_name)        AS facilitated_by,
    fa.farm_name,
    dd.district_name                                AS farmer_district
FROM Distributions        di
JOIN Farmers              fm ON fm.farmer_id  = di.farmer_id
JOIN Persons              pf ON pf.person_id  = fm.person_id
JOIN Products             pr ON pr.product_id = di.product_id
JOIN Districts            dd ON dd.district_id= pf.district_id
LEFT JOIN ExtensionWorkers ew ON ew.worker_id  = di.worker_id
LEFT JOIN Persons          pw ON pw.person_id  = ew.person_id
LEFT JOIN Farms            fa ON fa.farm_id    = di.farm_id;


-- ---- View 4: Extension Worker Activity Summary ----
-- Shows how many visits, distributions and records each worker handled.
CREATE OR REPLACE VIEW ExtensionWorkerActivityView AS
SELECT
    ew.worker_id,
    ew.employee_id,
    CONCAT(pw.first_name, ' ', pw.last_name)        AS worker_name,
    ew.specialization,
    ew.qualification,
    d.district_name                                 AS assigned_district,
    COUNT(DISTINCT fv.visit_id)                     AS total_farm_visits,
    COUNT(DISTINCT dist.distribution_id)            AS distributions_facilitated,
    COUNT(DISTINCT pr.production_id)                AS production_records_entered,
    MAX(fv.visit_date)                              AS last_visit_date
FROM ExtensionWorkers    ew
JOIN Persons             pw   ON pw.person_id  = ew.person_id
LEFT JOIN Districts      d    ON d.district_id = ew.assigned_district_id
LEFT JOIN FarmVisits     fv   ON fv.worker_id  = ew.worker_id
LEFT JOIN Distributions  dist ON dist.worker_id= ew.worker_id
LEFT JOIN ProductionRecords pr ON pr.recorded_by = ew.worker_id
GROUP BY ew.worker_id, ew.employee_id, worker_name,
         ew.specialization, ew.qualification, d.district_name;


-- ---- View 5: Farm Production Dashboard ----
-- One-stop view of each farm: size, varieties, production totals.
CREATE OR REPLACE VIEW FarmProductionDashboard AS
SELECT
    fa.farm_id,
    fa.farm_name,
    CONCAT(p.first_name, ' ', p.last_name)          AS farmer_name,
    d.district_name,
    fa.sub_county,
    fa.size_acres,
    SUM(fvar.trees_count)                           AS total_trees_on_farm,
    GROUP_CONCAT(DISTINCT cv.variety_name ORDER BY cv.variety_name SEPARATOR ', ')
                                                    AS varieties,
    COALESCE(SUM(CASE WHEN pr.season_year = YEAR(CURRENT_DATE)
                      THEN pr.quantity_kg END), 0)  AS current_year_kg,
    COUNT(DISTINCT vis.visit_id)                    AS visits_received
FROM Farms              fa
JOIN Farmers            fm   ON fm.farmer_id  = fa.farmer_id
JOIN Persons            p    ON p.person_id   = fm.person_id
JOIN Districts          d    ON d.district_id = fa.district_id
LEFT JOIN FarmVarieties fvar ON fvar.farm_id  = fa.farm_id
LEFT JOIN CoffeeVarieties cv ON cv.variety_id = fvar.variety_id
LEFT JOIN ProductionRecords pr ON pr.farm_id  = fa.farm_id
LEFT JOIN FarmVisits    vis  ON vis.farm_id   = fa.farm_id
WHERE fa.is_active = 1
GROUP BY fa.farm_id, fa.farm_name, farmer_name,
         d.district_name, fa.sub_county, fa.size_acres;


-- ============================================================
--  STEP 4: STORED PROCEDURES
--  A stored procedure is a saved block of SQL code you can
--  call by name. It avoids repeating the same logic and
--  keeps the application code clean.
-- ============================================================

DELIMITER $$


-- ---- Procedure 1: Register a New Farmer ----
-- Inserts one row into Persons and one row into Farmers.
-- Uses a TRANSACTION so both inserts succeed or both are rolled back.
-- OUT parameters return the result to the caller.
CREATE PROCEDURE sp_RegisterFarmer(
    IN  p_first_name       VARCHAR(50),
    IN  p_last_name        VARCHAR(50),
    IN  p_gender           ENUM('Male','Female','Other'),
    IN  p_dob              DATE,
    IN  p_national_id      VARCHAR(20),
    IN  p_phone            VARCHAR(20),
    IN  p_email            VARCHAR(100),
    IN  p_district_id      INT,
    IN  p_address          TEXT,
    IN  p_coop_member      TINYINT(1),
    IN  p_cooperative_name VARCHAR(60),
    OUT p_farmer_id        INT,
    OUT p_reg_number       VARCHAR(20),
    OUT p_message          VARCHAR(200)
)
BEGIN
    DECLARE v_person_id INT;
    DECLARE v_seq       INT;

    -- If any SQL error occurs, roll back and return an error message.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_farmer_id  = NULL;
        SET p_reg_number = NULL;
        SET p_message    = 'ERROR: Registration failed. Check for duplicate national ID or invalid district.';
    END;

    START TRANSACTION;

    -- Insert the person record first (supertype)
    INSERT INTO Persons (first_name, last_name, gender, date_of_birth, national_id,
                         phone, email, district_id, address, person_type)
    VALUES (p_first_name, p_last_name, p_gender, p_dob, p_national_id,
            p_phone, p_email, p_district_id, p_address, 'Farmer');

    SET v_person_id = LAST_INSERT_ID();

    -- Auto-generate registration number: FARM-YEAR-NNNN
    SELECT IFNULL(MAX(farmer_id), 0) + 1 INTO v_seq FROM Farmers;
    SET p_reg_number = CONCAT('FARM-', YEAR(CURRENT_DATE), '-', LPAD(v_seq, 4, '0'));

    -- Insert the farmer record (subtype)
    INSERT INTO Farmers (person_id, registration_number, registration_date,
                         is_coop_member, cooperative_name)
    VALUES (v_person_id, p_reg_number, CURRENT_DATE, p_coop_member, p_cooperative_name);

    SET p_farmer_id = LAST_INSERT_ID();
    COMMIT;

    SET p_message = CONCAT('SUCCESS: Farmer registered. ID=', p_farmer_id,
                           ', Reg No=', p_reg_number);
END$$


-- ---- Procedure 2: Record Seasonal Production ----
-- Adds a harvest record for a specific farm and variety.
-- Validates that the farm is active before inserting.
CREATE PROCEDURE sp_RecordProduction(
    IN  p_farm_id       INT,
    IN  p_variety_id    INT,
    IN  p_year          YEAR,
    IN  p_period        ENUM('First','Second'),
    IN  p_qty_kg        DECIMAL(10,2),
    IN  p_grade         ENUM('AA','A','B','C','Ungraded'),
    IN  p_worker_id     INT,
    IN  p_notes         TEXT,
    OUT p_production_id INT,
    OUT p_message       VARCHAR(200)
)
BEGIN
    DECLARE v_farm_active INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_production_id = NULL;
        SET p_message = 'ERROR: Could not record production. Possible duplicate entry.';
    END;

    -- Check that the farm exists and is active
    SELECT COUNT(*) INTO v_farm_active
    FROM Farms WHERE farm_id = p_farm_id AND is_active = 1;

    IF v_farm_active = 0 THEN
        SET p_production_id = NULL;
        SET p_message = 'ERROR: Farm not found or is inactive.';
    ELSEIF p_qty_kg < 0 THEN
        SET p_production_id = NULL;
        SET p_message = 'ERROR: Quantity in kg cannot be negative.';
    ELSE
        START TRANSACTION;

        INSERT INTO ProductionRecords
            (farm_id, variety_id, season_year, season_period,
             quantity_kg, quality_grade, record_date, recorded_by, notes)
        VALUES
            (p_farm_id, p_variety_id, p_year, p_period,
             p_qty_kg, p_grade, CURRENT_DATE, p_worker_id, p_notes);

        SET p_production_id = LAST_INSERT_ID();
        COMMIT;
        SET p_message = CONCAT('SUCCESS: Production record ID=', p_production_id, ' saved.');
    END IF;
END$$


-- ---- Procedure 3: Distribute a Product to a Farmer ----
-- Checks stock, records the distribution, and deducts from stock.
-- Returns remaining stock and a success/error message.
CREATE PROCEDURE sp_DistributeProduct(
    IN  p_farmer_id       INT,
    IN  p_product_id      INT,
    IN  p_farm_id         INT,
    IN  p_worker_id       INT,
    IN  p_quantity        INT,
    IN  p_notes           TEXT,
    OUT p_distribution_id INT,
    OUT p_remaining_stock INT,
    OUT p_message         VARCHAR(200)
)
BEGIN
    DECLARE v_stock INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_distribution_id = NULL;
        SET p_message = 'ERROR: Distribution failed unexpectedly.';
    END;

    -- Check available stock
    SELECT current_stock INTO v_stock
    FROM Products WHERE product_id = p_product_id;

    IF v_stock < p_quantity THEN
        -- Not enough stock – reject the request
        SET p_distribution_id = NULL;
        SET p_remaining_stock = v_stock;
        SET p_message = CONCAT('ERROR: Insufficient stock. Available: ', v_stock,
                               ', Requested: ', p_quantity);
    ELSE
        START TRANSACTION;

        -- Record the distribution.
        -- NOTE: The trigger trg_after_distribution_insert automatically
        -- deducts the quantity from Products.current_stock when this INSERT runs.
        -- We do NOT manually deduct here to avoid double-counting.
        INSERT INTO Distributions
            (farmer_id, product_id, farm_id, worker_id,
             distribution_date, quantity, notes)
        VALUES
            (p_farmer_id, p_product_id, p_farm_id, p_worker_id,
             CURRENT_DATE, p_quantity, p_notes);

        SET p_distribution_id = LAST_INSERT_ID();

        -- Read the remaining stock AFTER the trigger has deducted
        SELECT current_stock INTO p_remaining_stock
        FROM Products WHERE product_id = p_product_id;

        COMMIT;
        SET p_message = CONCAT('SUCCESS: Distribution ID=', p_distribution_id,
                               '. Stock remaining: ', p_remaining_stock);
    END IF;
END$$


-- ---- Procedure 4: Get Farmer Production Report ----
-- Returns all production records for a specific farmer.
-- No OUT parameters – results come back as a SELECT result set.
CREATE PROCEDURE sp_FarmerProductionReport(
    IN p_farmer_id INT
)
BEGIN
    SELECT
        CONCAT(p.first_name, ' ', p.last_name)  AS farmer_name,
        f.registration_number,
        fa.farm_name,
        cv.variety_name,
        cv.variety_type,
        pr.season_year,
        pr.season_period,
        pr.quantity_kg,
        pr.quality_grade
    FROM ProductionRecords pr
    JOIN Farms           fa ON fa.farm_id    = pr.farm_id
    JOIN Farmers         f  ON f.farmer_id  = fa.farmer_id
    JOIN Persons         p  ON p.person_id  = f.person_id
    JOIN CoffeeVarieties cv ON cv.variety_id= pr.variety_id
    WHERE f.farmer_id = p_farmer_id
    ORDER BY pr.season_year DESC, pr.season_period, fa.farm_name;
END$$


-- ---- Procedure 5: District Production Summary for a Year ----
-- Aggregates total coffee production per district for a given year.
CREATE PROCEDURE sp_DistrictProductionSummary(
    IN p_year YEAR
)
BEGIN
    SELECT
        d.district_name,
        d.region,
        COUNT(DISTINCT f.farmer_id)  AS active_farmers,
        COUNT(DISTINCT fa.farm_id)   AS active_farms,
        SUM(pr.quantity_kg)          AS total_production_kg,
        ROUND(AVG(pr.quantity_kg),2) AS avg_per_farm_kg,
        SUM(CASE WHEN pr.quality_grade IN ('AA','A')
                 THEN pr.quantity_kg ELSE 0 END) AS premium_grade_kg
    FROM Districts d
    JOIN Persons   p  ON p.district_id  = d.district_id
    JOIN Farmers   f  ON f.person_id    = p.person_id
    JOIN Farms     fa ON fa.farmer_id   = f.farmer_id
    JOIN ProductionRecords pr ON pr.farm_id = fa.farm_id AND pr.season_year = p_year
    GROUP BY d.district_id, d.district_name, d.region
    ORDER BY total_production_kg DESC;
END$$


DELIMITER ;


-- ============================================================
--  STEP 5: TRIGGERS
--  A trigger is code that runs AUTOMATICALLY when a specific
--  event happens on a table (INSERT, UPDATE, or DELETE).
--  We use triggers for two purposes:
--    1. Audit logging – record who changed what.
--    2. Business rule enforcement – e.g. deduct stock.
-- ============================================================

DELIMITER $$


-- ---- Trigger 1: After a new farmer is registered ----
-- Writes an entry to AuditLog recording the new farmer's ID.
CREATE TRIGGER trg_after_farmer_insert
AFTER INSERT ON Farmers
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, operation, record_id, new_value)
    VALUES (
        'Farmers',
        'INSERT',
        NEW.farmer_id,
        CONCAT('Farmer registered: ', NEW.registration_number,
               ' | person_id=', NEW.person_id)
    );
END$$


-- ---- Trigger 2: After a production record is inserted ----
-- Logs each new harvest entry automatically.
CREATE TRIGGER trg_after_production_insert
AFTER INSERT ON ProductionRecords
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, operation, record_id, new_value)
    VALUES (
        'ProductionRecords',
        'INSERT',
        NEW.production_id,
        CONCAT('Farm=', NEW.farm_id,
               ' | Variety=', NEW.variety_id,
               ' | Year=',    NEW.season_year,
               ' | Period=',  NEW.season_period,
               ' | Qty=',     NEW.quantity_kg, 'kg',
               ' | Grade=',   NEW.quality_grade)
    );
END$$


-- ---- Trigger 3: After a distribution is inserted ----
-- Deducts the distributed quantity from the product stock AND
-- logs the event in AuditLog.
CREATE TRIGGER trg_after_distribution_insert
AFTER INSERT ON Distributions
FOR EACH ROW
BEGIN
    -- Deduct from stock
    UPDATE Products
    SET current_stock = current_stock - NEW.quantity
    WHERE product_id = NEW.product_id;

    -- Log the distribution
    INSERT INTO AuditLog (table_name, operation, record_id, new_value)
    VALUES (
        'Distributions',
        'INSERT',
        NEW.distribution_id,
        CONCAT('Farmer=', NEW.farmer_id,
               ' | Product=', NEW.product_id,
               ' | Qty=',     NEW.quantity,
               ' | Date=',    NEW.distribution_date)
    );
END$$


-- ---- Trigger 4: When a farm visit is inserted ----
-- Logs the visit automatically so management can track activity.
CREATE TRIGGER trg_after_visit_insert
AFTER INSERT ON FarmVisits
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, operation, record_id, new_value)
    VALUES (
        'FarmVisits',
        'INSERT',
        NEW.visit_id,
        CONCAT('Farm=', NEW.farm_id,
               ' | Worker=', NEW.worker_id,
               ' | Date=',   NEW.visit_date,
               ' | Purpose=', IFNULL(NEW.visit_purpose, 'N/A'))
    );
END$$


-- ---- Trigger 5: Before a person is updated ----
-- Saves the OLD national_id and person_type before any change
-- is made, so we have a full history.
CREATE TRIGGER trg_before_person_update
BEFORE UPDATE ON Persons
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, operation, record_id, old_value, new_value)
    VALUES (
        'Persons',
        'UPDATE',
        OLD.person_id,
        CONCAT('national_id=', OLD.national_id,
               ' | type=', OLD.person_type),
        CONCAT('national_id=', NEW.national_id,
               ' | type=', NEW.person_type)
    );
END$$


DELIMITER ;


-- ============================================================
--  STEP 6: DATABASE USERS AND PRIVILEGES  (Security)
--  Different users get different levels of access so that
--  sensitive data is protected.
-- ============================================================

-- Create a read-only analyst user (for reporting, no changes allowed)
CREATE USER IF NOT EXISTS 'analyst_user'@'localhost' IDENTIFIED BY 'Analyst@2024!';
GRANT SELECT ON agri_coffee_db.* TO 'analyst_user'@'localhost';

-- Create a data-entry user (can add and read, cannot delete or change structure)
CREATE USER IF NOT EXISTS 'data_entry_user'@'localhost' IDENTIFIED BY 'DataEntry@2024!';
GRANT SELECT, INSERT ON agri_coffee_db.* TO 'data_entry_user'@'localhost';

-- Create a supervisor user (can read, add, and update – but not drop tables or delete)
CREATE USER IF NOT EXISTS 'supervisor_user'@'localhost' IDENTIFIED BY 'Supervisor@2024!';
GRANT SELECT, INSERT, UPDATE ON agri_coffee_db.* TO 'supervisor_user'@'localhost';

-- Create a full admin user (all privileges on this database)
CREATE USER IF NOT EXISTS 'agri_admin'@'localhost' IDENTIFIED BY 'AgriAdmin@2024!';
GRANT ALL PRIVILEGES ON agri_coffee_db.* TO 'agri_admin'@'localhost';

-- Apply all privilege changes immediately
FLUSH PRIVILEGES;


-- ============================================================
--  END OF FILE
--  To verify the database was created correctly, run:
--    SHOW TABLES;
--    SELECT COUNT(*) FROM Farmers;
--    SELECT COUNT(*) FROM ProductionRecords;
--    SELECT * FROM FarmerDetailsView;
-- ============================================================
