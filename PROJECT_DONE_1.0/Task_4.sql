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

-- TASK #4

-- CTE_SALARIES - testing approach
SELECT
	Year
	,ROUND(AVG(Salary),0)
FROM v_js_avg_salary_per_branch_year 			AS avgsal
GROUP BY 
Year;

-- CTE_SALARIES_DIFF[%] - testing approach
SELECT
	avgsal1.Year	AS Year1
	,avgsal2.Year	AS Year2
	,ROUND(AVG(avgsal1.Salary),0) AS Salary1
	,ROUND(AVG(avgsal2.Salary),0) AS Salary2
	,ROUND((AVG(avgsal2.Salary)/AVG(avgsal1.Salary)-1)*100,2) AS 'Diff[%]'
FROM v_js_avg_salary_per_branch_year 			AS avgsal1
LEFT OUTER JOIN v_js_avg_salary_per_branch_year			AS avgsal2
ON avgsal2.Year = (avgsal1.Year+1)
GROUP BY avgsal2.Year
ORDER BY avgsal1.Year;


-- CTE_PRICES - testing approach
SELECT
	Year
	,ROUND(AVG(Price),2)
FROM v_js_avg_product_price_per_branch_year 	AS avgprice
GROUP BY 
Year;

-- CTE_PRICES_DIFF[%] - testing approach
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



WITH cte_salaries AS (
SELECT
	avgsal1.Year	AS Year1
	,avgsal2.Year	AS Year2
	,ROUND(AVG(avgsal1.Salary),0) AS Salary1
	,ROUND(AVG(avgsal2.Salary),0) AS Salary2
	,ROUND((AVG(avgsal2.Salary)/AVG(avgsal1.Salary)-1)*100,2) AS 'Diff'
FROM v_js_avg_salary_per_branch_year 			AS avgsal1
LEFT OUTER JOIN v_js_avg_salary_per_branch_year			AS avgsal2
ON avgsal2.Year = (avgsal1.Year+1)
GROUP BY avgsal2.Year
ORDER BY avgsal1.Year
),
cte_prices AS(
SELECT
	avgprice1.Year	AS Year1
	,avgprice2.Year	AS Year2
	,ROUND(AVG(avgprice1.Price),0) AS Price1
	,ROUND(AVG(avgprice2.Price),0) AS Price2
	,ROUND((AVG(avgprice2.Price)/AVG(avgprice1.Price)-1)*100,2) AS 'Diff'
FROM v_js_avg_product_price_per_branch_year 				AS avgprice1
LEFT OUTER JOIN v_js_avg_product_price_per_branch_year		AS avgprice2
ON avgprice2.Year = (avgprice1.Year+1)
GROUP BY avgprice2.Year
ORDER BY avgprice1.Year
)
SELECT 
	cte_salaries.Year2	AS	'Year'
 	,cte_prices.Diff 	AS 'ΔPrices[%]'
	,cte_salaries.Diff 	AS 'ΔSalaries[%]'
	,CASE 
		WHEN (cte_prices.Diff IS NULL OR cte_salaries.DiFf IS NULL ) 
		THEN "NO DATA"
		ELSE cte_prices.Diff-cte_salaries.Diff
	END AS "Price vs Salary change [%]"
FROM cte_salaries
LEFT OUTER JOIN cte_prices 
 ON cte_prices.Year2 = cte_salaries.Year2
ORDER BY cte_salaries.Year2;
/*
JOIN v_js_avg_product_price_per_branch_year 	AS avgprice
ON avgsal.`Year` = avgprice.`Year` 
*/



