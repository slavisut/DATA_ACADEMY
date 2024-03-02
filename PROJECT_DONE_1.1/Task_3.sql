/* VYZKUMNE OTAZKY
 *  1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 *  2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 *  3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 *  4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 *  5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na 
 *     cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
 */

/* TASK #3
 * This table uses CTE to give you total and annual price increase for all products.
 * Financial formula used: P2 = P1 * (1 + I)^Y Where
 * P1 = Initial Price
 * P2 = Final price
 * I = Annual increase
 * Y = Number of years
 * Modified formula for I: I = ((P2 / P1) - 1)^(1/Y)
 */

WITH cte_prices_2006 AS (
    SELECT 
        Product,
        AVG(Price) AS Price1,
        Year AS Year1
    FROM 
        t_js_avg_product_price_per_branch_year
    WHERE 
        Year = (SELECT MIN(Year) FROM t_js_avg_product_price_per_branch_year)
    GROUP BY 
        Product
), 
cte_prices_2018 AS (
    SELECT 
        Product,
        AVG(Price) AS Price2,
        Year AS Year2
    FROM 
        t_js_avg_product_price_per_branch_year
    WHERE 
        Year = (SELECT MAX(Year) FROM t_js_avg_product_price_per_branch_year)
    GROUP BY 
        Product
)
SELECT 
    *,
    ROUND(((pr2018.Price2 - pr2006.Price1) / pr2006.Price1) * 100, 2) AS 'Total price change [%]',
    ROUND((POWER((pr2018.Price2 / pr2006.Price1), (1 / (Year2 - Year1))) - 1) * 100, 2) AS 'Annual price change [%]'
FROM 
    cte_prices_2006 AS pr2006
JOIN 
    cte_prices_2018 AS pr2018 ON pr2006.Product = pr2018.Product 
ORDER BY 
    'Annual price change [%]';
