CREATE DATABASE AIRLINE;
USE AIRLINE;

CREATE TABLE `maindata` (
  `%Airline ID` int DEFAULT NULL,
  `%Carrier Group ID` int DEFAULT NULL,
  `%Unique Carrier Code` text,
  `%Unique Carrier Entity Code` int DEFAULT NULL,
  `%Region Code` text,
  `%Origin Airport ID` int DEFAULT NULL,
  `%Origin Airport Sequence ID` int DEFAULT NULL,
  `%Origin Airport Market ID` int DEFAULT NULL,
  `%Origin World Area Code` int DEFAULT NULL,
  `%Destination Airport ID` int DEFAULT NULL,
  `%Destination Airport Sequence ID` int DEFAULT NULL,
  `%Destination Airport Market ID` int DEFAULT NULL,
  `%Destination World Area Code` int DEFAULT NULL,
  `%Aircraft Group ID` int DEFAULT NULL,
  `%Aircraft Type ID` int DEFAULT NULL,
  `%Aircraft Configuration ID` int DEFAULT NULL,
  `%Distance Group ID` int DEFAULT NULL,
  `%Service Class ID` text,
  `%Datasource ID` text,
  `# Departures Scheduled` int DEFAULT NULL,
  `# Departures Performed` int DEFAULT NULL,
  `# Payload` int DEFAULT NULL,
  `Distance` int DEFAULT NULL,
  `# Available Seats` int DEFAULT NULL,
  `# Transported Passengers` int DEFAULT NULL,
  `# Transported Freight` int DEFAULT NULL,
  `# Transported Mail` int DEFAULT NULL,
  `# Ramp-To-Ramp Time` int DEFAULT NULL,
  `# Air Time` int DEFAULT NULL,
  `Unique Carrier` text,
  `Carrier Code` text,
  `Carrier Name` text,
  `Origin Airport Code` text,
  `Origin City` text,
  `Origin State Code` text,
  `Origin State FIPS` int NULL,
  `Origin State` text,
  `Origin Country Code` text,
  `Origin Country` text,
  `Destination Airport Code` text,
  `Destination City` text,
  `Destination State Code` text,
  `Destination State FIPS` int DEFAULT NULL,
  `Destination State` text,
  `Destination Country Code` text,
  `Destination Country` text,
  `Year` int DEFAULT NULL,
  `Month (#)` int DEFAULT NULL,
  `Day` int DEFAULT NULL,
  `From - To Airport Code` text,
  `From - To Airport ID` text,
  `From - To City` text,
  `From - To State Code` text,
  `From - To State` text
) ;

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/MainData_Final.csv'
INTO TABLE maindata
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER TABLE `distance groups` 
RENAME COLUMN `ï»¿%Distance Group ID` TO `%Distance Group ID`;

-- ALTER TABLE maindata DROP COLUMN Date_; --

-- ADDED COLUMNS DATE,LOAD FACTOR,MONTHNAME,QUARTER,AND DAY TYPE INTO TABLE --

ALTER TABLE maindata
ADD COLUMN Date_ DATE,
ADD COLUMN Load_factor INT;

UPDATE maindata
SET Date_ = DATE(CONCAT(Year,'-',LPAD(`Month (#)`,2,'0'),'-',LPAD(Day,2,'0'))),
Load_factor = CASE
        WHEN `# Available Seats` = 0 THEN 0
        ELSE (`# Transported Passengers` / `# Available Seats`) * 100
    END;

ALTER TABLE maindata
ADD COLUMN Month_name VARCHAR(12),
ADD COLUMN Quarter_ VARCHAR(10),
ADD COLUMN  Day_type VARCHAR(10);

UPDATE maindata 
SET 
    Month_name = MONTHNAME(Date_),
    Quarter_ = concat("Q",QUARTER(Date_)),
    Day_type = CASE
        WHEN DAYOFWEEK(Date_) IN (1 , 7) THEN 'Weekend'
        ELSE 'Weekday'
    END;
    
    -- KPI CARDS --
    CREATE OR REPLACE VIEW Cards AS 
SELECT
COUNT(`Origin Country`) AS Total_Country,
SUM(Distance)AS Total_Distance ,
CONCAT(AVG(Load_factor)," ","%") AS Average_Load_factor,
COUNT(`# Transported Passengers`)  AS Total_Passengers
FROM maindata;

SELECT * FROM Cards;

-- LOAD FACTOR PERCENTAGE ON YEARLY ,QUARTERLY AND MONTHLY BASIS --
SELECT
Year,
ROUND(SUM(Load_factor)*100/(SELECT SUM(Load_factor) FROM maindata), 2) AS Load_Factor_Percentage
FROM maindata
GROUP BY YEAR;

SELECT 
Quarter_,
ROUND(SUM(Load_factor) *100/(SELECT SUM(Load_factor) FROM maindata), 2) AS Load_Factor_Percentage
FROM maindata
GROUP BY Quarter_
ORDER BY Load_Factor_Percentage DESC;

SELECT 
Month_name,
ROUND(SUM(Load_factor)*100/(SELECT SUM(Load_factor) FROM maindata), 2) AS Load_Factor_Percentage
FROM maindata
GROUP BY Month_name
ORDER BY Load_Factor_Percentage Desc;

-- LOAD FACTOR PERCENTAGE ON CARRIER NAME BASIS --
SELECT
`Carrier Name`,
ROUND(SUM(Load_factor)*100/(SELECT SUM(Load_factor) FROM maindata), 2) AS Load_Factor_Percentage
FROM maindata
GROUP BY  `Carrier Name`
ORDER BY Load_Factor_Percentage DESC
LIMIT 5;

-- TOP 10 CARRIER NAMES BASED ON PASSENGERS PREFERENCE --
SELECT 
`Carrier Name`,
COUNT(`# Departures Performed`) AS No_of_Flights
FROM maindata
GROUP BY `Carrier Name` 
ORDER BY No_of_Flights DESC
LIMIT 10;

-- DISPLAY TOP-ROUTES (FROM-TO-CITY)BASED ON NUMBER OF FLIGHTS
SELECT 
`From - To City`,
COUNT(`# Departures Performed`) AS No_of_flights
FROM maindata
GROUP BY `From - To City`
ORDER BY No_of_flights DESC
LIMIT 5;


-- 6.LOAD FACTOR BY DAY-TYPE --
SELECT 
Day_type,
ROUND(SUM(Load_factor)*100/(SELECT SUM(Load_factor) FROM maindata), 2) AS Load_Factor_Percentage
FROM maindata
GROUP BY Day_type
ORDER BY  Load_Factor_Percentage Desc;

-- 7.NO OF FLIGHTS BASED ON DISTANCE GROUP --
SELECT
`Distance Interval`,
COUNT(`# Departures Performed`) AS No_of_flights
FROM maindata m
LEFT JOIN `distance groups`d ON m.`%Distance Group ID` = d.`%Distance Group ID`
GROUP BY `Distance Interval`
ORDER BY No_of_flights DESC;
