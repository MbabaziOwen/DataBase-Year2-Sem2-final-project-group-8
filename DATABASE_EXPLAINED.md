# Coffee Growers Management System — Database Explained

**Group 8 | Year 2 Semester 2 Final Project**

This document explains every part of `agricultural_services_db.sql` in plain language — what each section does, why it exists, and how the pieces connect to each other.

---

## Table of Contents

1. [What the database is for](#1-what-the-database-is-for)
2. [How the file is structured](#2-how-the-file-is-structured)
3. [Key concepts you need to know first](#3-key-concepts-you-need-to-know-first)
4. [Database creation](#4-database-creation)
5. [Tables — Geographic hierarchy](#5-tables--geographic-hierarchy)
6. [Tables — People (Persons and subtypes)](#6-tables--people-persons-and-subtypes)
7. [Tables — Farm operations](#7-tables--farm-operations)
8. [Tables — Coffee varieties](#8-tables--coffee-varieties)
9. [Tables — Audit log](#9-tables--audit-log)
10. [How the tables link together (relationships)](#10-how-the-tables-link-together-relationships)
11. [ALTER TABLE — adding extra columns](#11-alter-table--adding-extra-columns)
12. [Triggers — automatic actions](#12-triggers--automatic-actions)
13. [Sample data](#13-sample-data)
14. [Views — saved queries](#14-views--saved-queries)
15. [Stored procedures — reusable tasks](#15-stored-procedures--reusable-tasks)
16. [User roles and permissions](#16-user-roles-and-permissions)
17. [Sample queries](#17-sample-queries)
18. [Complete table reference](#18-complete-table-reference)

---

## 1. What the database is for

This database tracks everything related to coffee farming in Uganda:

- **Who** the farmers and government workers are
- **Where** each farm is located (district → subcounty → village)
- **What** coffee varieties are grown on each farm
- **How much** coffee each farm produces each season
- **What** farming inputs (seedlings, fertiliser, tools) have been distributed to farmers
- **When** extension workers visited farms and what they found
- **Support requests** that farmers raise with the Ministry of Agriculture

---

## 2. How the file is structured

The SQL file is divided into these sections, in order:

| Section | What it does |
|---|---|
| Database creation | Creates the empty database |
| CREATE TABLE (×18) | Defines the structure of every table |
| TRIGGERS (×4) | Automatic actions that fire when data changes |
| ALTER TABLE (×8) | Adds extra columns after the tables are created |
| Sample data (INSERT) | Puts test data into every table |
| Views (×5) | Saves complex SELECT queries so they can be reused |
| Stored procedures (×5) | Saves reusable multi-step operations |
| User roles | Creates database users with different permission levels |
| Sample queries | Example SELECTs showing how to use the database |

---

## 3. Key concepts you need to know first

### Primary Key (PK)
A column that uniquely identifies every row in a table. No two rows can have the same value, and it can never be empty. Example: `Farmer_id` in the `Farmers` table.

### Foreign Key (FK)
A column in one table that points to the Primary Key of another table. It creates a link between tables. Example: `Farmer_id` in the `Farms` table points to `Farmers.Farmer_id` — this tells you which farmer owns that farm.

### ON UPDATE CASCADE
If the primary key value in the parent table changes, the foreign key in the child table automatically updates to match. You never end up with broken links.

### ON DELETE CASCADE
If a row in the parent table is deleted, all related rows in the child table are automatically deleted too.

### ON DELETE RESTRICT
Prevents you from deleting a parent row if child rows still reference it. Used where you want to protect data — for example you cannot delete a farmer who still has registered farms.

### UNIQUE constraint
Ensures no two rows in a column have the same value. Different from a Primary Key — a table can have many UNIQUE columns but only one Primary Key.

### CHECK constraint
A rule that a value must satisfy before it can be saved. Example: `CHECK (Size_acres > 0)` prevents someone entering a negative farm size.

### DEFAULT
The value that is automatically used if you do not provide one. Example: `DEFAULT 'Active'` means a new worker is marked Active unless you say otherwise.

### NULL / NOT NULL
`NULL` means the column is optional — it is allowed to be empty. `NOT NULL` means it is required — you must always provide a value.

### ENUM
A column that can only hold one of a fixed list of values. Example: `ENUM('Male','Female','Other')` — the gender column can only ever be one of those three words.

### Supertype / Subtype (ISA hierarchy)
A design pattern where one "parent" table (`Persons`) holds shared information, and separate "child" tables (`Farmers`, `ExtensionWorkers`) hold role-specific information. Every farmer is a person, so their name and phone are stored in `Persons`, while their registration number is stored in `Farmers`.

### Associative entity
A table that exists only to connect two other tables in a many-to-many relationship. Example: `FarmVarieties` connects `Farms` and `CoffeeVarieties` — one farm can grow many varieties, and one variety can be grown on many farms.

---

## 4. Database creation

```sql
DROP DATABASE IF EXISTS agricultural_services_db;
CREATE DATABASE agricultural_services_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE agricultural_services_db;
```

| Line | What it does |
|---|---|
| `DROP DATABASE IF EXISTS` | Deletes the database if it already exists, so the script can run cleanly from scratch |
| `CREATE DATABASE` | Creates a fresh, empty database |
| `CHARACTER SET utf8mb4` | Supports all Unicode characters including emojis and special letters (e.g. accented characters in names) |
| `COLLATE utf8mb4_unicode_ci` | Controls how text is sorted and compared — `ci` means case-insensitive, so "james" and "JAMES" are treated as equal |
| `USE` | Tells MySQL to run all following statements inside this database |

---

## 5. Tables — Geographic hierarchy

These four tables store location information. They are arranged in a chain from largest to smallest: **Region → District → Subcounty → Village**.

### Region
```sql
CREATE TABLE Region (
    region_ID   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    region_name VARCHAR(100)    NOT NULL,
    CONSTRAINT uq_region_name UNIQUE (region_name)
);
```
Stores the four regions of Uganda: Central, Western, Northern, Eastern. Every district belongs to a region.

### Districts
```sql
CREATE TABLE Districts (
    District_ID   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    district_name VARCHAR(100)    NOT NULL,
    region_ID     INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_district_region
        FOREIGN KEY (region_ID) REFERENCES Region(region_ID)
        ON UPDATE CASCADE,
    CONSTRAINT uq_district_name UNIQUE (district_name)
);
```
Stores districts (e.g. Kampala, Mbarara). The `region_ID` foreign key links each district to its region. `uq_district_name` prevents two districts having the same name.

### Subcounty
```sql
CREATE TABLE Subcounty (
    Subcounty_ID   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Subcounty_name VARCHAR(100)    NOT NULL,
    District_ID    INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_subcounty_district
        FOREIGN KEY (District_ID) REFERENCES Districts(District_ID)
        ON UPDATE CASCADE
);
```
Each subcounty sits inside a district.

### Village
```sql
CREATE TABLE Village (
    Village_ID   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Village_name VARCHAR(100)    NOT NULL,
    Subcounty_ID INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_village_subcounty
        FOREIGN KEY (Subcounty_ID) REFERENCES Subcounty(Subcounty_ID)
        ON UPDATE CASCADE
);
```
The smallest geographic unit. Both `Persons` and `Farms` reference a `Village_ID` so their exact location is recorded relationally rather than as plain text.

---

## 6. Tables — People (Persons and subtypes)

The system uses an **ISA (Is-A) hierarchy** for people. One central `Persons` table holds information that every person shares, and separate tables hold role-specific details.

```
Persons (supertype — shared info)
   ├── Farmers          (disjoint — a person cannot be both a farmer AND an extension worker)
   ├── ExtensionWorkers (disjoint)
   ├── MinistryStaff    (overlapping — a person can be both staff AND an admin)
   └── SystemAdmin      (overlapping)
```

**Disjoint** means roles are mutually exclusive — the database enforces this by putting a `UNIQUE` constraint on the `Person_id` column in both `Farmers` and `ExtensionWorkers`. If someone is already a farmer, you cannot insert them as an extension worker because their `Person_id` already exists in that table.

**Overlapping** means the same person can hold multiple roles simultaneously — `MinistryStaff` and `SystemAdmin` do NOT have this unique constraint, so the same person can appear in both tables.

### Persons
```sql
CREATE TABLE Persons (
    Person_id   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Name        VARCHAR(120)    NOT NULL,
    National_ID VARCHAR(20)     NOT NULL,
    Gender      VARCHAR(10)     NOT NULL,
    Phone       VARCHAR(20)     NOT NULL,
    Email       VARCHAR(120)    NULL,
    Address     VARCHAR(255)    NULL,
    Village_ID  INT UNSIGNED    NOT NULL,
    CONSTRAINT uq_person_nin UNIQUE (National_ID),
    CONSTRAINT fk_person_village FOREIGN KEY (Village_ID) REFERENCES Village(Village_ID) ON UPDATE CASCADE,
    CONSTRAINT chk_person_gender CHECK (Gender IN ('Male','Female','Other'))
);
```

| Column | Explanation |
|---|---|
| `Person_id` | Auto-generated unique number for every person |
| `Name` | Full name (first + last combined) |
| `National_ID` | Uganda National ID number — must be unique across all persons |
| `Gender` | Restricted to Male, Female, or Other by a CHECK constraint |
| `Email` | Optional (`NULL` allowed) |
| `Village_ID` | Links this person to their village in the geographic chain |

### MinistryStaff
```sql
CREATE TABLE MinistryStaff (
    StaffID   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Role      VARCHAR(100)    NOT NULL,
    Hire_date DATE            NOT NULL,
    Person_id INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_staff_person
        FOREIGN KEY (Person_id) REFERENCES Persons(Person_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
```
Stores Ministry of Agriculture staff who approve support requests and handle product distributions. `ON DELETE CASCADE` means if a person is deleted from `Persons`, their staff record is automatically removed too.

### SystemAdmin
```sql
CREATE TABLE SystemAdmin (
    AdminID      INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Access_level VARCHAR(50)     NOT NULL,
    Status       VARCHAR(30)     NOT NULL DEFAULT 'Active',
    Activity     VARCHAR(100)    NULL,
    Person_id    INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_admin_person
        FOREIGN KEY (Person_id) REFERENCES Persons(Person_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
```
Stores system administrators who manage database access. The same person can be both a `MinistryStaff` member and a `SystemAdmin` at the same time — this is the **overlapping** rule.

### ExtensionWorkers
```sql
CREATE TABLE ExtensionWorkers (
    Worker_id     INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Qualification VARCHAR(100)    NOT NULL,
    Hire_date     DATE            NOT NULL,
    Status        VARCHAR(30)     NOT NULL DEFAULT 'Active',
    District_ID   INT UNSIGNED    NOT NULL,
    Person_id     INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_extworker_person   FOREIGN KEY (Person_id)   REFERENCES Persons(Person_id)  ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_extworker_district FOREIGN KEY (District_ID) REFERENCES Districts(District_ID) ON UPDATE CASCADE,
    CONSTRAINT uq_extworker_person UNIQUE (Person_id)
);
```
Government field workers who visit farms, record production, and distribute inputs. Each worker is assigned to one district. `UNIQUE (Person_id)` enforces the disjoint rule — a farmer cannot also be an extension worker.

### Farmers
```sql
CREATE TABLE Farmers (
    Farmer_id           INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Registration_date   DATE            NOT NULL DEFAULT (CURDATE()),
    Registration_number VARCHAR(30)     NOT NULL,
    Person_id           INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_farmer_person   FOREIGN KEY (Person_id) REFERENCES Persons(Person_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_farmer_person   UNIQUE (Person_id),
    CONSTRAINT uq_farmer_reg_num  UNIQUE (Registration_number)
);
```
Coffee farmers registered with the system. `Registration_number` is a unique government-issued ID like `FRM-2020-0001`. `DEFAULT (CURDATE())` automatically records today's date when a farmer is registered.

### SupportRequest
```sql
CREATE TABLE SupportRequest (
    Request_ID   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    request_type VARCHAR(80)     NOT NULL,
    description  TEXT            NULL,
    status       VARCHAR(30)     NOT NULL DEFAULT 'Pending',
    assigned_to  INT UNSIGNED    NULL,
    resolved_by  INT UNSIGNED    NULL,
    Farmer_ID    INT UNSIGNED    NOT NULL,
    ...
    CONSTRAINT chk_sr_status CHECK (status IN ('Pending','Assigned','InProgress','Resolved','Closed'))
);
```
A farmer can raise a request for seedlings, fertiliser, or pesticide. The workflow goes: `Pending` → `Assigned` (staff assigned) → `InProgress` → `Resolved` → `Closed`. Both `assigned_to` and `resolved_by` are nullable foreign keys pointing to `MinistryStaff` — a request may not yet have been assigned or resolved.

---

## 7. Tables — Farm operations

### Farms
```sql
CREATE TABLE Farms (
    Farm_id     INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Farm_name   VARCHAR(150)    NOT NULL,
    Size_acres  DECIMAL(8,2)    NOT NULL,
    Coffee_Type VARCHAR(50)     NOT NULL,
    Start_Year  YEAR            NOT NULL,
    Farmer_id   INT UNSIGNED    NOT NULL,
    Village_ID  INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_plot_farmer  FOREIGN KEY (Farmer_id)  REFERENCES Farmers(Farmer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_plot_village FOREIGN KEY (Village_ID) REFERENCES Village(Village_ID) ON UPDATE CASCADE,
    CONSTRAINT chk_plot_size CHECK (Size_acres > 0)
);
```
Each row is one coffee farm. A farmer can own many farms (one-to-many). `ON DELETE RESTRICT` on the farmer FK means you **cannot delete a farmer** who still has farms registered — you must remove their farms first. `DECIMAL(8,2)` for `Size_acres` stores values like `3.50` acres precisely.

### FarmVisits
```sql
CREATE TABLE FarmVisits (
    Visit_id       INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Visit_purpose  VARCHAR(200)    NOT NULL,
    Visit_date     DATE            NOT NULL,
    Findings       TEXT            NULL,
    Follow_up_date DATE            NULL,
    Worker_id      INT UNSIGNED    NOT NULL,
    Farmer_ID      INT UNSIGNED    NOT NULL,
    Farm_id        INT UNSIGNED    NOT NULL,
    ...
    CONSTRAINT chk_fv_followup CHECK (Follow_up_date IS NULL OR Follow_up_date > Visit_date)
);
```
Records every official visit made by an extension worker to a farm. Three foreign keys are required: **who** visited (`Worker_id`), **whose** farm it is (`Farmer_ID`), and **which specific farm** was visited (`Farm_id`). The CHECK constraint ensures the follow-up date, if provided, is always after the visit date — you cannot schedule a follow-up in the past.

### Products
```sql
CREATE TABLE Products (
    Product_id   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Product_type VARCHAR(80)     NOT NULL,
    Product_name VARCHAR(150)    NOT NULL,
    Quantity     INT UNSIGNED    NOT NULL DEFAULT 0,
    CONSTRAINT uq_product_name UNIQUE (Product_name),
    CONSTRAINT chk_product_qty CHECK (Quantity >= 0)
);
```
The stock catalogue — seeds, fertiliser, pesticides, tools. `Quantity` is the current stock level. `CHECK (Quantity >= 0)` prevents stock from going negative. The trigger (see Section 12) automatically decreases this number each time a distribution is recorded.

### ProductionRecords
```sql
CREATE TABLE ProductionRecords (
    Production_id INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Season        VARCHAR(30)     NOT NULL,
    Record_date   DATE            NOT NULL,
    Quantity      DECIMAL(10,2)   NOT NULL,
    Farm_id       INT UNSIGNED    NOT NULL,
    Worker_id     INT UNSIGNED    NOT NULL,
    CONSTRAINT fk_pr_plot      FOREIGN KEY (Farm_id)   REFERENCES Farms(Farm_id)            ON UPDATE CASCADE,
    CONSTRAINT fk_pr_extworker FOREIGN KEY (Worker_id) REFERENCES ExtensionWorkers(Worker_id) ON UPDATE CASCADE,
    CONSTRAINT chk_pr_qty CHECK (Quantity > 0)
);
```
Records how much coffee a farm produced in a given season. `Season` is a text field like `'Season A 2022'`. `Quantity` is in kilograms. The extension worker who measured and recorded the harvest is linked via `Worker_id`.

### Distributions
```sql
CREATE TABLE Distributions (
    Distribution_id   INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    Product_type      VARCHAR(80)     NOT NULL,
    Distribution_date DATE            NOT NULL DEFAULT (CURDATE()),
    Product_ID        INT UNSIGNED    NOT NULL,
    Farmer_ID         INT UNSIGNED    NOT NULL,
    Farm_id           INT UNSIGNED    NOT NULL,
    Staff_ID          INT UNSIGNED    NOT NULL,
    ...
);
```
Records every time the Ministry gives a product to a farmer. Four foreign keys: the product given, the farmer who received it, the specific farm it was delivered to, and the Ministry Staff member who handled it. The date defaults to today if not provided.

---

## 8. Tables — Coffee varieties

### CoffeeVarieties
```sql
CREATE TABLE CoffeeVarieties (
    variety_id        INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    variety_name      VARCHAR(100)    NOT NULL,
    variety_type      ENUM('Arabica','Robusta','Liberica') NOT NULL,
    maturity_months   INT UNSIGNED    NULL,
    avg_yield_kg_tree DECIMAL(6,2)    NULL,
    drought_resistant TINYINT(1)      NOT NULL DEFAULT 0,
    description       TEXT            NULL,
    CONSTRAINT uq_variety_name UNIQUE (variety_name)
);
```
A reference catalogue of coffee varieties. `variety_type` is an ENUM — only `Arabica`, `Robusta`, or `Liberica` are valid values. `drought_resistant` uses `TINYINT(1)` which acts as a boolean: `1` = yes, `0` = no.

### FarmVarieties
```sql
CREATE TABLE FarmVarieties (
    Farm_id       INT UNSIGNED    NOT NULL,
    variety_id    INT UNSIGNED    NOT NULL,
    trees_count   INT UNSIGNED    NOT NULL DEFAULT 0,
    planting_date DATE            NULL,
    PRIMARY KEY (Farm_id, variety_id),
    CONSTRAINT fk_farmvar_farm    FOREIGN KEY (Farm_id)    REFERENCES Farms(Farm_id)           ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_farmvar_variety FOREIGN KEY (variety_id) REFERENCES CoffeeVarieties(variety_id) ON UPDATE CASCADE
);
```
This is an **associative entity** (also called a junction table). It solves a **many-to-many** relationship: one farm can grow multiple coffee varieties, and the same variety can be grown on multiple farms. Without this table you could not represent that.

The **primary key is composite** — `PRIMARY KEY (Farm_id, variety_id)` — meaning the combination of both columns must be unique. You cannot add the same variety to the same farm twice, but the same variety can appear on many different farms.

`ON DELETE CASCADE` on `Farm_id` means if a farm is deleted, all its variety links are automatically removed too.

---

## 9. Tables — Audit log

### AuditLog
```sql
CREATE TABLE AuditLog (
    log_id       INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    table_name   VARCHAR(50)     NOT NULL,
    operation    ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    record_id    INT UNSIGNED    NOT NULL,
    old_value    JSON            NULL,
    new_value    JSON            NULL,
    performed_by VARCHAR(100)    NULL,
    performed_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```
This table automatically records a history of every important change in the database. It is populated by triggers (not by hand). For example, when a farmer record is updated, a trigger writes a row here recording what the data was before and after the change.

| Column | Explanation |
|---|---|
| `table_name` | Which table was changed (e.g. `'Farmers'`) |
| `operation` | What was done — INSERT, UPDATE, or DELETE |
| `record_id` | The ID of the specific row that changed |
| `old_value` | The data before the change, stored as JSON |
| `new_value` | The data after the change, stored as JSON |
| `performed_at` | Automatically set to the exact date and time of the change |

---

## 10. How the tables link together (relationships)

The diagram below shows the foreign key relationships. An arrow means "references".

```
Region
  └──< Districts
          └──< Subcounty
                  └──< Village
                          └──< Persons ─────────────────────────────┐
                                  ├──< Farmers                      │
                                  │       └──< Farms ──< FarmVisits │
                                  │       │       └──< FarmVarieties│
                                  │       │       └──< ProductionRecords
                                  │       │       └──< Distributions│
                                  │       └──< SupportRequest       │
                                  ├──< ExtensionWorkers ────────────┘
                                  │       └──< FarmVisits
                                  │       └──< ProductionRecords
                                  ├──< MinistryStaff
                                  │       └──< SupportRequest
                                  │       └──< Distributions
                                  └──< SystemAdmin

CoffeeVarieties ──< FarmVarieties (joins to Farms)
CoffeeVarieties ──< ProductionRecords
```

In plain words:
- A **Region** has many **Districts**. A district is in one region.
- A **District** has many **Subcounties**. A subcounty is in one district.
- A **Subcounty** has many **Villages**. A village is in one subcounty.
- A **Person** lives in one village. A village has many persons.
- A **Farmer** is a person. One farmer can own many farms.
- A **Farm** belongs to one farmer and is located in one village.
- A **Farm** can grow many coffee **varieties** (via FarmVarieties).
- An **ExtensionWorker** is a person, assigned to one district.
- A **FarmVisit** involves one extension worker, one farmer, and one farm.
- A **ProductionRecord** belongs to one farm and was recorded by one extension worker.
- A **Distribution** sends one product to one farmer's farm, handled by one staff member.

---

## 11. ALTER TABLE — adding extra columns

After the tables are created, extra columns are added with `ALTER TABLE`. This is done separately because some columns reference tables that are created later in the script (e.g. `CoffeeVarieties` must exist before `ProductionRecords` can reference it).

```sql
ALTER TABLE Persons
    ADD COLUMN first_name    VARCHAR(60)  NULL AFTER Name,
    ADD COLUMN last_name     VARCHAR(60)  NULL AFTER first_name,
    ADD COLUMN date_of_birth DATE         NULL AFTER last_name,
    ADD COLUMN district_id   INT UNSIGNED NULL AFTER Village_ID,
    ADD COLUMN person_type   ENUM('Farmer','ExtensionWorker','MinistryStaff','SystemAdmin') NULL,
    ADD COLUMN created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD CONSTRAINT fk_person_district FOREIGN KEY (district_id) REFERENCES Districts(District_ID);
```

`ON UPDATE CURRENT_TIMESTAMP` on `updated_at` means MySQL automatically updates that column to the current time every time that row is modified — you never have to do it manually.

A summary of all columns added:

| Table | Extra columns added |
|---|---|
| Persons | `first_name`, `last_name`, `date_of_birth`, `district_id` FK, `person_type` discriminator, `created_at`, `updated_at` |
| Farmers | `is_coop_member` (boolean), `cooperative_name`, `total_trees` |
| ExtensionWorkers | `employee_id` (unique staff number), `specialization`, `is_active` |
| Farms | `district_id` FK, `sub_county` text, `village` text, `registration_date`, `is_active`, `gps_latitude`, `gps_longitude` |
| FarmVisits | `recommendations` |
| ProductionRecords | `variety_id` FK, `season_year`, `season_period`, `quantity_kg`, `quality_grade`, `recorded_by` FK, `notes` |
| Products | `unit_of_measure`, `unit_cost_ugx`, `description` |
| Distributions | `worker_id` FK (assisting extension worker), `quantity`, `notes` |

---

## 12. Triggers — automatic actions

A trigger is code that MySQL runs automatically when a specific event happens on a table. You never call a trigger manually — it fires on its own.

The file uses `DELIMITER $$` before triggers and `DELIMITER ;` after. This is because trigger bodies contain semicolons inside them, and MySQL needs to know the outer boundary of the whole trigger is `$$`, not `;`.

### trg_after_distribution
```sql
CREATE TRIGGER trg_after_distribution
AFTER INSERT ON Distributions
FOR EACH ROW
BEGIN
    UPDATE Products
    SET Quantity = Quantity - NEW.quantity
    WHERE Product_id = NEW.Product_ID;
END$$
```
**When:** After every new row is inserted into `Distributions`.
**What it does:** Reduces the stock count of the distributed product by the distributed quantity. `NEW.quantity` refers to the `quantity` column of the row that was just inserted.

### trg_before_distribution
```sql
CREATE TRIGGER trg_before_distribution
BEFORE INSERT ON Distributions
FOR EACH ROW
BEGIN
    DECLARE v_stock INT UNSIGNED;
    SELECT Quantity INTO v_stock FROM Products WHERE Product_id = NEW.Product_ID;
    IF v_stock < 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot distribute: product out of stock.';
    END IF;
END$$
```
**When:** Before every new row is inserted into `Distributions`.
**What it does:** Checks the stock level first. If stock is zero, it raises an error using `SIGNAL SQLSTATE '45000'` and the insert is cancelled. This is a safeguard — the `AFTER` trigger above can never bring stock below zero because this `BEFORE` trigger blocks the insert if there is nothing left.

### trg_before_farmer_delete
```sql
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
```
**When:** Before a row is deleted from `Farmers`.
**What it does:** Counts how many farms the farmer owns. If they still own at least one, the delete is blocked with an error. `OLD.Farmer_id` refers to the ID of the farmer being deleted.

### trg_farmer_reg_number
```sql
CREATE TRIGGER trg_farmer_reg_number
BEFORE INSERT ON Farmers
FOR EACH ROW
BEGIN
    IF NEW.Registration_number IS NULL OR NEW.Registration_number = '' THEN
        SET NEW.Registration_number =
            CONCAT('FRM-', YEAR(CURDATE()), '-', LPAD(NEW.Farmer_id + 1, 4, '0'));
    END IF;
END$$
```
**When:** Before a new row is inserted into `Farmers`.
**What it does:** If no registration number is provided, it auto-generates one in the format `FRM-2024-0001`. `LPAD` pads the number with leading zeros so it is always 4 digits.

---

## 13. Sample data

The INSERT statements load test data so you can immediately run queries and see results. They must follow the **foreign key dependency order** — you cannot insert a farmer before inserting the person they are linked to.

The order is:
1. Region → Districts → Subcounty → Village (geography first)
2. Persons
3. MinistryStaff, SystemAdmin (overlapping subtypes)
4. ExtensionWorkers, Farmers (disjoint subtypes)
5. SupportRequest
6. Farms
7. CoffeeVarieties → FarmVarieties
8. FarmVisits
9. Products → Distributions
10. ProductionRecords

The sample data includes 9 persons: 5 farmers (Person IDs 1–5), 2 extension workers (IDs 6–7), and 2 ministry staff (IDs 8–9). Person 9 is both a MinistryStaff member and a SystemAdmin, demonstrating the overlapping rule.

---

## 14. Views — saved queries

A view is a stored SELECT query that you can use like a table. It does not store data itself — it runs the underlying query every time you access it. Views hide complexity and let users query without writing long JOINs.

### vw_PersonProfile
Returns a person's full profile including their village, subcounty, district, and region — all four levels of the geographic chain joined together.

### vw_FarmerProfile
Builds on `vw_PersonProfile` to add farmer-specific columns: `Farmer_id`, `Registration_number`, and `Registration_date`. Useful for looking up any farmer with their complete details in one query.

### vw_FarmSummary
Shows each farm with its farmer's name and registration number, plus the full location chain. Good for a summary report of all farms and who owns them.

### vw_ProductionHistory
Joins `ProductionRecords` with the farm, farmer, and extension worker who recorded it. Shows the full production history with names instead of IDs.

### vw_DistributionLog
Shows every distribution with the product name, farmer name, farm, district, and the ministry staff member who handled it. Uses `Products.Quantity AS Stock_After` to show the current stock level at the time of the query.

### vw_VisitHistory
Shows all farm visits with the worker's name, qualification, farmer's name, farm details, and district. Good for a field activity report.

---

## 15. Stored procedures — reusable tasks

A stored procedure is a named block of SQL code saved in the database. You call it with `CALL procedure_name(...)`. Procedures can accept input parameters and return output parameters, and they can run multiple statements in sequence.

### sp_RegisterFarmer
```sql
CALL sp_RegisterFarmer('James Okello', 'CM900001234A', 'Male', '0701234567',
                        'james@mail.com', 'Nakawa', 1, 'FRM-2020-0001', @new_id);
```
Creates both a `Persons` row and a `Farmers` row in a single call. First checks whether the National ID is already registered — if it is, it raises an error and stops. Returns the new `Farmer_id` in the output parameter `@new_id`.

### sp_RecordProduction
```sql
CALL sp_RecordProduction('Season A 2024', '2024-07-15', 850.00, 1, 1, @prod_id);
```
Records a harvest for a farm. Checks the farm exists first, then inserts into `ProductionRecords`. Parameters: season name, harvest date, quantity in kg, farm ID, extension worker ID, output production ID.

### sp_DistributeProduct
```sql
CALL sp_DistributeProduct('Seedling', 1, 2, 2, 1, @dist_id);
```
Distributes a product to a farmer. Checks stock is available before inserting into `Distributions`. Note: this check overlaps with the trigger — having it in both places means the procedure will also catch it explicitly and give a clear error message.

### sp_FarmerProductionReport
```sql
CALL sp_FarmerProductionReport(1);
```
Returns all production records for a specific farmer across all their farms, ordered from newest to oldest. Takes one input: the `Farmer_id`.

### sp_DistrictProductionSummary
```sql
CALL sp_DistrictProductionSummary(1);
```
Returns an aggregated production summary grouped by season for a given district: total farmers, total farms, total kg produced, and average kg per record. Takes one input: the `District_ID`.

---

## 16. User roles and permissions

Four database users are created, each with different permission levels matching their job function.

| User | Password | What they can do |
|---|---|---|
| `g8_admin` | `Admin@G8_2024!` | Full control of everything — all tables, all procedures |
| `g8_ext_worker` | `Worker@G8_2024!` | Read all data; insert and update in `FarmVisits` and `ProductionRecords` only; call the two production procedures |
| `g8_analyst` | `Analyst@G8_2024!` | Read all data; call the two reporting procedures — cannot change anything |
| `g8_readonly` | `ReadOnly@G8_2024!` | Can only SELECT from the five views — cannot see raw tables |

`FLUSH PRIVILEGES` at the end tells MySQL to reload the permissions table so all changes take effect immediately.

---

## 17. Sample queries

Six example queries show how to use the database.

**Q1 — All farmers with total production:**
Joins `vw_FarmerProfile` with `Farms` and `ProductionRecords` to show each farm and how many kg it produced. `SUM` adds up all season records. `LEFT JOIN` on `ProductionRecords` means farms with no production yet still appear (with NULL for the total).

**Q2 — Open support requests:**
Lists requests that have not been closed yet. Uses `LEFT JOIN` on `MinistryStaff` because some requests may not yet have an assigned staff member (`assigned_to` can be NULL).

**Q3 — District production summary:**
Calls `sp_DistrictProductionSummary(1)` for district 1 (Kampala). Returns season-by-season totals.

**Q4 — Farmer production report:**
Calls `sp_FarmerProductionReport(1)` for farmer 1. Returns their full harvest history.

**Q5 — Low stock products:**
Finds products with fewer than 100 units in stock, ordered by quantity ascending (most urgent first).

**Q6 — Overlapping roles demonstration:**
Shows persons who are in either `MinistryStaff`, `SystemAdmin`, or both. Uses `LEFT JOIN` on both tables and filters to only show rows where at least one role exists.

---

## 18. Complete table reference

| Table | PK | Purpose |
|---|---|---|
| Region | region_ID | Geographic — top level |
| Districts | District_ID | Geographic — links to Region |
| Subcounty | Subcounty_ID | Geographic — links to Districts |
| Village | Village_ID | Geographic — links to Subcounty |
| Persons | Person_id | Supertype — all people |
| Farmers | Farmer_id | Subtype of Persons — coffee farmers |
| ExtensionWorkers | Worker_id | Subtype of Persons — field staff |
| MinistryStaff | StaffID | Subtype of Persons — ministry officials |
| SystemAdmin | AdminID | Subtype of Persons — database admins |
| SupportRequest | Request_ID | Requests raised by farmers |
| Farms | Farm_id | Individual coffee farms |
| FarmVisits | Visit_id | Official visits to farms |
| Products | Product_id | Stock catalogue — seeds, tools, chemicals |
| ProductionRecords | Production_id | Harvest records per farm per season |
| Distributions | Distribution_id | Product deliveries to farmers |
| CoffeeVarieties | variety_id | Reference list of coffee varieties |
| FarmVarieties | (Farm_id, variety_id) | Links farms to the varieties they grow |
| AuditLog | log_id | History log of all data changes |
