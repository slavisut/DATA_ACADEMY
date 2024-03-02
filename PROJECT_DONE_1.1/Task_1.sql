/* VYZKUMNE OTAZKY
 *  1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 *  2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 *  3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 *  4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 *  5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na 
 *     cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?
*/

--    GENERAL SOURCE PART    --

-- SOURCE TABLE 1
CREATE OR REPLACE TABLE t_js_avg_salary_per_branch_year AS
SELECT 
    cpib.name AS Branch,
    cpay.payroll_year AS Year,
    ROUND(AVG(cpay.value), 0) AS Salary
FROM 
    czechia_payroll AS cpay 
JOIN 
    czechia_payroll_industry_branch AS cpib ON cpay.industry_branch_code = cpib.code 
WHERE 
    cpay.value_type_code = 5958               -- only take into consideration wages given in monthly income, not hourly
    AND cpay.value IS NOT NULL                -- NULL values also eliminated
GROUP BY 
    cpib.name, cpay.payroll_year
ORDER BY 
    cpib.name, cpay.payroll_year;

-- SOURCE TABLE 2
CREATE OR REPLACE TABLE t_js_avg_product_price_per_branch_year AS
SELECT 
    cpc.name AS Product,
    DATE_FORMAT(cpri.date_to, '%Y') AS Year,
    ROUND(AVG(cpri.value), 2) AS Price
FROM 
    czechia_price AS cpri
JOIN 
    czechia_price_category AS cpc ON cpri.category_code = cpc.code
GROUP BY 
    cpc.name, DATE_FORMAT(cpri.date_to, '%Y');



/* This table shows you annual growth or decline in salaries per branch. 
Year X is always compared to the previous X-1 eg. 2001 vs 2000 */
CREATE OR REPLACE VIEW v_js_annual_salary_growth_per_branch AS
SELECT 
    m1.Branch,
    m1.Year AS Year_X_1,
    m1.Salary AS Salary_X_1,
    m2.Year AS Year_X,
    m2.Salary AS Salary_X,
    ROUND(((m2.Salary / m1.Salary) - 1) * 100, 2) AS Annual_salary_growth_percent
FROM 
    t_js_avg_salary_per_branch_year AS m1
LEFT OUTER JOIN 
    t_js_avg_salary_per_branch_year AS m2 ON m2.Year = (m1.Year + 1) AND m1.Branch = m2.Branch
GROUP BY 
    m1.Branch, m1.Year
-- HAVING ROUND(((m2.Salary / m1.Salary) - 1) * 100, 2) < 0  -- Disable this comment to get only negative years
;

/* This table shows you cumulative growth or decline in salaries per branch,
 * and if growth was interruped by decline in any ot the years
 * First measured year = 2000, last = 2021  */
SELECT
    avgsal.Branch,
    ROUND((MAX(avgsal.Salary) / MIN(avgsal.Salary) - 1) * 100, 2) AS Total_salary_growth_percent,
    CASE
        WHEN MIN(avgsal.Salary) - MAX(avgsal.Salary) > 0 THEN 'DECREASE'
        ELSE 'INCREASE'
    END AS Salary_trend,
    CASE 
        WHEN MIN(annsal.Annual_salary_growth_percent) > 0 THEN 'NO'
        ELSE 'YES'
    END AS WAS_GROWTH_INTERRUPTED
FROM 
    t_js_avg_salary_per_branch_year AS avgsal
JOIN
