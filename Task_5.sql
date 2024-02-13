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


-- GDP GROWTH OVER YEARS
SELECT
	 e1.Country
	,e1.Year AS Year1
	,e2.Year AS Year2
	,ROUND(((e2.GDP/e1.GDP)-1)*100,2) AS 'GDP_diff'
	,e1.GDP  AS 'GDP_Year1'
	,e2.GDP	 AS 'GDP_Year2'
FROM economies 				AS e1
LEFT OUTER JOIN economies	AS e2
ON (e2.Year = e1.year+1)
WHERE  e1.country = 'Czech republic'
AND  e2.country = 'Czech republic'
;

-- CTE_PRICES_DIFF[%]
SELECT
	avgprice1.Year	AS Year1
	,avgprice2.Year	AS Year2
	,ROUND(AVG(avgprice1.Price),0) AS Price1
	,ROUND(AVG(avgprice2.Price),0) AS Price2
	,ROUND((AVG(avgprice2.Price)/AVG(avgprice1.Price)-1)*100,2) AS 'Diff[%]'
FROM v_js_avg_product_price_per_branch_year 				AS avgprice1
LEFT OUTER JOIN v_js_avg_product_price_per_branch_year		AS avgprice2
ON avgprice2.Year = (avgprice1.Year+1)
GROUP BY avgprice2.Year
ORDER BY avgprice1.Year;


-- QUERYCOMPARING PRICES & GDP DIFFERENCE
WITH cte_GDP_diff AS (
SELECT
	 e1.Country
	,e1.Year AS Year1
	,e2.Year AS Year2
	,ROUND(((e2.GDP/e1.GDP)-1)*100,2) AS 'GDP_diff'
	,e1.GDP  AS 'GDP_Year1'
	,e2.GDP	 AS 'GDP_Year2'
FROM economies 				AS e1
LEFT OUTER JOIN economies	AS e2
ON (e2.Year = e1.year+1)
WHERE  e1.country = 'Czech republic'
AND  e2.country = 'Czech republic'
), cte_prices_diff AS(
SELECT	
	 avgprice1.Year	AS Year1
	,avgprice2.Year	AS Year2
	,ROUND(AVG(avgprice1.Price),0) AS Price1
	,ROUND(AVG(avgprice2.Price),0) AS Price2
	,ROUND((AVG(avgprice2.Price)/AVG(avgprice1.Price)-1)*100,2) AS 'Price_Diff'
FROM v_js_avg_product_price_per_branch_year 				AS avgprice1
LEFT OUTER JOIN v_js_avg_product_price_per_branch_year		AS avgprice2
ON avgprice2.Year = (avgprice1.Year+1)
GROUP BY avgprice2.Year
ORDER BY avgprice1.Year
)
SELECT
prices.Year1	AS Year
,GDP_diff
,Price_Diff
FROM cte_GDP_diff	 AS gdp
JOIN cte_prices_diff AS prices
ON gdp.Year1 = prices.Year1

