/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

I will start by saying that this project took me several weeks as I encountered several problems:

Problem 1. MS SQL did not let me upload the excel files, I uninstalled the server, installed it, followed all the steps taken by other 
people that had this problem and still could not upload it.
What worked for me was to save the Excel files as CSV and upload it as a flat file but from the Tasks -> Import Data -> Flat File Source. 

This allowed me to finally upload the data.

Problem 2. When uploaded, all the data was as (varchar(50)) -> this caused me several problems when it came to calculations. 
I ended up changing that data type myself.


--Change of data type (I am aware you can use other ways, but this seemed easier to me as the time)

----CovidDeaths Table----

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

----CovidVaccinations Table----

--ALTER TABLE CovidVaccinations
--ALTER COLUMN date datetime

--ALTER TABLE CovidVaccinations
--ALTER COLUMN new_vaccinations float


-- Checking the tables were uploaded properly

Select *
From CovidDeaths
Order by 3,4

Select *
From CovidVaccinations
Order by 3,4


-- Select Data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Order by 1,2 

-- Looking at Total Cases vs Total Deaths
-- Shows the likelyhood of dying if you contract COVID in your country (I picked UK)
Select location, date, total_cases, total_deaths, (total_deaths / NULLIF(total_cases,0))*100 as DeathPercentage
From CovidDeaths
Where location like '%kingdom%'
Order by 1,2 


-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID
Select location, date, population, total_cases, (total_cases / population)*100 as PercentPopulationInfected
From CovidDeaths
Where location like '%kingdom%'
Order by 1,2 


-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by location, population
Order by PercentPopulationInfected desc

-- Showing countries with Highest Death Count per Population
Select Location, MAX(total_deaths) as TotalDeathCount
From CovidDeaths
Where continent is not null
Group by location
Order by TotalDeathCount desc

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing Continent with the Highest Death Count
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
