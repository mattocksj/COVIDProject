/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM CovidDeaths
ORDER BY 3,4;

--SELECT *
--FROM CovidVacc
--ORDER BY 3,4;

-- Select Data that we are going to be using

SELECT 
    location, 
    date_, 
    total_cases, 
    new_cases, 
    total_deaths, 
    population
FROM CovidDeaths
ORDER BY 1,2;

-- Looking at Total Cases vs. Total Deaths
-- Shows likelihood of dying if you contract Covid in your country
SELECT 
    location, 
    date_, 
    total_cases, 
    total_deaths, 
    (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%States'
ORDER BY 1,2;

-- Looking at Total Cases vs. Population
-- Shows what percentage of population that contracted Covid
SELECT location, date_, population, total_cases, (total_cases/population)*100 AS InfectionPercentage
FROM CovidDeaths
--WHERE location LIKE '%States'
ORDER BY 1,2;

-- Looking at countries with highest Infection Rate compared to Population
SELECT location, population, HighestInfectionCount, InfectionPercentage
FROM (
    SELECT 
        location,
        population,
        MAX(total_cases) AS HighestInfectionCount,
        MAX((total_cases/population)*100) AS InfectionPercentage
    FROM CovidDeaths
    GROUP BY location, population
) 
WHERE InfectionPercentage IS NOT NULL
ORDER BY InfectionPercentage DESC;

-- Showing Continents with the Highest Death Count per Population
SELECT 
    continent, 
    Max(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- Showing Countries with the Highest Death Count per Population
SELECT location, TotalDeathCount
FROM (
    SELECT 
            location,
            Max(total_deaths) AS TotalDeathCount
    FROM CovidDeaths
    GROUP BY location
)
WHERE TotalDeathCount IS NOT NULL
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS
SELECT 
    date_, 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths, 
    CASE
        WHEN SUM(new_cases) = 0 THEN NULL
        ELSE SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100
    END AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date_
ORDER BY date_, total_cases;


-- Looking at Total Population vs. Vaccinations
SELECT 
    DEA.continent, 
    DEA.location, 
    DEA.date_, 
    DEA.population, 
    VAC.new_vaccinations,
    SUM(VAC.new_vaccinations) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date_) AS RollingPeopleVaccinated,
FROM CovidDeaths DEA
JOIN CovidVacc VAC
    ON DEA.location = VAC.location
    AND DEA.date_ = VAC.date_
WHERE DEA.continent IS NOT NULL
ORDER BY 2,3;

-- USE CTE
WITH PopVsVac (continent, location, date_, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT 
        DEA.continent, 
        DEA.location, 
        DEA.date_, 
        DEA.population, 
        VAC.new_vaccinations,
        SUM(VAC.new_vaccinations) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date_) AS RollingPeopleVaccinated
    FROM CovidDeaths DEA
    JOIN CovidVacc VAC
        ON DEA.location = VAC.location
        AND DEA.date_ = VAC.date_
    WHERE DEA.continent IS NOT NULL
    ORDER BY 2,3
)
SELECT 
    PVV.*,
    (PVV.RollingPeopleVaccinated / PVV.population) * 100 AS VaccinationPercentage
FROM PopVsVac PVV;

-- TEMP Table
CREATE TABLE CovidPCTVacc
(
    continent NVARCHAR2(255),
    location NVARCHAR2(255),
    date_ DATE,
    population NUMBER,
    new_vaccinations NUMBER,
    RollingPeopleVaccinated NUMBER
);


INSERT INTO CovidPCTVacc
SELECT 
    DEA.continent, 
    DEA.location, 
    DEA.date_, 
    DEA.population, 
    VAC.new_vaccinations,
    SUM(VAC.new_vaccinations) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date_) AS RollingPeopleVaccinated
FROM CovidDeaths DEA
JOIN CovidVacc VAC
    ON DEA.location = VAC.location
    AND DEA.date_ = VAC.date_
WHERE DEA.continent IS NOT NULL
ORDER BY 2,3;

SELECT 
    *
FROM CovidPCTVacc;

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    DEA.continent, 
    DEA.location, 
    DEA.date_, 
    DEA.population, 
    VAC.new_vaccinations,
    SUM(VAC.new_vaccinations) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date_) AS RollingPeopleVaccinated
FROM CovidDeaths DEA
JOIN CovidVacc VAC
    ON DEA.location = VAC.location
    AND DEA.date_ = VAC.date_
WHERE DEA.continent IS NOT NULL
ORDER BY 2,3;

SELECT *
FROM PercentPopulationVaccinated;
