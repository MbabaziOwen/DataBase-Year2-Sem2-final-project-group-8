CREATE DATABASE agricultural_services_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE agricultural_services_db;


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
show tables;