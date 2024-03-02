
/*Potřebují k tomu od vás připravit robustní datové podklady,
 * ve kterých bude možné vidět porovnání dostupnosti potravin na základě průměrných příjmů za určité časové období.
 */

CREATE OR REPLACE TABLE t_jan_slavik_project_salaries  -- t_jan_slavik_project_SQL_primary_final
SELECT 
	'SALARY' AS 'TYPE'
	,cpib.name AS 'Branch_Product'
	,DATE_FORMAT (CONCAT(cpay.payroll_year,'-01','-01'), '%Y') AS 'Year'
	,ROUND(AVG(cpay.value),0) AS 'Salary_Price'
FROM czechia_payroll AS cpay 
JOIN czechia_payroll_industry_branch AS cpib
ON cpay.industry_branch_code = cpib.code 
WHERE cpay.value > 4000 						-- smaller values than minimum wage in 2000 are disregared, to clear up data
AND cpay.value IS NOT NULL 						-- NULL values also eliminated
GROUP BY cpib.name, cpay.payroll_year
ORDER BY cpib.name, cpay.payroll_year;

DESCRIBE t_jan_slavik_project_salaries;

ALTER TABLE t_jan_slavik_project_salaries
MODIFY Salary_Price decimal(11,0),
MODIFY TYPE VARCHAR(10);

CREATE OR REPLACE TABLE t_jan_slavik_project_prices
SELECT
	'PRICE' AS 'TYPE'
	,cpc.name 'Branch_Product'
	,DATE_FORMAT (cpri.date_to, '%Y') AS 'Year'
	,ROUND(AVG(cpri.value),2) AS 'Salary_Price'
FROM czechia_price AS cpri
JOIN czechia_price_category cpc ON cpri.category_code = cpc.code
GROUP BY cpc.name , DATE_FORMAT (cpri.date_to, '%Y');

DESCRIBE t_jan_slavik_project_prices;

ALTER TABLE t_jan_slavik_project_prices
MODIFY Salary_Price decimal(11,0),
MODIFY Branch_Product VARCHAR(255),
MODIFY TYPE VARCHAR(10);

CREATE OR REPLACE TABLE t_jan_slavik_project_SQL_primary_final
SELECT 
*
FROM t_jan_slavik_project_salaries
UNION
SELECT
*
FROM t_jan_slavik_project_prices
