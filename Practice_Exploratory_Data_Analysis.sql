-- Exploratory Data Analysis

SELECT *
FROM layoffs_staging2;

-- Check total layoff in numbers
SELECT MAX(total_laid_off)
FROM layoffs_staging2;

-- Check total layoff in percentage
SELECT MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Check the companies with 100% layoff ordered by largest number
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Check the companies with 100% layoff ordered by fundings
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Check the sum of total laid off for each company
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Check the period of laid off
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Check which industry hit the most
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Check which country hit the most
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Check the lay off numbers by years
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- Check the lay off numbers by company's stage
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- Check the progression of layoff by company

-- Obtain the sum of total layoff by month first
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH` 
ORDER BY 1 ASC;

-- Obtain the rolling sum of total layoff by month
With Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) As total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH` 
ORDER BY 1 ASC
)
SELECT `Month`, total_off,
SUM(total_off) OVER(order by `MONTH`) As rolling_total
FROM Rolling_Total;


-- See which year, which company layoff most employee 

-- Let's group the sum of total laid off of each company first
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- 
With Company_Year (company, years, total_laid_off) As
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(
SELECT *, 
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <=5
;

