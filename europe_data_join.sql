/*Jako dodatečný materiál připravte i tabulku s HDP, 
 * GINI koeficientem a populací dalších evropských států ve stejném období, 
 * jako primární přehled pro ČR.
 */
CREATE OR REPLACE TABLE t_jan_slavik_project_SQL_secondary_final
SELECT 
	 c.country
	,c.population
	,e.GDP 
	,e.gini
	,e.year
FROM countries AS c 
JOIN economies AS e	
ON c.country = e.country 
WHERE 
c.continent = 'Europe'
AND
e.year BETWEEN 
	(SELECT
	min(Year)
	FROM
	t_jan_slavik_project_SQL_primary_final) 
AND
	(SELECT
	max(Year)
	FROM
	t_jan_slavik_project_SQL_primary_final);



