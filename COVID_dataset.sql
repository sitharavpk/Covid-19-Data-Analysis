SELECT location, date, total_cases, total_deaths, population
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths`
WHERE location LIKE '%Asia%' and continent is not null 
ORDER BY LOCATION,DATE;

-- Total deaths Vs Total Cases - Likelihood of dying due to COVID in Asia--

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths`
WHERE location LIKE '%Asia%'
ORDER BY LOCATION,DATE;


-- Total Cases Vs Population - Percentage of people infected with COVID in Asia--

SELECT location, date, total_cases, population, (total_cases/population)*100 as InfectedPercentage
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths`
WHERE location LIKE '%Asia%'
and continent is not null
ORDER BY LOCATION,DATE;

-- Countries with highest infection rate per Population --

SELECT location, MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases/population))*100 as PercentagePopulationInfected
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths`
WHERE continent is not null
GROUP BY location,population
ORDER BY PercentagePopulationInfected DESC;


-- Countries with highest death count --

SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths`
WHERE continent is not null
GROUP BY location
ORDER BY HighestDeathCount DESC;

-- Continents with highest death count --

SELECT continent , MAX(cast(total_deaths as int)) as TotalDeathCount
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths`
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Total cases and Total Deaths on each day --

SELECT date , SUM(new_cases) as Cases, SUM(cast(new_deaths as int)) as Deaths
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths`
WHERE continent is not null
GROUP BY date
ORDER BY date;


-- Death Percentage across the world on each day --

SELECT date , SUM(new_cases) as Cases, SUM(cast(new_deaths as int)) as Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths`
WHERE continent is not null and new_cases > 0
GROUP BY date
ORDER BY date;


-- Total Death Percentage in the World --

SELECT SUM(new_cases) as Cases, SUM(cast(new_deaths as int)) as Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths`
WHERE continent is not null;



-- Joining both the tables using location and date attributes --

SELECT *
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths` as deat
JOIN `beaming-pillar-381706.CovidProject.Covid_Vaccinations` as vacc
  ON deat.location = vacc.location
  and deat.date = vacc.date;


-- People Vaccinated  --

SELECT deat.continent, deat.location,deat.date, deat.population,vacc.new_vaccinations
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths` as deat
JOIN `beaming-pillar-381706.CovidProject.Covid_Vaccinations` as vacc
  ON deat.location = vacc.location
  and deat.date = vacc.date
WHERE deat.continent is not null
order by 2,3;


-- Total People Vaccinated Location-wise --

SELECT deat.continent, deat.location,deat.date, deat.population,vacc.new_vaccinations, SUM(cast(vacc.new_vaccinations as int)) OVER (PARTITION BY deat.location ORDER BY deat.location, deat.date) as Cummulated_Vaccinated
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths` as deat
JOIN `beaming-pillar-381706.CovidProject.Covid_Vaccinations` as vacc
  ON deat.location = vacc.location
  and deat.date = vacc.date
WHERE deat.continent is not null
order by 2,3;


-- Percentage of Vaccinated People - computing from the new column from the above table, using Temp Table --


CREATE OR REPLACE TEMP TABLE PercentPopulationVaccinated
AS
(
  SELECT deat.continent, deat.location, deat.date, deat.population as population,vacc.new_vaccinations, SUM(cast(vacc.new_vaccinations as int)) OVER (PARTITION BY deat.location ORDER BY deat.location, deat.date) as Cummulated_Vaccinated
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths` as deat
JOIN `beaming-pillar-381706.CovidProject.Covid_Vaccinations` as vacc
  ON deat.location = vacc.location
  and deat.date = vacc.date
WHERE deat.continent is not null
);

SELECT *, Cummulated_Vaccinated/population*100 as Cummulative_Percentage
FROM PercentPopulationVaccinated;


-- Percentage of Vaccinated People Location-wise (consolidated) - computing from the new column from the above table, using Common Table Expression (CTE) --

WITH
 CTEpopVSvac 
 AS (
  SELECT deat.continent as continent, deat.location as location, deat.population as population,vacc.new_vaccinations, SUM(cast(vacc.new_vaccinations as int)) OVER (PARTITION BY deat.location ORDER BY deat.location, deat.date) as Cummulated_Vaccinated
FROM `beaming-pillar-381706.CovidProject.Covid_Deaths` as deat
JOIN `beaming-pillar-381706.CovidProject.Covid_Vaccinations` as vacc
  ON deat.location = vacc.location
  and deat.date = vacc.date
WHERE deat.continent is not null
)
SELECT CTEpopVSvac.continent,CTEpopVSvac.location, MAX(Cummulated_Vaccinated/population)*100 as Cummulative_Percentage
FROM CTEpopVSvac
GROUP BY CTEpopVSvac.continent, CTEpopVSvac.location;


