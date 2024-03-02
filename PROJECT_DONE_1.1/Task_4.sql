/* VYZKUMNE OTAZKY
 *  1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 *  2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 *  3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 *  4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 *  5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na 
 *     cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
*/

-- TASK #4

WITH cte_salaries AS (
    SELECT
        avgsal1.Year AS Year1,
        avgsal2.Year AS Year2,
        ROUND(AVG(avgsal1.Salary), 0) AS Salary1,
        ROUND(AVG(avgsal2.Salary), 0) AS Salary2,
        ROUND((AVG(avgsal2.Salary) / AVG(avgsal1.Salary) - 1) * 100, 2) AS Diff
    FROM 
        t_js_avg_salary_per_branch_year AS avgsal1
    LEFT OUTER JOIN 
        t_js_avg_salary_per_branch_year AS avgsal2 ON avgsal2.Year = (avgsal1.Year + 1)
    GROUP BY 
        avgsal2.Year
    ORDER BY 
        avgsal1.Year
),
cte_prices AS (
    SELECT
        avgprice1.Year AS Year1,
        avgprice2.Year AS Year2,
        ROUND(AVG(avgprice1.Price), 0) AS Price1,
        ROUND(AVG(avgprice2.Price), 0) AS Price2,
        ROUND((AVG(avgprice2.Price) / AVG(avgprice1.Price) - 1) * 100, 2) AS Diff
    FROM 
        t_js_avg_product_price_per_branch_year AS avgprice1
    LEFT OUTER JOIN 
        t_js_avg_product_price_per_branch_year AS avgprice2 ON avgprice2.Year = (avgprice1.Year + 1)
    GROUP BY 
        avgprice2.Year
    ORDER BY 
        avgprice1.Year
)
SELECT 
    cte_salaries.Year2 AS Year,
    cte_prices.Diff AS ΔPrices[%],
    cte_salaries.Diff AS ΔSalaries[%],
    CASE 
        WHEN cte_prices.Diff IS NULL OR cte_salaries.Diff IS NULL THEN 'NO DATA'
        ELSE cte_prices.Diff - cte_salaries.Diff
    END AS 'Price vs Salary change [%]'
FROM 
    cte_salaries
LEFT OUTER JOIN 
    cte_prices ON cte_prices.Year2 = cte_salaries.Year2
ORDER BY 
    (cte_prices.Diff - cte_salaries.Diff);
