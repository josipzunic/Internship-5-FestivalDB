CREATE TYPE status AS ENUM ('planned', 'active', 'completed');
ALTER TYPE status RENAME VALUE 'planiran' TO 'planned';
ALTER TYPE status RENAME VALUE 'aktivan' TO 'active';
ALTER TYPE status RENAME VALUE 'završen' TO 'completed';

CREATE TABLE Festivals (
	FestivalId SERIAL PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	City VARCHAR(100) NOT NULL,
	Capacity INT NOT NULL,
	DateOfStart TIMESTAMP NOT NULL,
	DateOfEnd TIMESTAMP NOT NULL,
	Status status NOT NULL,
	HasCamp BOOLEAN DEFAULT FALSE
);

CREATE TYPE location AS ENUM ('main', 'forest', 'beach');

CREATE TABLE Stage (
	StageId SERIAL PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	Location location NOT NULL,
	MaxPeopleFirstRows INT NOT NULL,
	Covered BOOLEAN NOT NULL,
	FestivalId INT NOT NULL,
	FOREIGN KEY (FestivalId) REFERENCES Festivals(FestivalId)
);

CREATE TYPE performer AS ENUM ('bend', 'DJ', 'soloist');

CREATE TABLE Performers (
	PerformerId SERIAL PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	Country VARCHAR(100) NOT NULL,
	Genre VARCHAR(100) NOT NULL,
	MembersCount INT DEFAULT 1,
	PerformerType performer,
	IsActive BOOLEAN DEFAULT TRUE
);





