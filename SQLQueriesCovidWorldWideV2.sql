SELECT *
FROM CovidDeaths
WHERE continent is not null
ORDER BY 3, 4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3, 4

--Select the data that I am going the be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2


-- Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1

-- There is an error because the datatype of total_cases seem to be nvarchar. The following query will
-- findout exactly the datatype of the two columns we need

SELECT 
    COLUMN_NAME, 
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'CovidDeaths'
AND COLUMN_NAME = 'total_deaths';
--AND COLUMN_NAME = 'total_cases';     -- in deed those columns are nvarchar. we need to change the datatype

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases FLOAT;

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths FLOAT;

ALTER TABLE CovidDeaths
ALTER COLUMN population FLOAT

-- after altering the datatypes we run the query again: 

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location 
ORDER BY 1,2


--Looking at Total Cases vs Total Deaths
--This shows the likelihood of dying if you contract covid in your country. 
--For Colombia it is about 2.25 percent of change of dying from covid.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%Colombia%' 
ORDER BY 1,2


-- Looking at the Total Cases vs the Population 
--This shows what percentage of the population got Covid per country
SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentageInfectedPopulation
FROM PortfolioProject..CovidDeaths
WHERE location like '%States%' 
ORDER BY 1,2


--Looking at countries with highest infection rate compared to population

SELECT location, population, MAX (total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 as PercentageInfectedPopulation
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentageInfectedPopulation DESC


-- Showing the countries with the highest death count per pupulation
SELECT location, 
	MAX (cast(total_deaths AS INT)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC;


--Let´s break things down by continent

--Showing continents with the highest death count per population

SELECT continent, 
	MAX (cast(total_deaths AS INT)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- DEATHPERCENTAGE OF POPULATION BY COUNTRY --THIS IS NOT PART OF THE TUTORIAL

Select location, population, MAX(((total_deaths/population)*100)) as DeathPercentage
FROM CovidDeaths
GROUP BY location, population
ORDER BY DeathPercentage DESC

-- DEATHPERCENTAGE OF POPULATION WORLDWIDE    --THIS IS NOT PART OF THE TUTORIAL
SELECT location, population, 
(SUM(cast(new_deaths as float))/population)*100 as PercentageOfDeathsInTheWorld
FROM PortfolioProject..CovidDeaths
WHERE location = 'World'
GROUP BY location, population

--Total Global numbers per day

SELECT date, SUM(cast(new_cases as float)) as total_cases, SUM(cast(new_deaths as float)) as total_deaths, 
SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 AS Death_percentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


--Total number of cases and deaths uptodate  -- THIS IS A SUGGESTION FROM THE TUTORIAL

SELECT SUM(cast(new_cases as float)) as total_cases, SUM(cast(new_deaths as float)) as total_deaths, 
SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 AS Death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


--NOW WE´RE GONNA WORK WITH THE VACCINATION TABLE

--we found a problem with the data type that was solved by changing the data type in excel and importing the
--dataset again in ssms. For verification purposes I wrote this code:
SELECT location, new_vaccinations, people_vaccinated
FROM PortfolioProject..CovidVaccinations
WHERE new_vaccinations IS NOT NULL
ORDER BY location
-------and I found the new_vaccinations column is not filled with nulls anymore



--Looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,  SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,  
  dea.date) as RollingPeopleVaccinated
--,  (RollingPeopleVaccinated/population)*100  if I do this I will get an error, then the solution will be a 
--    temptable or CTE. explained down
FROM PortfolioProject..CovidDeaths as dea
	JOIN PortfolioProject..CovidVaccinations as vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3


--now we wanna look at the total population vs the vaccination, but we cant´t devide

with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,  SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,  
  dea.date) as RollingPeopleVaccinated
--,  (RollingPeopleVaccinated/population)*100  if I do this I will get an error, then the solution will be a 
--    temptable or CTE. explained down
FROM PortfolioProject..CovidDeaths as dea
	JOIN PortfolioProject..CovidVaccinations as vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac



--TEMP TABLE:  this is the same thing above but with a temp table instead of a CTE
DROP table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,  SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,  
  dea.date) as RollingPeopleVaccinated
--,  (RollingPeopleVaccinated/population)*100  if I do this I will get an error, then the solution will be a 
--    temptable or CTE. explained down
FROM PortfolioProject..CovidDeaths as dea
	JOIN PortfolioProject..CovidVaccinations as vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated





-- Creating View to store data for later visualizations 
DROP view if exists PercentPopulationVaccinated
Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,  SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,  
  dea.date) as RollingPeopleVaccinated
--,  (RollingPeopleVaccinated/population)*100  if I do this I will get an error, then the solution will be a 
--    temptable or CTE. explained down
FROM PortfolioProject..CovidDeaths as dea
	JOIN PortfolioProject..CovidVaccinations as vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3


select *
from PercentPopulationVaccinated