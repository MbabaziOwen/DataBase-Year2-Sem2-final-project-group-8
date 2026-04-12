# Group 8 — Coffee Growers Management System
# Complete Project Feedback & Review Notes

This document records every review finding, correction, improvement, and explanation made to `agricultural_services_db.sql` across the full development session. It is organised by the order things were discovered and fixed.

---

## Table of Contents

1. [File comparison — choosing the right base](#1-file-comparison--choosing-the-right-base)
2. [EERD alignment check — what matched and what did not](#2-eerd-alignment-check--what-matched-and-what-did-not)
3. [Table and column naming corrections](#3-table-and-column-naming-corrections)
4. [Missing EERD tables added](#4-missing-eerd-tables-added)
5. [Missing columns added per table](#5-missing-columns-added-per-table)
6. [Code size reduction — what was removed and why](#6-code-size-reduction--what-was-removed-and-why)
7. [Bug fixes — errors found when running the script](#7-bug-fixes--errors-found-when-running-the-script)
8. [Milestone 3 — Data validation gaps and fixes](#8-milestone-3--data-validation-gaps-and-fixes)
9. [Milestone 4 — Security, automation, and backup gaps and fixes](#9-milestone-4--security-automation-and-backup-gaps-and-fixes)
10. [Final object count](#10-final-object-count)
11. [Key lessons summary](#11-key-lessons-summary)

---

## 1. File comparison — choosing the right base

Two SQL files were reviewed at the start:

| File | Tables | Style | Verdict |
|---|---|---|---|
| `agricultural_services_db.sql` (original) | 8 tables, simple | Plain, readable, consistent naming | Better starting point |
| `Group8_EERD_SQL.sql` (downloaded) | 15 tables, complex | Verbose long names, FK chains | Over-engineered |

**Why the simpler file was better:**
- Fewer tables meant fewer places where mistakes could hide
- Naming was consistent (short, clear column names)
- Easier to understand and extend
- The extra tables in the complex file (`Region`, `Subcounty`, `Village`, `MinistryStaff`, `SystemAdmin`, `SupportRequest`) were not actually in the real EERD

**Decision:** Use the simpler file as the base and bring it up to EERD standard, rather than trying to simplify the complex one.

---

## 2. EERD alignment check — what matched and what did not

After comparing the SQL against the actual EERD PDF, the following gaps were found:

### Tables in EERD that were MISSING from the SQL

| Missing Table | Purpose |
|---|---|
| `CoffeeVarieties` | Reference catalogue of coffee variety types |
| `FarmVarieties` | Associative entity linking Farms ↔ CoffeeVarieties (M:N) |
| `AuditLog` | Automatic history log of all data changes |

### Tables in the SQL that are NOT in the EERD

These were kept because they add system value, but they are acknowledged as extras beyond the EERD:

| Extra Table | Reason kept |
|---|---|
| `Region` | Supports the geographic hierarchy |
| `Subcounty` | Supports the geographic hierarchy |
| `Village` | Supports the geographic hierarchy |
| `MinistryStaff` | Needed for `Distributions` and `SupportRequest` workflow |
| `SystemAdmin` | Needed to represent overlapping subtypes |
| `SupportRequest` | Operational need — farmers raise requests |

### EERD relationship that was incorrectly implemented

**Distribution table — wrong FK:**
The original code used `Worker_ID → ExtensionWorkers` on the `Distributions` table. The EERD clearly shows that Ministry Staff (not extension workers) handle distributions. The FK was corrected to `Staff_ID → MinistryStaff`.

### ISA hierarchy — disjoint rule missing

The EERD shows Farmers and ExtensionWorkers as a **disjoint** specialisation of Persons — one person cannot be both. This was not enforced. Fix: added `UNIQUE (Person_id)` on both `Farmers` and `ExtensionWorkers`. If someone is already a farmer, the database now prevents them from also being registered as an extension worker.

---

## 3. Table and column naming corrections

### Tables renamed from singular to plural (to match EERD)

| Before | After |
|---|---|
| `Farmer` | `Farmers` |
| `ExtensionWorker` | `ExtensionWorkers` |
| `Farm` | `Farms` |
| `FarmVisit` | `FarmVisits` |
| `Product` | `Products` |
| `ProductionRecord` | `ProductionRecords` |
| `Distribution` | `Distributions` |
| `District` | `Districts` |

**Important:** Word-boundary regex (`\bFarmer\b`) was used for all renames to avoid corrupting column names. For example, `Farmer_id` (a column name) was correctly left unchanged because the underscore `_` is a word character — the boundary only matched the standalone table name `Farmer`.

### Column names that were standardised

| Table | Old name | New name | Reason |
|---|---|---|---|
| `Farms` | `Farm_id` (FK) | `Farmer_id` | Matches the PK it references |
| `FarmVisits` | `Farm_ID` | `Farm_id` | Consistent casing |
| `ProductionRecords` | `Farm_varietyID` | `Farm_id` | Was referencing a non-EERD table |

---

## 4. Missing EERD tables added

### CoffeeVarieties

```
variety_id PK | variety_name AK | variety_type ENUM | maturity_months
avg_yield_kg_tree | drought_resistant (boolean) | description
```

- `variety_type` uses `ENUM('Arabica','Robusta','Liberica')` — only valid coffee species are accepted
- `drought_resistant` uses `TINYINT(1)` acting as a boolean (1 = yes, 0 = no)
- `UNIQUE` on `variety_name` prevents duplicate variety entries

### FarmVarieties (associative entity)

```
Farm_id PK/FK | variety_id PK/FK | trees_count | planting_date
```

- **Composite primary key** `(Farm_id, variety_id)` — the pair must be unique, so the same variety cannot be added to the same farm twice
- Solves the many-to-many relationship: one farm can grow multiple varieties; one variety can be grown on many farms
- `ON DELETE CASCADE` on `Farm_id` — if a farm is deleted, its variety links are automatically cleaned up

### AuditLog

```
log_id PK | table_name | operation ENUM | record_id
old_value JSON | new_value JSON | performed_by | performed_at
```

- `operation` is `ENUM('INSERT','UPDATE','DELETE')` — only valid operations accepted
- `old_value` and `new_value` are `JSON` type — stores full row snapshot before and after a change
- `performed_at` defaults to `CURRENT_TIMESTAMP` — automatically records the exact time
- This table is populated entirely by triggers (see Section 9) — nothing is inserted manually

---

## 5. Missing columns added per table

These were all added via `ALTER TABLE` statements placed **before** the triggers section (see Section 7 for why order matters).

### Persons
| Column | Type | Purpose |
|---|---|---|
| `first_name` | VARCHAR(60) NULL | Separate first name field |
| `last_name` | VARCHAR(60) NULL | Separate last name field |
| `date_of_birth` | DATE NULL | Age verification capability |
| `district_id` | INT UNSIGNED NULL FK | Direct district link for the person |
| `person_type` | ENUM discriminator | Tags which subtype(s) a person belongs to |
| `created_at` | DATETIME DEFAULT NOW | Auto-records when row was created |
| `updated_at` | DATETIME ON UPDATE NOW | Auto-updates whenever the row is modified |

### Farmers
| Column | Type | Purpose |
|---|---|---|
| `is_coop_member` | TINYINT(1) DEFAULT 0 | Whether they belong to a cooperative |
| `cooperative_name` | VARCHAR(150) NULL | Name of cooperative if member |
| `total_trees` | INT UNSIGNED DEFAULT 0 | Total coffee trees owned |

### ExtensionWorkers
| Column | Type | Purpose |
|---|---|---|
| `employee_id` | VARCHAR(30) NULL UNIQUE | Government staff number (alternate key) |
| `specialization` | VARCHAR(100) NULL | Area of expertise |
| `is_active` | TINYINT(1) DEFAULT 1 | Quick active/inactive flag |

### Farms
| Column | Type | Purpose |
|---|---|---|
| `district_id` | INT UNSIGNED NULL FK | Direct district reference |
| `sub_county` | VARCHAR(100) NULL | Text sub-county for quick reference |
| `village` | VARCHAR(100) NULL | Text village for quick reference |
| `registration_date` | DATE NULL | When the farm was formally registered |
| `is_active` | TINYINT(1) DEFAULT 1 | Whether farm is currently operational |
| `gps_latitude` | DECIMAL(9,6) NULL | GPS coordinate |
| `gps_longitude` | DECIMAL(9,6) NULL | GPS coordinate |

### FarmVisits
| Column | Purpose |
|---|---|
| `recommendations` TEXT NULL | What the extension worker recommended after the visit |

### ProductionRecords
| Column | Type | Purpose |
|---|---|---|
| `variety_id` | INT UNSIGNED NULL FK | Which coffee variety was harvested |
| `season_year` | YEAR NULL | The year of the season |
| `season_period` | ENUM('A','B','C') NULL | Season A, B, or C |
| `quantity_kg` | DECIMAL(10,2) NULL | Quantity specifically in kilograms |
| `quality_grade` | ENUM('Grade A','Grade B','Grade C') | Graded quality of harvest |
| `recorded_by` | INT UNSIGNED NULL FK | Person who recorded (may differ from worker) |
| `notes` | TEXT NULL | Additional observations |

### Products
| Column | Type | Purpose |
|---|---|---|
| `unit_of_measure` | VARCHAR(30) DEFAULT 'unit' | e.g. kg, litres, pieces |
| `unit_cost_ugx` | DECIMAL(12,2) NULL | Cost in Uganda Shillings |
| `description` | TEXT NULL | Product description |

### Distributions
| Column | Type | Purpose |
|---|---|---|
| `worker_id` | INT UNSIGNED NULL FK | Extension worker who assisted (optional) |
| `quantity` | INT UNSIGNED DEFAULT 1 | How many units were distributed |
| `notes` | TEXT NULL | Additional distribution notes |

---

## 6. Code size reduction — what was removed and why

The file was reduced from **1,089 lines to 875 lines** (214 lines removed) without changing any functional SQL.

### What was removed

| Category | Lines saved | Reason removed |
|---|---|---|
| Per-table `──` bordered comment boxes (18 total) | ~150 | Each table had a 5–16 line decorative comment block explaining the EERD mapping. This information is now in `DATABASE_EXPLAINED.md` where it belongs. |
| Header `TABLE ORDER` dependency list | ~20 | The dependency order is obvious from reading the CREATE TABLE statements in sequence |
| Redundant inline comments | ~22 | Comments like `-- current stock level`, `-- enforces disjoint`, `-- MinistryStaff, NOT ExtensionWorkers` repeated what the code already clearly showed |
| `-- END OF SCRIPT` footer | 3 | Not needed |
| Triple/quadruple blank lines collapsed | ~19 | Excessive spacing between sections |

### What was kept

- All `-- ====` section headers (TRIGGERS, VIEWS, PROCEDURES, etc.)
- Comments inside trigger bodies explaining the logic
- Constraint names (these are part of the SQL structure)

---

## 7. Bug fixes — errors found when running the script

Three bugs were found when the script was executed for the first time.

---

### Bug 1 — `Unknown column 'quantity' in 'NEW'` (line 266)

**What went wrong:**
The trigger `trg_after_distribution` used `NEW.quantity`, but the `quantity` column is added to `Distributions` via `ALTER TABLE` — which was positioned *after* the TRIGGERS section. MySQL/MariaDB compiles triggers at creation time, so when the trigger was created, `quantity` did not yet exist in the table.

**Fix:**
Moved the entire `ALTER TABLE` section to *before* the `TRIGGERS` section. The new order is:
1. `CREATE TABLE` (all 18 tables)
2. `ALTER TABLE` (add missing columns)
3. `TRIGGERS` (now all columns exist when triggers are compiled)
4. Sample data, views, procedures

**Lesson:** Triggers reference table structure at the time they are created. Any column used in a trigger body must already exist in the table before the trigger is created.

---

### Bug 2 — Weak stock-check logic in `trg_before_distribution`

**What went wrong:**
The BEFORE INSERT trigger on `Distributions` checked `IF v_stock < 1` — meaning it only blocked distribution when stock was completely zero. If stock was 3 and someone tried to distribute 10 units, it would pass the check. Then the AFTER INSERT trigger would subtract 10, setting stock to −7, which would violate the `CHECK (Quantity >= 0)` constraint on `Products`.

**Fix:**
Changed the check to `IF v_stock < NEW.quantity` so it compares actual available stock against the quantity being requested.

---

### Bug 3 — `Unknown column 'fp.Name'` in Query 1

**What went wrong:**
Sample Query 1 referenced `fp.Name` where `fp` is an alias for `vw_FarmerProfile`. That view selects the name as `pp.Name AS Farmer_Name`. The column is exposed as `Farmer_Name`, not `Name`.

**Fix:**
Changed `fp.Name AS Farmers` to `fp.Farmer_Name` in Query 1.

---

## 8. Milestone 3 — Data validation gaps and fixes

### What the milestone required
> Use appropriate constraints to validate data and avoid garbage-in. The constraints should enforce operational rules. Use of relevant functions.

---

### Gaps found

**No input format validation:**
- `Phone` — `VARCHAR(20) NOT NULL` accepted empty strings and single-character values
- `Email` — `VARCHAR(120) NULL` accepted anything including `'notanemail'`
- `Name` — `VARCHAR(120) NOT NULL` accepted a single space as a valid name

**No value-range enforcement on business fields:**
- `Status` in `ExtensionWorkers` and `SystemAdmin` — plain `VARCHAR(30)`, so `'Retired'`, `'fired'`, or `'xyz'` would all pass
- `Access_level` in `SystemAdmin` — unconstrained `VARCHAR(50)`
- `Coffee_Type` in `Farms` — unconstrained `VARCHAR(50)`, accepted any string
- `gps_latitude` / `gps_longitude` — no range check (coordinates outside ±90/±180 are impossible on Earth)

**No financial/count validation:**
- `unit_cost_ugx` — negative prices were accepted
- `avg_yield_kg_tree` — negative or zero yield was accepted
- `maturity_months` — could be 0 or 999
- `trees_count` in `FarmVarieties` — `DEFAULT 0` allowed recording a variety with no trees
- `quantity` in `Distributions` — no `> 0` check (could distribute 0 units)

**No date logic enforcement:**
- `Hire_date` in `ExtensionWorkers` and `MinistryStaff` — a future date was accepted
- `Visit_date` in `FarmVisits` — could record a visit that hasn't happened yet
- `Record_date` in `ProductionRecords` — could record a future harvest
- `Registration_date` in `Farmers` — could register a farmer with a future date

**`Distributions.worker_id` declared wrong:**
- Was `NOT NULL DEFAULT 1` — should be nullable since the assisting extension worker is optional. The default value of `1` silently assigned every distribution to Worker ID 1, which is incorrect.

**Functions missing:**
The file used `CURDATE()`, `YEAR()`, `CONCAT()`, `LPAD()`, `COUNT()`, `SUM()`, `AVG()`, and `LAST_INSERT_ID()` but had no use of: `COALESCE()`, `DATEDIFF()`, `DATE_FORMAT()`, `IF()`, or `UPPER()`.

---

### Fixes applied

**CHECK constraints added:**

| Table | Constraint | Rule |
|---|---|---|
| `Persons` | `chk_name_len` | `LENGTH(TRIM(Name)) >= 2` |
| `Persons` | `chk_phone_len` | `LENGTH(TRIM(Phone)) >= 10` |
| `Persons` | `chk_email_fmt` | `Email IS NULL OR (Email LIKE '%@%.%' AND LENGTH(Email) >= 6)` |
| `Farms` | `chk_coffee_type` | `Coffee_Type IN ('Arabica','Robusta','Liberica','Hybrid')` |
| `Farms` | `chk_size_max` | `Size_acres <= 5000` |
| `Farms` | `chk_gps_lat` | `gps_latitude BETWEEN -90 AND 90` |
| `Farms` | `chk_gps_lon` | `gps_longitude BETWEEN -180 AND 180` |
| `FarmVarieties` | `chk_trees_pos` | `trees_count > 0` |
| `CoffeeVarieties` | `chk_var_maturity` | `maturity_months BETWEEN 1 AND 60` |
| `CoffeeVarieties` | `chk_var_yield` | `avg_yield_kg_tree > 0` |
| `Products` | `chk_prod_cost` | `unit_cost_ugx > 0` (when provided) |
| `Distributions` | `chk_dist_qty` | `quantity > 0` |

**ENUM replacements (replacing unconstrained VARCHAR):**

| Table | Column | ENUM values |
|---|---|---|
| `ExtensionWorkers` | `Status` | `'Active','Inactive','On Leave','Suspended'` |
| `SystemAdmin` | `Status` | `'Active','Inactive','Suspended'` |
| `SystemAdmin` | `Access_level` | `'Administrator','Supervisor','Operator'` |

**Note on `CURDATE()` in CHECK constraints:**
`CURDATE()` is a non-deterministic function and is NOT allowed inside `CHECK` constraints in MariaDB/MySQL. Therefore, date-not-in-future rules cannot be CHECK constraints — they must be enforced using `BEFORE INSERT` triggers instead.

**Date validation triggers added:**

| Trigger | Table | Rule enforced |
|---|---|---|
| `trg_farmer_reg_number` (extended) | `Farmers` | `Registration_date <= CURDATE()` |
| `trg_before_extworker_insert` | `ExtensionWorkers` | `Hire_date <= CURDATE()` |
| `trg_before_staff_insert` | `MinistryStaff` | `Hire_date <= CURDATE()` |
| `trg_before_visit_insert` | `FarmVisits` | `Visit_date <= CURDATE()` |
| `trg_before_production_insert` | `ProductionRecords` | `Record_date <= CURDATE()` |

**New functions demonstrated — `vw_FarmActivitySummary`:**

| Function | Used for |
|---|---|
| `COALESCE(SUM(pr.Quantity), 0)` | Returns `0` instead of `NULL` for farms with no harvests |
| `DATEDIFF(CURDATE(), MAX(pr.Record_date))` | Days elapsed since last harvest |
| `DATE_FORMAT(MAX(pr.Record_date), '%d %b %Y')` | Human-readable date e.g. `20 Dec 2022` |
| `IF(f.is_active = 1, 'Active', 'Inactive')` | Readable farm status |
| `UPPER(f.Coffee_Type)` | Normalised uppercase display |

---

## 9. Milestone 4 — Security, automation, and backup gaps and fixes

### What the milestone required
> Enforce views, user authentication, privileges and roles. Allow code reuse and action automation using stored procedures and triggers. Backup and recovery features.

---

### Gaps found

**No formal MySQL/MariaDB ROLES:**
The file had four users with direct `GRANT` statements — not role-based. The milestone specifically requires roles. Additionally, `g8_ext_worker` and `g8_analyst` both had `GRANT SELECT ON *.*` which exposed the raw `Persons` table (containing National ID numbers and phone numbers) to every non-admin user.

**AuditLog table was completely empty:**
The `AuditLog` table was created and had the right structure, but zero triggers wrote to it. It would always be empty regardless of what changes were made to the database.

**`sp_DistributeProduct` had a hardcoded quantity of 1:**
The procedure inserted into `Distributions` without a `quantity` parameter, always distributing exactly 1 unit. It also checked `v_stock < 1` instead of comparing against the requested quantity.

**Missing stored procedures:**
- No `sp_RegisterExtensionWorker` — registering a new extension worker required two separate raw INSERT statements
- No `sp_RecordFarmVisit` — recording a farm visit required a raw INSERT with no validation

**Minor procedure bug:**
`sp_RecordProduction` error message said `'Farms does not exist.'` (wrong — should be `'Farm does not exist.'`).

**No password policy:**
All four user accounts were created with no expiry, no lock-out policy, and no account restrictions.

**No backup or recovery strategy at all.**

---

### Fixes applied

**Formal roles created (MariaDB 10.4 syntax):**

| Role | Who it is assigned to | What it can access |
|---|---|---|
| `role_db_admin` | `g8_admin` | Full control — ALL PRIVILEGES with GRANT OPTION |
| `role_field_worker` | `g8_ext_worker` | SELECT on farm-operation tables only; INSERT/UPDATE on FarmVisits and ProductionRecords; three procedures |
| `role_data_analyst` | `g8_analyst` | SELECT on all 7 views only (no raw tables); two reporting procedures |
| `role_portal_viewer` | `g8_readonly` | SELECT on 6 non-sensitive views only |

**Privacy improvement:**
`role_field_worker` and `role_data_analyst` no longer have `SELECT ON *.*`. The raw `Persons` table (National_ID, Phone, Email) is inaccessible to them. They can only see the data that views intentionally expose.

**Password policies added:**

```sql
CREATE USER 'g8_admin'@'localhost'
    IDENTIFIED BY 'Admin@G8_2024!'
    PASSWORD EXPIRE INTERVAL 180 DAY;
```

Admin, worker, and analyst passwords expire every 180 days. Portal viewer password expires every 365 days.

**`SET DEFAULT ROLE ... FOR`:**
Roles activate automatically when each user logs in — no manual `SET ROLE` command is required.

> **MariaDB syntax note:** MySQL 8.0 uses `SET DEFAULT ROLE role TO user`. MariaDB 10.4 uses `SET DEFAULT ROLE role FOR user`. The server running is MariaDB 10.4.32 (not MySQL 8.0 as the file header stated). All role syntax was corrected accordingly.

**AuditLog triggers added:**

| Trigger | Event | What gets logged |
|---|---|---|
| `trg_audit_farmer_insert` | AFTER INSERT on Farmers | New farmer ID, registration number, person ID, date |
| `trg_audit_farmer_update` | AFTER UPDATE on Farmers | Old and new values of key fields side by side |
| `trg_audit_production_insert` | AFTER INSERT on ProductionRecords | Farm, season, quantity, worker, date |
| `trg_audit_dist_insert` | AFTER INSERT on Distributions | Product, farmer, quantity, staff, date |

`CURRENT_USER()` is used in all audit triggers so the log records exactly who made the change.

**`sp_DistributeProduct` fixed and `sp_RegisterExtensionWorker` + `sp_RecordFarmVisit` + `sp_BackupKeyTables` added:**

| Procedure | Key logic |
|---|---|
| `sp_DistributeProduct` (fixed) | Now accepts `p_quantity IN INT UNSIGNED`; validates `p_quantity >= 1`; checks `v_stock < p_quantity` |
| `sp_RegisterExtensionWorker` | Creates Persons + ExtensionWorkers in one transaction; validates NIN uniqueness and hire date |
| `sp_RecordFarmVisit` | Records a visit; validates farm exists, worker exists, visit date not future |
| `sp_BackupKeyTables` | Uses `DATE_FORMAT(NOW(), '%Y%m%d_%H%i')` to generate a timestamp suffix; creates `bkp_TableName_YYYYMMDD_HHMM` copies using prepared statements |

**Backup and recovery strategy documented and implemented:**

| Strategy | Implementation |
|---|---|
| **OS-level full dump** | `mysqldump` commands documented with exact syntax for backup and restore |
| **Selective table dump** | Command to back up only the 5 critical tables |
| **In-database snapshot** | `sp_BackupKeyTables()` — call any time to create timestamped table copies |
| **Scheduled maintenance** | `evt_auditlog_cleanup` — MariaDB event that runs weekly and deletes AuditLog rows older than 1 year |
| **Recovery checklist** | Step-by-step restore procedure including stopping connections and verifying row counts |

---

## 10. Final object count

| SQL object type | Count |
|---|---|
| Tables | 18 |
| Triggers | 12 |
| Stored procedures | 8 |
| Views | 7 |
| Roles | 4 |
| User accounts | 4 |
| Scheduled events | 1 |

**Trigger breakdown:**

| # | Trigger | Type | Table |
|---|---|---|---|
| 1 | `trg_after_distribution` | AFTER INSERT | Distributions |
| 2 | `trg_before_distribution` | BEFORE INSERT | Distributions |
| 3 | `trg_before_farmer_delete` | BEFORE DELETE | Farmers |
| 4 | `trg_farmer_reg_number` | BEFORE INSERT | Farmers |
| 5 | `trg_before_extworker_insert` | BEFORE INSERT | ExtensionWorkers |
| 6 | `trg_before_staff_insert` | BEFORE INSERT | MinistryStaff |
| 7 | `trg_before_visit_insert` | BEFORE INSERT | FarmVisits |
| 8 | `trg_before_production_insert` | BEFORE INSERT | ProductionRecords |
| 9 | `trg_audit_farmer_insert` | AFTER INSERT | Farmers |
| 10 | `trg_audit_farmer_update` | AFTER UPDATE | Farmers |
| 11 | `trg_audit_production_insert` | AFTER INSERT | ProductionRecords |
| 12 | `trg_audit_dist_insert` | AFTER INSERT | Distributions |

---

## 11. Key lessons summary

These are the most important technical points that came up during the project:

**1. Trigger creation order matters.**
A trigger that references a column must be created AFTER that column exists in the table. `ALTER TABLE` statements that add columns must always come before the TRIGGERS section in a setup script.

**2. `CURDATE()` cannot go inside a `CHECK` constraint.**
MariaDB and MySQL treat `CURDATE()` as non-deterministic and reject it in CHECK constraints. Date-not-in-future rules must be implemented as `BEFORE INSERT` triggers using `SIGNAL SQLSTATE '45000'`.

**3. Word-boundary regex is essential for safe bulk renames.**
When renaming table names like `Farmer → Farmers`, using `\bFarmer\b` ensures `Farmer_id` column names are left unchanged. Without word boundaries, a simple `str.replace('Farmer', 'Farmers')` would corrupt `Farmer_id` → `Farmers_id`.

**4. Direct `GRANT SELECT ON *.*` is a privacy failure.**
Giving any non-admin user `SELECT ON database.*` exposes raw tables including personal data like National IDs, phone numbers, and email addresses. Access should always be granted through views that intentionally expose only the data each role needs.

**5. Roles must be activated with `SET DEFAULT ROLE`.**
In both MySQL 8.0 and MariaDB, assigning a role to a user with `GRANT role TO user` does not automatically activate it on login. `SET DEFAULT ROLE role FOR user` (MariaDB) or `SET DEFAULT ROLE role TO user` (MySQL 8.0) is required.

**6. MySQL 8.0 and MariaDB have different role syntax.**
The server in use was MariaDB 10.4 (not MySQL 8.0). Key differences:
- `SET DEFAULT ROLE role TO user` (MySQL) → `SET DEFAULT ROLE role FOR user` (MariaDB)
- Role names in `CREATE ROLE` and `GRANT role TO user` should not be single-quoted in MariaDB

**7. Multiple triggers per event per table are supported.**
MariaDB 10.2+ (and MySQL 5.7.2+) allow multiple triggers for the same event on the same table. This was used to have both `trg_after_distribution` (stock decrement) and `trg_audit_dist_insert` (audit log) both firing on AFTER INSERT on Distributions. Each trigger is independent.

**8. An AuditLog table does nothing without triggers.**
Creating the `AuditLog` table is only the first step. Without AFTER triggers to populate it, the table stays permanently empty. The triggers must be explicitly written to INSERT into AuditLog.

**9. Associative entities solve many-to-many relationships.**
`FarmVarieties` exists specifically because a Farm can grow many coffee Varieties, and a Variety can be grown on many Farms. A single FK on either table cannot represent this. The associative entity holds the composite PK `(Farm_id, variety_id)` and can store attributes about the relationship itself (like `trees_count` and `planting_date`).

**10. Stored procedures should validate their own inputs.**
`sp_DistributeProduct` originally checked `v_stock < 1` (always distributes 1 unit). When a quantity parameter was added, the check had to be updated to `v_stock < p_quantity`. Procedures should validate every input parameter independently of what constraints or triggers exist on the underlying tables.
