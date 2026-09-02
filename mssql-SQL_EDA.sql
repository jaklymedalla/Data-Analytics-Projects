-- Exploratory Data Analysis --
SELECT * FROM layoffstaging

-- This query shows the largest number of laid off of a company in a single day--
-- shows largest percent of laid off of a company where 1 represent 100% --
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging

-- This query shows the company with 100% laid off -- 
SELECT * FROM layoffs_staging
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Create a new, properly typed column --
ALTER TABLE layoffs_staging 
ADD funds_clean DECIMAL(18,2);
GO
-- Convert text -> varchar -> decimal safely --
UPDATE layoffs_staging
SET funds_clean = TRY_CONVERT(DECIMAL(18,2), CAST(funds_raised_millions AS VARCHAR(MAX)));
GO
-- Drop the old restrictive text column --
ALTER TABLE layoffs_staging 
DROP COLUMN funds_raised_millions;
GO
-- Rename your new clean column back to the original name --
EXEC sp_rename 'layoffs_staging.funds_clean', 'funds_raised_millions', 'COLUMN';
GO

-- This query shows the number of funds of a company that have 100% laid off --
SELECT * FROM layoffs_staging
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;


-- Shows the total laid off of a company --
SELECT company, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY company
ORDER BY 2 DESC;

-- Shows the percentage of laid off of a company --
SELECT company, AVG(percentage_laid_off)
FROM layoffs_staging
GROUP BY company
ORDER BY 2 DESC

-- We can see the starting date of the laiding off of the companies -- 
SELECT MIN([date]), MAX([date])
FROM layoffs_staging

-- Shows the total laid off of an industry --
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY industry
ORDER BY 2 DESC;

-- Shows the total laid off of a country --
SELECT country, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY country
ORDER BY 2 DESC;

-- Shows the total of laid off by year --
SELECT YEAR([date]), SUM(total_laid_off)
FROM layoffs_staging
GROUP BY YEAR([date])
ORDER BY 1 DESC;

-- Shows the stages of company regarding to laid off data --
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY stage
ORDER BY 1 DESC;

-- Shows the total of laid off by month --
SELECT 
    FORMAT([date], 'yyyy-MM') AS [MONTH],
    SUM(total_laid_off) AS Total_Laid_Off
FROM 
    layoffs_staging
WHERE 
    [date] IS NOT NULL
GROUP BY 
    FORMAT([date], 'yyyy-MM')
ORDER BY 
    1 ASC;

-- Adds the rolling total of the laid off data by date upward--
WITH Rolling_Total AS
(
SELECT 
    FORMAT([date], 'yyyy-MM') AS [MONTH],
    SUM(total_laid_off) AS Total_Laid_Off
FROM 
    layoffs_staging
WHERE 
    [date] IS NOT NULL
GROUP BY 
    FORMAT([date], 'yyyy-MM')
)
SELECT 
    [MONTH], 
    Total_Laid_Off,
    -- Explicitly specifying ROWS UNBOUNDED PRECEDING fixes the byte error
    SUM(Total_Laid_Off) OVER(ORDER BY [MONTH] ROWS UNBOUNDED PRECEDING) AS rolling_total
FROM 
    Rolling_Total
ORDER BY 
    [MONTH] ASC;

-- Shows the total laid of a company by year --
SELECT company, YEAR([date]), SUM(total_laid_off)
FROM layoffs_staging
GROUP BY company, YEAR([date])
ORDER BY 3 DESC;

-- Shows the top laiding off company by year and ranking them --
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT 
    company, 
    YEAR([date]), -- Replaced backticks with square brackets
    SUM(total_laid_off)
FROM 
    layoffs_staging
GROUP BY 
    company, 
    YEAR([date])
), 
Company_Year_Rank as
(
SELECT 
    company,
    years,
    total_laid_off,
    DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM 
    Company_Year
WHERE 
    years IS NOT NULL
 )
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5

