-- Cleaning Data - Fixing fat content anomalies 

UPDATE blinkit
SET fat_content =
CASE
    WHEN fat_content IN ('LF', 'low fat') THEN 'Low Fat'
    WHEN fat_content = 'reg' THEN 'Regular'
    ELSE fat_content
END;

-- ***********************************************************************************************************************************************-- 
-- Cleaning Data - Handling Null Vales

-- During initial data importing noticed many rows were truncated found out that was because item weight was null in few rows
-- Browsed the web the find a work around, simple solution was to fix the null values in csv file and then import it
-- Another solution I found was to change item weight type to text when import so even if the values are missing, mysql will import them as empty string
-- Then I used the cast function to change its data type back to float, after replacing "" with Null

UPDATE blinkit
SET
    item_weight = CASE
        WHEN item_weight IS NULL OR item_weight = '' THEN NULL
        ELSE CAST(REPLACE(item_weight, ',', '.') AS DOUBLE)
    END;
ALTER TABLE blinkit MODIFY COLUMN item_weight DOUBLE;

-- ***********************************************************************************************************************************************-- 
-- Total Sales In Millions

SELECT 
    CAST(SUM(sales) / 1000000 AS DECIMAL (10 , 2 )) AS Total_Sales_In_Millions
FROM
    blinkit;

-- ***********************************************************************************************************************************************-- 
-- Average Sales


SELECT 
    CAST(AVG(sales) AS DECIMAL (10 , 2 )) AS Average_Sales
FROM
    blinkit;

-- ***********************************************************************************************************************************************-- 
-- Number Of Items


SELECT 
    COUNT(DISTINCT item_id) AS No_Of_Items
FROM
    blinkit;

-- ***********************************************************************************************************************************************-- 
-- Average Rating


SELECT 
    CAST(AVG(rating) AS DECIMAL (10 , 2 )) AS Average_Rating
FROM
    blinkit;

-- ***********************************************************************************************************************************************-- 
-- Total Sales, Average Sales, Number Of Items, Average Ratings Against Fat Content


SELECT 
    fat_content AS Fat_Content,
    CAST(SUM(sales) AS DECIMAL (10 , 2 )) AS Total_Sales,
    CAST(AVG(sales) AS DECIMAL (10 , 2 )) AS Average_Sales,
    COUNT(*) AS No_Of_Items,
    CAST(AVG(rating) AS DECIMAL (10 , 2 )) AS Average_Rating
FROM
    blinkit
GROUP BY fat_content
ORDER BY Total_Sales DESC;

-- ***********************************************************************************************************************************************-- 
-- Total Sales, Average Sales, Number Of Items, Average Ratings Against Item Type


SELECT 
    item_type AS Item_Type,
    CAST(SUM(sales) AS DECIMAL (10 , 2 )) AS Total_Sales,
    CAST(AVG(sales) AS DECIMAL (10 , 2 )) AS Average_Sales,
    COUNT(*) AS No_Of_Items,
    CAST(AVG(rating) AS DECIMAL (10 , 2 )) AS Average_Rating
FROM
    blinkit
GROUP BY item_type
ORDER BY Total_Sales DESC;

-- ***********************************************************************************************************************************************-- 
-- Total Sales Againt Outlet Location Type Pivoted Against Fat Content


SELECT
    GROUP_CONCAT(DISTINCT CONCAT(
        'ROUND(SUM(CASE WHEN fat_content = \'',
        fat_content,
        '\' THEN sales ELSE 0 END),2) AS `',
        fat_content,
        '`'
    )) 
FROM blinkit
INTO @sql;

SET @sql = CONCAT('SELECT outlet_loc_type, ', @sql, ' FROM blinkit GROUP BY outlet_loc_type');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ***********************************************************************************************************************************************-- 
-- Total Sales, Average Sales, Number Of Items, Average Ratings Against Outlet Establishment Year


SELECT 
    outlet_est_year,
    CAST(SUM(sales) AS DECIMAL (10 , 2 )) AS Total_Sales,
    CAST(AVG(sales) AS DECIMAL (10 , 2 )) AS Average_Sales,
    COUNT(*) AS No_Of_Items,
    CAST(AVG(rating) AS DECIMAL (10 , 2 )) AS Average_Rating
FROM
    blinkit
GROUP BY outlet_est_year;

-- ***********************************************************************************************************************************************-- 
-- Total Sales against Outlet Size as percentage of total


SELECT 
    outlet_size,
    CAST(SUM(sales) AS DECIMAL (10 , 2 )) AS Total_Sales,
    CAST((SUM(sales)*100/SUM(SUM(sales)) OVER()) AS DECIMAL (10 , 2 )) AS Percentage_Of_Total
FROM
    blinkit
GROUP BY outlet_size;
