/* VYZKUMNE OTAZKY
 *  1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 *  2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 *  3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 *  4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 *  5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na 
 *     cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?
 */

-- THIS VIEW FILTERS YEARS AVAILABLE IN BOTH SOURCE TABLES
CREATE OR REPLACE VIEW v_js_years_intersect AS
SELECT
    DISTINCT CAST(Year AS INT) AS Year
FROM 
    t_js_avg_salary_per_branch_year
INTERSECT
SELECT 
    DISTINCT CAST(Year AS INT) AS Year
FROM 
    t_js_avg_product_price_per_branch_year;

-- TASK #2

-- This table returns average price in first and last year in prices table 
CREATE OR REPLACE VIEW v_js_minmax_year_prices AS
SELECT 
    Product,
    Year,
    Price
FROM 
    t_js_avg_product_price_per_branch_year 
WHERE 
    (Product = 'Chléb konzumní kmínový' OR Product = 'Mléko polotučné pasterované')
    AND Year = 
        (SELECT MIN(Year) FROM v_js_years_intersect)
GROUP BY 
    Product, Year
UNION 
SELECT 
    Product,
    Year,
    Price
FROM 
    t_js_avg_product_price_per_branch_year 
WHERE 
    (Product = 'Chléb konzumní kmínový' OR Product = 'Mléko polotučné pasterované')
    AND Year = 
        (SELECT MAX(Year) FROM v_js_years_intersect)
GROUP BY 
    Product, Year;

-- This table returns average salary in first and last year in salaries table 
CREATE OR REPLACE VIEW v_js_minmax_year_salaries AS
SELECT 
    AVG(Salary) AS Salary,
    Year
FROM 
    t_js_avg_salary_per_branch_year 
WHERE
    Year = 
        (SELECT MIN(Year) FROM v_js_years_intersect)
GROUP BY 
    Year
UNION
SELECT 
    AVG(Salary) AS Salary,
    Year
FROM 
    t_js_avg_salary_per_branch_year 
WHERE
    Year = 
        (SELECT MAX(Year) FROM v_js_years_intersect)
GROUP BY 
    Year;

-- FINAL TABLE RETURNING NUMBER OF UNITS PURCHASEABLE WITH AVERAGE SALARY
SELECT
    mm_prices.Product,
    mm_prices.Year,
    ROUND(mm_salaries.Salary / mm_prices.Price, 0) AS Units_per_avg_salary
FROM 
    v_js_minmax_year_prices AS mm_prices
JOIN 
    v_js_minmax_year_salaries AS mm_salaries ON mm_prices.Year = mm_salaries.Year;
