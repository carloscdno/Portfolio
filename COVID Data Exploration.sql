-- Summary Table (Data chosen to perform the analysis)
DROP TABLE IF EXISTS covid19cleaned --in case I want to add or modify something later
SELECT continent, location, population/10 AS population_fix, CONVERT(Date, date) AS date_simplified, total_cases/10 AS total_cases_fix, 
new_cases/10 AS new_cases_fix, total_deaths/10 AS total_deaths_fix, new_deaths/10 AS new_deaths_fix, CONVERT(float, total_vaccinations) AS total_vaccinations_fix, 
CONVERT(float, new_vaccinations) AS new_vaccinations_fix, CONVERT(float, people_fully_vaccinated) AS people_fully_vaccinated_fix
INTO covid19cleaned
FROM PortfolioProject..covid19
WHERE total_deaths IS NOT NULL
ORDER BY location, date

SELECT continent, location
FROM covid19cleaned
WHERE continent > ' '
ORDER BY location, date_simplified

-- Cases that have been reported
SELECT location, MAX(total_cases_fix) AS total_cases_per_continent
FROM covid19cleaned
WHERE location IN('Europe', 'South America', 'North America', 'Africa', 'Asia', 'Oceania')
GROUP BY location
ORDER BY total_cases_per_continent DESC

-- Total Cases vs Population
-- How much percentage of the population got Covid
SELECT location, continent, population_fix, MAX(total_cases_fix/population_fix)*100 AS percent_pop_infected 
FROM covid19cleaned
WHERE continent > ' '
GROUP BY location, continent, population_fix
ORDER BY percent_pop_infected DESC 

-- People that has recovered from the virus per continent
SELECT location, MAX(total_cases_fix-total_deaths_fix) AS total_recovery
FROM covid19cleaned
WHERE location IN('Europe', 'South America', 'North America', 'Africa', 'Asia', 'Oceania')
GROUP BY location
ORDER BY total_recovery DESC

-- Countries with highest infection rate compared to their population
SELECT location, population_fix,  MAX(total_cases_fix) AS highest_infection_count, MAX(total_cases_fix/population_fix)*100 AS infection_rate
FROM covid19cleaned
WHERE continent > ' '
GROUP BY location, population_fix, date_simplified
ORDER BY infection_rate DESC

-- Deaths per continent
SELECT location, MAX(total_deaths_fix) AS total_deaths_per_continent
FROM covid19cleaned
WHERE location IN('Europe', 'South America', 'North America', 'Africa', 'Asia', 'Oceania')
GROUP BY location
ORDER BY total_deaths_per_continent DESC

-- Countries with highest death count
SELECT location, continent, MAX(total_deaths_fix) AS death_count
FROM covid19cleaned
WHERE continent > ' ' 
GROUP BY location, continent
ORDER BY death_count DESC

-- Cases per day, number of deaths and global death percentage 
SELECT date_simplified, SUM(new_cases_fix) AS cases_per_day, SUM(new_deaths_fix) AS deaths_per_day, 
(SUM(new_deaths_fix)/NULLIF(SUM(new_cases_fix),0))*100 AS global_death_percentage
FROM covid19cleaned
WHERE continent > ' '
GROUP BY date_simplified
ORDER BY date_simplified

-- Total Cases vs Total Death
-- Likelihood of dying if you get the virus in your country
SELECT location, MAX(total_deaths_fix/population_fix)*100 AS death_percentage
FROM covid19cleaned
WHERE continent > ' '
GROUP BY location
ORDER BY death_percentage DESC

-- People that have been fully vaccinated
SELECT location, MAX(people_fully_vaccinated_fix) AS fully_vaccinated_per_continent
FROM covid19cleaned
WHERE location IN('Europe', 'South America', 'North America', 'Africa', 'Asia', 'Oceania')
GROUP BY location
ORDER BY fully_vaccinated_per_continent DESC

-- Countries with a higher percentage of vaccinated population
SELECT location, continent, population_fix, MAX(people_fully_vaccinated_fix/population_fix)*100 AS perc_vaccinated_pop
FROM covid19cleaned
WHERE continent > ' ' 
GROUP BY location,continent,population_fix
ORDER BY perc_vaccinated_pop DESC

-- Total population vs. Vaccinations
-- First, we calculate the number of people per country that have received at least one dose. I created a partition to see the increase over time
SELECT continent, location, date_simplified, population_fix, new_vaccinations_fix, 
SUM(new_vaccinations_fix) OVER (PARTITION BY location ORDER BY location, date_simplified) AS num_vaccinated
FROM covid19cleaned
WHERE continent > ' ' 
ORDER BY 2,3

-- Then we can use a CTE to calculate the percentage of people that have received at least one vaccination compared to their population
WITH PopvsVac (continent, location, date_simplified, population_fix, new_vaccinations_fix, num_vaccinated)
AS
(SELECT continent, location, date_simplified, population_fix, new_vaccinations_fix, 
SUM(new_vaccinations_fix) OVER (PARTITION BY location ORDER BY location, date_simplified) AS num_vaccinated
FROM covid19cleaned
WHERE continent > ' ' 
)

SELECT *, (num_vaccinated/population_fix)*100 AS percentage_at_least_one_vac
FROM PopvsVac


-- Views to store data for later visualization
CREATE VIEW percent_infected_population AS
SELECT location, MAX(total_cases_fix/population_fix)*100 AS percent_pop_infected 
FROM covid19cleaned
GROUP BY location

CREATE VIEW recovered_people AS
SELECT location, MAX(total_cases_fix-total_deaths_fix) AS total_recovery
FROM covid19cleaned
WHERE location IN('Europe', 'South America', 'North America', 'Africa', 'Asia', 'Oceania')
GROUP BY location

CREATE VIEW reported_cases_around_the_world AS
SELECT location, MAX(total_cases_fix) AS total_cases_per_continent
FROM covid19cleaned
WHERE location IN('Europe', 'South America', 'North America', 'Africa', 'Asia', 'Oceania')
GROUP BY location

CREATE VIEW highest_infection AS
SELECT location, population_fix, MAX(total_cases_fix) AS reported_cases, MAX(total_cases_fix/population_fix)*100 AS infection_rate
FROM covid19cleaned
WHERE continent > ' '
GROUP BY location, population_fix

CREATE VIEW deaths_per_continent AS
SELECT location, MAX(total_deaths_fix) AS total_deaths_per_continent
FROM covid19cleaned
WHERE location IN('Europe', 'South America', 'North America', 'Africa', 'Asia', 'Oceania')
GROUP BY location

CREATE VIEW death_count AS
SELECT location, MAX(total_deaths_fix) AS death_count
FROM covid19cleaned
WHERE continent > ' ' 
GROUP BY location

CREATE VIEW death_perc_around_the_world AS
SELECT date_simplified, SUM(new_cases_fix) AS cases_per_day, SUM(new_deaths_fix) AS deaths_per_day, 
(SUM(new_deaths_fix)/NULLIF(SUM(new_cases_fix),0))*100 AS global_death_percentage
FROM covid19cleaned
WHERE continent > ' '
GROUP BY date_simplified

CREATE VIEW likelihood_of_dying AS
SELECT location, MAX(total_deaths_fix/population_fix)*100 AS death_percentage
FROM covid19cleaned
WHERE continent > ' '
GROUP BY location

CREATE VIEW fully_vaccinated AS
SELECT location, MAX(people_fully_vaccinated_fix) AS fully_vaccinated_per_continent
FROM covid19cleaned
WHERE location IN('Europe', 'South America', 'North America', 'Africa', 'Asia', 'Oceania')
GROUP BY location

CREATE VIEW fully_vac_perc AS
SELECT location, population_fix, MAX(people_fully_vaccinated_fix/population_fix)*100 AS perc_vaccinated_pop
FROM covid19cleaned
WHERE continent > ' ' 
GROUP BY location,population_fix

SELECT SUM(cases_per_day) AS total_cases, SUM(deaths_per_day) AS total_deaths, (SUM(deaths_per_day)/SUM(cases_per_day))*100 AS death_percentage
FROM death_perc_around_the_world

SELECT *
FROM highest_infection
ORDER BY infection_rate DESC

