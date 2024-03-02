/*Potřebují k tomu od vás připravit robustní datové podklady,
 * ve kterých bude možné vidět porovnání dostupnosti potravin na základě průměrných příjmů za určité časové období.
 */

CREATE OR REPLACE TABLE t_jan_slavik_project_salaries
SELECT 
    'SALARY' AS TYPE,
    cpib.name AS Branch_Product,
    cpay.payroll_year,
    ROUND(AVG(cpay.value), 0) AS Salary_Price
FROM 
    czechia_payroll AS cpay 
JOIN 
    czechia_payroll_industry_branch AS cpib ON cpay.industry_branch_code = cpib.code 
WHERE 
    cpay.value_type_code = 5958                -- only take into consideration wages given in monthly income, not hourly
    AND cpay.value IS NOT NULL                 -- NULL values also eliminated
GROUP BY 
    cpib.name, 
    cpay.payroll_year
ORDER BY 
    cpib.name, 
    cpay.payroll_year;

CREATE OR REPLACE TABLE t_jan_slavik_project_prices
SELECT
    'PRICE' AS TYPE,
    cpc.name AS Branch_Product,
    YEAR(cpri.date_to) AS Year,
    ROUND(AVG(cpri.value), 2) AS Salary_Price
FROM 
    czechia_price AS cpri
JOIN 
    czechia_price_category AS cpc ON cpri.category_code = cpc.code
GROUP BY 
    cpc.name, 
    YEAR(cpri.date_to);

CREATE OR REPLACE TABLE t_jan_slavik_project_SQL_primary_final
SELECT 
    *
FROM 
    t_jan_slavik_project_salaries
UNION
SELECT
    *
FROM 
    t_jan_slavik_project_prices;
