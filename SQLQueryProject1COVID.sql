---Change date type to the right date type for this project here instead of during the other commands
----CovidDeaths Table

--ALTER TABLE CovidDeaths
--ALTER COLUMN total_deaths float

--ALTER TABLE CovidDeaths
--ALTER COLUMN new_deaths float

--ALTER TABLE CovidDeaths
--ALTER COLUMN total_cases float

--ALTER TABLE CovidDeaths
--ALTER COLUMN new_cases float

--ALTER TABLE CovidDeaths
--ALTER COLUMN population numeric

--ALTER TABLE CovidDeaths
--ALTER COLUMN date datetime

----CovidVaccinations Table

--ALTER TABLE CovidVaccinations
--ALTER COLUMN date datetime

ALTER TABLE CovidVaccinations
ALTER COLUMN new_vaccinations float

--SELECT location, date, total_cases, total_deaths, (total_deaths/NULLIF(total_cases,0))*100 as DeathPercentage
--FROM CovidDeaths
--Order by 1,2

--Select *
--From CovidDeaths
--Order by 3,4

--Select *
--From CovidVaccinations
--Order by 3,4


-- Select Data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Order by 1,2 

-- Looking at Total Cases vs Total Deaths
-- Shows the likelyhood of dying if you contract covid in your country
Select location, date, total_cases, total_deaths, (total_deaths / NULLIF(total_cases,0))*100 as DeathPercentage
From CovidDeaths
Where location like '%kingdom%'
Order by 1,2 


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
Select location, date, population, total_cases, (total_cases / population)*100 as PercentPopulationInfected
From CovidDeaths
Where location like '%kingdom%'
Order by 1,2 


-- Countries with highest infection rate compared to population
Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by location, population
Order by PercentPopulationInfected desc

-- Showing countries with highest death count per population
Select Location, MAX(total_deaths) as TotalDeathCount
From CovidDeaths
Where continent is not null
Group by location
Order by TotalDeathCount desc

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing continent with the highest death count
Select continent, MAX(total_deaths) as TotalDeathCount
From CovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 as DeathPercentage
From CovidDeaths
Where continent is not null
--Group by date
Order by 1,2 


--Looking at Total Population vs Vaccinations

--Select *
--From CovidDeaths dea
--Join CovidVaccinations vac
--ON dea.location = vac.location
--and dea.date = vac.date

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
 ON dea.location = vac.location
 and dea.date = vac.date
Where dea.continent is not null
Order by 2,3

-- USE CTE

With PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
 ON dea.location = vac.location
 and dea.date = vac.date
Where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

--TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
 ON dea.location = vac.location
 and dea.date = vac.date
Where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


--Creating View to store data for later visualisations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
 ON dea.location = vac.location
 and dea.date = vac.date
Where dea.continent is not null
