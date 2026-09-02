-- Data Cleaning Procedures --
-- 1. Removing of duplicated data --
-- 2. Standardization of data --
-- 3. Look for NULL values or blank values --
-- 4. Remove Columns that are not neccessary in the analysis --


SELECT * FROM  layoffs;

-- Create a copy of original data for data manipualtion--
CREATE TABLE layoffs_staging
LIKE layoffs
-- or just right clicked the original table and Navigate to Script Table -- 
-- as > CREATE To > New Query Editor Window Change the name of the table --
-- in the generated script --

SELECT * FROM layoffs_staging;

-- Insert the data from the original table to the copy table --
INSERT INTO layoffs_staging
SELECT * FROM layoffs;

-- Show the number of rows --
SELECT *,
ROW_NUMBER() OVER(
	PARTITION BY 
		CAST(company AS VARCHAR(255)),
		CAST(industry AS VARCHAR(255)), 
		CAST([location] AS VARCHAR(255)),
		CAST(total_laid_off AS VARCHAR(255)), 
		CAST(percentage_laid_off AS VARCHAR(255)), 
		CAST([date] AS VARCHAR(255)),
		CAST(stage AS VARCHAR(255)),
		CAST(country AS VARCHAR(255)),
		CAST(funds_raised_millions AS VARCHAR(255))
	ORDER BY (SELECT 1)
) AS row_number
FROM layoffs_staging;


-- Duplicate checking --
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
	PARTITION BY 
		CAST(company AS VARCHAR(255)),
		CAST(industry AS VARCHAR(255)), 
		CAST([location] AS VARCHAR(255)),
		CAST(total_laid_off AS VARCHAR(255)), 
		CAST(percentage_laid_off AS VARCHAR(255)), 
		CAST([date] AS VARCHAR(255)),
		CAST(stage AS VARCHAR(255)),
		CAST(country AS VARCHAR(255)),
		CAST(funds_raised_millions AS VARCHAR(255))
	ORDER BY (SELECT 1)
) AS row_number
FROM layoffs_staging
) 
SELECT * FROM duplicate_cte
WHERE row_number > 1;


-- Deletes the duplicate data -- 
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
	PARTITION BY 
		CAST(company AS VARCHAR(255)),
		CAST(industry AS VARCHAR(255)), 
		CAST([location] AS VARCHAR(255)),
		CAST(total_laid_off AS VARCHAR(255)), 
		CAST(percentage_laid_off AS VARCHAR(255)), 
		CAST([date] AS VARCHAR(255)),
		CAST(stage AS VARCHAR(255)),
		CAST(country AS VARCHAR(255)),
		CAST(funds_raised_millions AS VARCHAR(255))
	ORDER BY (SELECT 1)
) AS row_number
FROM layoffs_staging
) 
DELETE FROM duplicate_cte
WHERE row_number > 1;

--- Standardizing of Data --

-- Removes unneccessary spaces at the start and end of the data -- 
SELECT company, TRIM(company)
FROM layoffs_staging;

-- Update the company column to standarad data --
UPDATE layoffs_staging
SET company = TRIM(company)

-- Upon checking industry column we see some data are inconsistent, we need --
-- to fix that data to prevent unreliable information from the data--
-- Ex. industry column have Crypto, Crypto Currency, CryptoCurrency, that three data are just the same --
SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1;

SELECT *
FROM layoffs_staging
WHERE industry LIKE 'Crypto%'

-- Update all to Crypto --
UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'

-- Checking other columns if there are issues in the data --
SELECT DISTINCT [location]
FROM layoffs_staging
ORDER BY 1;

-- One of the data has unneccessary dot, must be standardized --
SELECT DISTINCT country
FROM layoffs_staging
ORDER BY 1;

-- Removes the dot at the end of the data --
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging
ORDER BY 1;

-- Updating the data by removing the dot --
UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'

-- converting text data type to date data type --
SELECT * FROM layoffs_staging

SELECT [date] 
FROM layoffs_staging
WHERE TRY_CONVERT(DATE, CAST([date] AS VARCHAR(50))) IS NULL 
  AND [date] IS NOT NULL;

-- 1. Create the new column with the proper DATE type
ALTER TABLE layoffs_staging 
ADD new_date_column DATE;
GO

-- 2. Populate it using the CAST string fix
UPDATE layoffs_staging
SET new_date_column = TRY_CONVERT(DATE, CAST([date] AS VARCHAR(50)));
GO

-- 3. Drop the old restrictive TEXT column
ALTER TABLE layoffs_staging 
DROP COLUMN [date];
GO

-- 4. Rename the new column back to its original name [date]
EXEC sp_rename 'layoffs_staging.new_date_column', 'date', 'COLUMN';
GO

SELECT * FROM layoffs_staging


-- Dealing Null values -- 
-- We can see that the result of this query is not useful for the analysis since --
-- our goal is to see numbers regarding to lay offs--
SELECT * FROM layoffs_staging
WHERE total_laid_off  IS NULL
AND
percentage_laid_off IS NULL;

SELECT * FROM layoffs_staging
WHERE total_laid_off  IS NULL
AND
percentage_laid_off IS NULL;

-- We can see from this query that there are NULL values -- 
SELECT DISTINCT industry
FROM layoffs_staging;

SELECT * FROM layoffs_staging
WHERE industry IS NULL
OR industry = '';

-- We can see from this query what data we can populate the Null or missing value of a column --
SELECT t1.industry, t2.industry
FROM layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- This query updates the NULL columns --
UPDATE t1
SET t1.industry = t2.industry
FROM layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- This query shows the populated column with the desired data --
SELECT * FROM layoffs_staging
WHERE company = 'Airbnb';

-- We can see that the result of this query is not useful for the analysis since --
-- our goal is to see numbers regarding to lay offs--
SELECT * FROM layoffs_staging
WHERE total_laid_off  IS NULL
AND
percentage_laid_off IS NULL;

-- Deleting the data of the previous query because it doesnt give significance --
-- to our analysis and might cause misinformation t our analysis --
DELETE FROM layoffs_staging
WHERE total_laid_off IS NULL
AND 
percentage_laid_off IS NULL;

-- Dropping a column that is not useful to our data analysis --
ALTER TABLE layoffs_staging
DROP COLUMN [row_number];

SELECT * FROM layoffs_staging
-- End of data cleaning --