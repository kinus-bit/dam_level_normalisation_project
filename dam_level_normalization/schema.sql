/* ============================================================

                    DATABASE SETUP REFERENCE

   ------------------------------------------------------------
   INITIAL DATABASE AND TABLE CREATION
   ------------------------------------------------------------

   The database and its initial tables were created
   using the SQL script linked below.

   DATABASE CREATION SCRIPT:
   [https://drive.google.com/file/d/10XrqoOtdo7nXQQrWPfPuaTfLC6gZMwB_/view?usp=sharing]

   ------------------------------------------------------------
   NEXT STEP:
   Database normalization from:

                  1NF  →  2NF  →  3NF

   ============================================================ */

/* ============================================================

             ★★★ FIRST NORMAL FORM (1NF) ★★★

   ------------------------------------------------------------
   RULES:
   1. Each column must contain atomic (single) values.
   2. Each record must be unique.
   3. Each column must contain values of the same data type.
   4. No repeating groups or multiple values in one column.

   ============================================================ */
   
-- 1. deleting unatomic record
DELETE FROM 
    dam.dam_levels
WHERE 
    Assessment_Officer = 'V. Mokere';

-- 2.reinserting to ensure atomicity
INSERT INTO dam.dam_levels(year, dam_name, Assessment_Officer, Officer_Reg, water_level, dam_latitude, dam_longitude)
VALUES
    (2012, 'STEENBRAS LOWER', 'V. Mokere', 201124, 20.3, -34.180527, 18.866688),
    (2012, 'STEENBRAS UPPER', 'V. Mokere', 201124, 24.2, -34.166702, 18.90976),
    (2013, 'STEENBRAS LOWER', 'V. Mokere', 201124, 22.4, -34.180527, 18.866688),
    (2013, 'STEENBRAS UPPER', 'V. Mokere', 201124, 24.6, -34.166702, 18.90976),
    (2015, 'STEENBRAS LOWER', 'V. Mokere', 201124, 22.7, -34.180527, 18.866688),
    (2015, 'STEENBRAS UPPER', 'V. Mokere', 201124, 24.6, -34.16670, 18.90976);

-- 3. creating a new table with unique primary keys
CREATE TABLE dam.dam_levels_1nf(
    AssessmentId INT PRIMARY KEY,
    year TEXT,
    dam_name TEXT,
    Assessment_Officer TEXT,
    Officer_Reg TEXT,
    water_level TEXT,
    dam_latitude TEXT,
    dam_longitude TEXT  
);

-- made an error with datatypes(so I correct that)
ALTER TABLE dam.dam_levels_1nf
MODIFY AssessmentId INT AUTO_INCREMENT,
MODIFY year INT,
MODIFY dam_name VARCHAR(100),
MODIFY Assessment_Officer VARCHAR(100),
MODIFY Officer_Reg INT, 
MODIFY water_level DECIMAL(10,1),
MODIFY dam_latitude DECIMAL(10,6),
MODIFY dam_longitude DECIMAL(10,6)
;

-- 4. copying data from table dam levels to dam_levels_1nf
INSERT INTO dam_levels_1nf(
    year,
    dam_name,
    Assessment_Officer,
    Officer_Reg,
    water_level,
    dam_latitude,
    dam_longitude
)

SELECT
    CAST(year AS SIGNED),
    dam_name,
    Assessment_Officer,
    CAST(Officer_Reg AS SIGNED),
    CAST(water_level AS DECIMAL(10,1)),
    CAST(dam_latitude AS DECIMAL(10,6)),
    CAST(dam_longitude AS DECIMAL(10,6))
FROM
    dam_levels
ORDER BY year;

-- 5. dropping duplicate table
DROP TABLE dam_levels;

SELECT * FROM dam.dam_levels_1nf;
SELECT * FROM dam.dam_levels;

DESCRIBE dam.dam_levels;
DESCRIBE dam.dam_levels_1nf;

/* ============================================================

             ★★★ SECOND NORMAL FORM (2NF) ★★★

   ------------------------------------------------------------
   RULES:
   1. The table must already satisfy First Normal Form (1NF).
   2. Every non-key attribute must depend on the entire
      primary key, not just part of it.
   3. Eliminate partial functional dependencies.
   4. Separate attributes that depend on only part of a
      composite primary key into their own tables.

   ============================================================ */
-- 1. creating assessment table
CREATE TABLE assessments(
    AssessmentId INT PRIMARY KEY AUTO_INCREMENT,
    year INT,
    Assessment_Officer VARCHAR(100),
    Officer_Reg INT,
    water_level DECIMAL(10, 1)
);

-- 2. copying values from dam_levels_1nf to assessment table
INSERT INTO assessments(
    AssessmentId,
    year,
    Assessment_Officer,
    Officer_Reg,
    water_level
)
SELECT 
    AssessmentId,
    year,
    Assessment_Officer,
    Officer_Reg,
    water_level
FROM
    dam.dam_levels_1nf
ORDER BY year;

-- 3. creating dams table
CREATE TABLE dams(
    dam_name VARCHAR(100),
    dam_latitude DECIMAL(10,6),
    dam_longitude DECIMAL(10,6)
);

-- 4. copying from dam_levels_1nf to dams table
INSERT INTO dams(
    dam_name,
    dam_latitude,
    dam_longitude
)
SELECT
    dam_name,
    dam_latitude,
    dam_longitude
FROM 
    dam.dam_levels_1nf
GROUP BY dam_name, dam_latitude, dam_longitude;

-- 5.creating a junction table to connect an assessment to a dam
CREATE TABLE dam_assessments(
    AssessmentId INT,
    dam_name VARCHAR(100)
);

-- 6. inserting values into the dam_assessment table
INSERT INTO dam_assessments(
    AssessmentId,
    dam_name
)
VALUES
(1,  'WEMMERSHOEK'),
(2,  'VOËLVLEI'),
(3,  'HELY-HUTCHINSON'),
(4,  'WOODHEAD'),
(5,  'STEENBRAS LOWER'),
(6,  'STEENBRAS UPPER'),
(7,  'WEMMERSHOEK'),
(8,  'VOËLVLEI'),
(9,  'HELY-HUTCHINSON'),
(10, 'WOODHEAD'),
(11, 'STEENBRAS LOWER'),
(12, 'STEENBRAS UPPER'),
(13, 'WEMMERSHOEK'),
(14, 'VOËLVLEI'),
(15, 'HELY-HUTCHINSON'),
(16, 'WOODHEAD'),
(17, 'STEENBRAS LOWER'),
(18, 'STEENBRAS UPPER');

-- 7. dropping the redundant dam_levels_1nf
DROP TABLE dam_levels_1nf;

/* ============================================================

              ★★★ THIRD NORMAL FORM (3NF) ★★★

   ------------------------------------------------------------
   RULES:
   1. The table must already satisfy Second Normal Form (2NF).
   2. Every non-key attribute must depend directly on the
      primary key.
   3. Eliminate transitive functional dependencies.
   4. Non-key attributes must not depend on other non-key
      attributes.
   5. Move attributes with transitive dependencies into
      separate tables where necessary.

   ============================================================ */

-- 1. breaking down assessment table to break transitivity by creating water_level_assessments
CREATE TABLE water_level_assessments(
    AssessmentId INT PRIMARY KEY AUTO_INCREMENT,
    year INT,
    Officer_Reg INT,
    water_level DECIMAL(10,1)
);

-- 2. copying values from assessment table into the water_level_assessment table
INSERT INTO water_level_assessments(
    AssessmentId,
    year,
    Officer_Reg,
    water_level
)
SELECT
    AssessmentId,
    year,
    Officer_Reg,
    water_level
FROM
    assessments
ORDER BY year;

-- 3.creating officer table that will contain officer data from assessment table.
CREATE TABLE  officers(
    Officer_Reg INT PRIMARY KEY,
    Officer_Name VARCHAR(100)
);

--  4.copying data from assessment table into the officers table
INSERT INTO officers(
    Officer_Name, 
    Officer_Reg
)
SELECT
    Assessment_Officer,
    Officer_Reg
FROM
    assessments
GROUP BY Assessment_Officer, Officer_Reg;

-- deleting assessment table
DROP TABLE assessments;

/* ============================================================

   ************************************************************

                 NORMALIZATION COMPLETED!

                  1NF  --->  2NF  --->  3NF

             DATABASE SUCCESSFULLY NORMALIZED

   ************************************************************

   ACHIEVEMENTS:
   ✓ First Normal Form (1NF) completed.
   ✓ Second Normal Form (2NF) completed.
   ✓ Third Normal Form (3NF) completed.

   RESULT:
   Database structure is now normalized up to 3NF.
   Redundancy and unnecessary data dependencies
   have been minimized.

   ============================================================ */