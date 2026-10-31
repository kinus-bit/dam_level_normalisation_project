# Dam Levels Database Normalization (1NF → 2NF → 3NF)

This project shows, step by step, how a single messy table of dam water-level records was cleaned up and split into smaller, well-organised tables using **database normalization**.

The SQL was written for **MySQL** and all tables live in a database (schema) called `dam`.

---

## What Is Normalization?

Normalization is the process of organising a database so that:

- the same data is not stored again and again (less **redundancy**),
- data stays consistent when it is updated,
- every piece of information has one clear home.

We do it in stages called **normal forms**. Each stage builds on the one before it.

| Stage | Main idea |
|-------|-----------|
| **1NF** | Every column holds one value only, and every row is unique |
| **2NF** | Every column depends on the *whole* key, not just part of it |
| **3NF** | Columns depend on the key directly, not on other non-key columns |

---

## Starting Point

The original table was `dam.dam_levels`. It was created with a separate SQL script (see the link in the top comment of the `.sql` file). Each row held information about one dam's water level in a given year, including:

`year`, `dam_name`, `Assessment_Officer`, `Officer_Reg`, `water_level`, `dam_latitude`, `dam_longitude`

---

## Step 1: First Normal Form (1NF)

**Rules**
1. Each column holds a single (atomic) value.
2. Each record is unique.
3. Each column holds one data type.
4. No repeating groups or multiple values in one column.

**What was done**

1. **Removed the non-atomic records.** The rows for officer `V. Mokere` contained values that were not atomic, so they were deleted.
2. **Re-inserted them correctly**, with one dam per row (for example, `STEENBRAS LOWER` and `STEENBRAS UPPER` as separate rows for 2012, 2013 and 2015).
3. **Created a new table, `dam_levels_1nf`**, with a unique primary key `AssessmentId` (auto-increment).
4. **Fixed the data types** with `ALTER TABLE` (an early mistake made them all `TEXT`):

   | Column | Final type |
   |--------|-----------|
   | `AssessmentId` | `INT` (auto-increment, primary key) |
   | `year` | `INT` |
   | `dam_name` | `VARCHAR(100)` |
   | `Assessment_Officer` | `VARCHAR(100)` |
   | `Officer_Reg` | `INT` |
   | `water_level` | `DECIMAL(10,1)` |
   | `dam_latitude` | `DECIMAL(10,6)` |
   | `dam_longitude` | `DECIMAL(10,6)` |

5. **Copied the data** from `dam_levels` into `dam_levels_1nf` using `CAST` to convert values to the right types.
6. **Dropped the old `dam_levels` table.**

**Result:** `dam_levels_1nf` — one row per assessment, atomic values, unique primary key.

---

## Step 2: Second Normal Form (2NF)

**Rules**
1. The table must already be in 1NF.
2. Every non-key column must depend on the *entire* primary key.
3. Remove partial dependencies.
4. Move columns that depend on only part of the key into their own tables.

**The problem:** Dam details (`dam_name`, `dam_latitude`, `dam_longitude`) describe the *dam*, not the individual assessment. They were repeated every time a dam was assessed.

**What was done**

The 1NF table was split into three tables:

| New table | Purpose | Columns |
|-----------|---------|---------|
| `assessments` | Details of each assessment | `AssessmentId` (PK), `year`, `Assessment_Officer`, `Officer_Reg`, `water_level` |
| `dams` | One row per dam | `dam_name`, `dam_latitude`, `dam_longitude` |
| `dam_assessments` | **Junction table** linking assessments to dams | `AssessmentId`, `dam_name` |

The `dam_assessments` table was filled manually so each assessment (1–18) points to the correct dam, for example:

- Assessment 1 → `WEMMERSHOEK`
- Assessment 2 → `VOËLVLEI`
- Assessment 5 → `STEENBRAS LOWER`
- Assessment 6 → `STEENBRAS UPPER`

After the data was copied across, `dam_levels_1nf` was dropped.

**Result:** Dam location data is stored once per dam instead of once per assessment.

---

## Step 3: Third Normal Form (3NF)

**Rules**
1. The table must already be in 2NF.
2. Every non-key column must depend directly on the primary key.
3. Remove transitive dependencies (a non-key column depending on another non-key column).
4. Move such columns into separate tables.

**The problem:** In `assessments`, the officer's name (`Assessment_Officer`) depends on `Officer_Reg` (the registration number), not directly on `AssessmentId`. That is a transitive dependency:

`AssessmentId → Officer_Reg → Assessment_Officer`

**What was done**

The `assessments` table was split into two:

| New table | Purpose | Columns |
|-----------|---------|---------|
| `water_level_assessments` | The assessment records | `AssessmentId` (PK), `year`, `Officer_Reg`, `water_level` |
| `officers` | One row per officer | `Officer_Reg` (PK), `Officer_Name` |

The old `assessments` table was then dropped.

**Result:** An officer's name is stored once, and assessments simply reference the officer by registration number.

---

## Final Database Structure

```
officers                     water_level_assessments            dam_assessments              dams
---------------              ----------------------             ----------------             ----------------
Officer_Reg (PK) <---------- Officer_Reg                        AssessmentId  -------------> dam_name
Officer_Name                 AssessmentId (PK) <--------------- dam_name      -------------> dam_latitude
                             year                                                            dam_longitude
                             water_level
```

**How the tables relate**

- One **officer** can carry out many **assessments** (`officers` → `water_level_assessments` via `Officer_Reg`).
- Each **assessment** is linked to a **dam** through the `dam_assessments` junction table (via `AssessmentId` and `dam_name`).

---

## Summary of Table Changes

| Stage | Tables created | Tables dropped |
|-------|----------------|----------------|
| **1NF** | `dam_levels_1nf` | `dam_levels` |
| **2NF** | `assessments`, `dams`, `dam_assessments` | `dam_levels_1nf` |
| **3NF** | `water_level_assessments`, `officers` | `assessments` |

**Final tables:** `officers`, `water_level_assessments`, `dams`, `dam_assessments`

---

## Notes and Possible Improvements

These are optional suggestions to make the design even stronger:

- Add a **primary key** to `dams` (for example on `dam_name`) and to `dam_assessments`.
- Add **foreign keys** so the database enforces the relationships:
  - `water_level_assessments.Officer_Reg` → `officers.Officer_Reg`
  - `dam_assessments.AssessmentId` → `water_level_assessments.AssessmentId`
  - `dam_assessments.dam_name` → `dams.dam_name`
- Since each assessment belongs to exactly one dam, `dam_name` could be stored directly in `water_level_assessments`, which would make the junction table unnecessary.

---

## How to Use

1. Run the database creation script (linked in the `.sql` file) to create the `dam` database and initial table.
2. Run the normalization SQL file from top to bottom.
3. Use `SELECT * FROM table_name;` and `DESCRIBE table_name;` to inspect any table.

## Technologies

- MySQL
- SQL (DDL and DML)