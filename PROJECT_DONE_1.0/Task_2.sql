/* VYZKUMNE OTAZKY
 *  1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 *  2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 *  3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 *  4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 *  5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na 
 * 	   cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?
*/

-- SOURCE TABLE 1

CREATE OR REPLACE VIEW v_js_avg_salary_per_branch_year AS
SELECT 
	cpib.name AS 'Branch'
	,cpay.payroll_year AS 'Year'
	,ROUND(AVG(cpay.value),0) AS 'Salary'
FROM czechia_payroll AS cpay 
JOIN czechia_payroll_industry_branch AS cpib
ON cpay.industry_branch_code = cpib.code 
WHERE cpay.value > 4000 						-- smaller values than minimum wage in 2000 are disregared, to clear up data
AND cpay.value IS NOT NULL 						-- NULL values also eliminated
GROUP BY cpib.name, cpay.payroll_year
ORDER BY cpib.name, cpay.payroll_year
;

-- SOURCE TABLE 2
CREATE OR REPLACE VIEW v_js_avg_product_price_per_branch_year AS
SELECT 
	cpc.name 'Product' 
	,DATE_FORMAT (cpri.date_to, '%Y') AS 'Year'
	,ROUND(AVG(cpri.value),2) AS 'Price'
FROM czechia_price AS cpri
JOIN czechia_price_category cpc ON cpri.category_code = cpc.code
GROUP BY cpc.name , DATE_FORMAT (cpri.date_to, '%Y');

-- THIS VIEW FILTERS YEARS AVAILABLE IN BOTH SOURCE TABLES
CREATE OR REPLACE VIEW v_js_years_intersect AS
	SELECT
	DISTINCT CAST ( Year as int) AS 'Year'
	FROM v_js_avg_salary_per_branch_year
	INTERSECT
	SELECT 
	DISTINCT CAST ( Year as int) AS 'Year'
	FROM v_js_avg_product_price_per_branch_year
	;

-- ##########################################################
	SELECT
	DISTINCT (avgsal.Year)
	FROM v_js_avg_salary_per_branch_year AS avgsal
	JOIN v_js_avg_product_price_per_branch_year AS avgprice
	ON	avgprice.Year = avgsal.Year
	;

-- TASK #2

-- This table returns average price in first and last year in prices table 	
CREATE OR REPLACE VIEW v_js_minmax_year_prices AS
SELECT 
	  Product
	 ,Year
	 ,Price
FROM v_js_avg_product_price_per_branch_year 
WHERE (Product = 'Chléb konzumní kmínový'  OR Product  = 'Mléko polotučné pasterované')
AND Year = 
	(SELECT MIN(Year) FROM  v_js_years_intersect )
GROUP BY Product, Year
UNION 
SELECT 
	  Product
	 ,Year
	 ,Price
FROM v_js_avg_product_price_per_branch_year 
WHERE (Product = 'Chléb konzumní kmínový'  OR Product  = 'Mléko polotučné pasterované')
AND Year = 
	(SELECT MAX(Year) FROM  v_js_years_intersect )
GROUP BY Product, Year
;

-- This table returns average salary in first and last year in prices table 	
CREATE OR REPLACE VIEW v_js_minmax_year_salaries AS
SELECT 
	  AVG(Salary) AS Salary
	 ,Year
FROM v_js_avg_salary_per_branch_year 
WHERE
Year = 
	(SELECT MIN(Year) FROM  v_js_years_intersect )
GROUP BY  Year
UNION
SELECT 
	  AVG(Salary) AS Salary
	 ,Year
FROM v_js_avg_salary_per_branch_year 
WHERE
Year = 
	(SELECT MAX(Year) FROM  v_js_years_intersect )
GROUP BY  Year

-- FINAL TABLE RETURNING NUMBER OF UNITS PURCHASEABLE WITH AVERAGE SALARY
SELECT
mm_prices.Product
,mm_prices.Year
,Round(mm_salaries.Salary/mm_prices.Price,0) AS 'nb of units/avg. salary'
FROM v_js_minmax_year_prices AS mm_prices
JOIN v_js_minmax_year_salaries AS mm_salaries
ON mm_prices.Year  = mm_salaries.Year

