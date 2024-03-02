/* VYZKUMNE OTAZKY
 *  1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 *  2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 *  3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 *  4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 *  5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na 
 *     cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
*/

-- QUERY COMPARING PRICES & GDP DIFFERENCE
WITH cte_GDP_diff AS (
    SELECT
        e1.Country,
        e1.Year AS Year1,
        e2.Year AS Year2,
        ROUND(((e2.GDP / e1.GDP) - 1) * 100, 2) AS GDP_diff,
        e1.GDP AS GDP_Year1,
        e2.GDP AS GDP_Year2
    FROM 
        economies AS e1
    LEFT OUTER JOIN 
        economies AS e2 ON e2.Year = e1.Year + 1
    WHERE 
        e1.Country = 'Czech Republic'
        AND e2.Country = 'Czech Republic'
), 
cte_prices_diff AS (
    SELECT
        avgprice1.Year AS Year1,
        avgprice2.Year AS Year2,
        ROUND(AVG(avgprice1.Price), 0) AS Price1,
        ROUND(AVG(avgprice2.Price), 0) AS Price2,
        ROUND((AVG(avgprice2.Price) / AVG(avgprice1.Price) - 1) * 100, 2) AS Price_Diff
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
    prices.Year1 AS Year,
    gdp.GDP_diff,
    prices.Price_Diff
FROM 
    cte_GDP_diff AS gdp
JOIN 
    cte_prices_diff AS prices ON gdp.Year1 = prices.Year1;
