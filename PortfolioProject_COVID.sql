-- Ensuring that the data was imported correctly

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths 
		-- to evaluate the likelyhood of death after contracting covid 

SELECT location, date, total_cases, total_deaths, 
       TRY_CONVERT(decimal(10,2),total_deaths)/TRY_CONVERT(decimal(10,2),total_cases) * 100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Looking at countries with highest infection rate compared to population

SELECT location,population, MAX(total_cases) AS highest_infection_count, 
       MAX(TRY_CONVERT(decimal(10,2), total_cases) / TRY_CONVERT(decimal(10,2), population)) * 100 AS percent_of_population_infected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_of_population_infected DESC

-- Looking at countries with the highest death count per population

SELECT location, MAX(cast(total_deaths as int)) AS total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Looking at continents with the highest death count per population


SELECT continent, MAX(cast(total_deaths as int)) AS total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY total_death_count DESC


-- Looking from the global viewpoint

SELECT  SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
        SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2

-- Looking at total population vs vaccination


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccinated_people_rolling_count
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3


-- Using CTE to calculate percentage of people vaccinated

WITH PopvsVAC (continent, location, date, population, new_vaccinations, vaccinated_people_rolling_count)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccinated_people_rolling_count
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, (vaccinated_people_rolling_count/population) * 100 AS percentage_of_people_vaccinated
FROM PopvsVAC


-- Creating View to store data for vizualizations later

CREATE VIEW PopvsVAC AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccinated_people_rolling_count
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL