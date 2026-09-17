-- Data Cleaning

SELECT *
FROM layoffs;

-- 1. Remove duplicates
-- 2. Standardize the data
-- 3. Null Values or blank values
-- 4. Remove Any Columns 

-- 1. Remove duplicates -- 
-- Copy the layoff table first
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- Assign a row number to check duplicate
SELECT *,
ROW_NUMBER() OVER(
Partition by company, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) As row_num
FROM layoffs_staging;
-- If you see a row number > 1, that's mean there is a duplicate

-- Create a duplicate table for it
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
Partition by company, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) As row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Now we find duplicate but we have to double check if they are really duplicate or not

-- We randomly pick one company to check
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Create another table to store non-duplicate data
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2
;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
Partition by company, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) As row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE row_num >1;

-- Standardizing data

-- Trim space
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- Update table
update layoffs_staging2
SET company = TRIM(company);

SELECT industry
FROM layoffs_staging2
ORDER BY 1;
-- We find 'Crypto Currency' and 'CryptoCurrency', we have to correct it

-- Now we have closer look with industry name Crypto
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';
-- We find Crypto; Crypto Currency; CryptoCurrency

-- Standardized to 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'; 

-- Now we check other industries
SELECT Distinct industry
FROM layoffs_staging2;
-- Seems ok

-- Now we check locations
SELECT distinct location
FROM layoffs_staging2
ORDER BY 1;

-- Find Wrong Spelling:
-- Dusseldorf --> D羹sseldorf
-- Malmo --> Malm繹
-- Florianopolis --> Florian籀polis ?

-- Update for Dusseldorf
UPDATE layoffs_staging2
SET location = 'Dusseldorf'
WHERE location = 'D羹sseldorf'; 

-- Check
SELECT location
FROM layoffs_staging2
WHERE location = 'Dusseldorf';

-- Update for Malmo
UPDATE layoffs_staging2
SET location = 'Malmo'
WHERE location = 'Malm繹'; 

-- Check
SELECT location
FROM layoffs_staging2
WHERE location = 'Malmo';

-- Update for Florianopolis
UPDATE layoffs_staging2
SET location = 'Florianopolis'
WHERE location = 'Florian籀polis'; 

-- Check
SELECT location
FROM layoffs_staging2
WHERE location = 'Florianopolis';

-- Check all location again
SELECT Distinct location
FROM layoffs_staging2
ORDER BY 1;
-- looks fine

-- Now check for country
SELECT Distinct country
FROM layoffs_staging2
ORDER BY 1;

-- Find United States. <-- one more dot
-- let's update it
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country = 'United States.'; 

-- Check for country
SELECT country
FROM layoffs_staging2
ORDER BY 1;
-- Looks fine now


-- Standardize format: change date from text column to date column

-- Check what will it be looks like
SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Update it now
Update layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

-- Check it
SELECT `date`
FROM layoffs_staging2;

-- But when you check the format of column date, it's still text
-- We have to change it
ALTER Table layoffs_staging2
MODIFY COLUMN `date` Date;

-- Interim check
Select *
From layoffs_staging2;

-- 3. Null Values or blank values

-- Check for NULL industry: We may be able to fill it for some missing value

-- Check NULL industry
SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL or industry = '';

-- We find that Airbnb has blank industry, we check if Airbnb has other column as well.
SELECT * 
FROM layoffs_staging2
WHERE company = 'Airbnb';
-- We find that Airbnb industry is Travel, and we check if other company has same situation

-- We use Join table to check
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Following companies have missing industry in some rows
-- (1) Airbnb
-- (2) Carvana
-- (3) Juul

-- We set the industry to NULL instead of blank before we update them
update layoffs_staging2
Set industry = null
Where industry = '';

-- We update these records
Update layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL)
AND t2.industry IS NOT NULL;

-- check Abnb
SELECT * 
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Check if the companies have no laid off data
-- Check
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete the row_num we created before since we don't need it
-- We use drop to drop column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Check
SELECT *
FROM layoffs_staging2;


