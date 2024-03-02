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

-- SOURCE TABLE 2A
CREATE OR REPLACE VIEW v_js_avg_product_price_per_branch_year AS
SELECT 
	cpc.name 'Product' 
	,DATE_FORMAT (cpri.date_to, '%Y') AS 'Year'
	,ROUND(AVG(cpri.value),2) AS 'Price'
FROM czechia_price AS cpri
JOIN czechia_price_category cpc ON cpri.category_code = cpc.code
GROUP BY cpc.name , DATE_FORMAT (cpri.date_to, '%Y');

/* TASK #3
 * 
 This table uses CTE to give you total and annual price increase for all products
 Financial formula used:  P2 = P1*(1+I)^Y Where
 P1 = Initial Price
 P2 = Final price
 I = Annual increase
 Z = Number of years
Modified formula for I:
I= ((C2/C1)-1)^(1/Y)
*/

WITH 
cte_prices_2006 AS(
SELECT 
	 Product
	,AVG(Price) AS Price1
	,Year 		AS Year1
FROM v_js_avg_product_price_per_branch_year
WHERE Year  =  (SELECT MIN(Year) FROM  v_js_avg_product_price_per_branch_year )
GROUP BY Product ),
cte_prices_2018 AS (
SELECT 
	 Product
	,AVG(Price) AS Price2
	,Year		AS Year2
FROM v_js_avg_product_price_per_branch_year
WHERE Year  =  (SELECT MAX(Year) FROM  v_js_avg_product_price_per_branch_year )
GROUP BY Product)
SELECT 
*
,ROUND(((pr2018.Price2-pr2006.Price1)/pr2006.Price1)*100,2) 'Total price change [%]'
,ROUND((POWER((pr2018.Price2/pr2006.Price1),(1/(Year2-Year1)))-1)*100,2) AS 'Annual price change [%]'
FROM cte_prices_2006  AS pr2006
JOIN cte_prices_2018  AS pr2018
ON pr2006.Product = pr2018.Product 
ORDER BY ROUND((POWER((pr2018.Price2/pr2006.Price1),(1/(Year2-Year1)))-1)*100,2);



