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
	HasCamp BOOLEAN DEFAULT FALSE,
	CHECK(DateOfStart < DateOfEnd)
);

SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'festivals'::regclass;

ALTER TABLE Festivals
DROP CONSTRAINT "festivals_pkey";

ALTER TABLE Festivals
	ADD CONSTRAINT StartVsEndTime
	CHECK(DateOfStart < DateOfEnd)

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

CREATE TABLE Performances (
	PerformanceId SERIAL PRIMARY KEY,
	StartTime TIMESTAMP NOT NULL,
	EndTime TIMESTAMP NOT NULL,
	ExpectedAttendance INT NOT NULL,
	FestivalId INT NOT NULL,
	StageId INT NOT NULL,
	PerformerId INT NOT NULL,
	FOREIGN KEY (FestivalId) REFERENCES Festivals(FestivalId),
	FOREIGN KEY (StageId) REFERENCES Stage(StageId),
	FOREIGN KEY (PerformerId) REFERENCES Performers(PerformerId)
);


ALTER TABLE Performances
	ADD CONSTRAINT StartVsEndTime
	CHECK(StartTime < EndTime)

CREATE OR REPLACE FUNCTION checkStagePerformanceOverlap()
RETURNS TRIGGER AS $$
BEGIN
	IF EXISTS (
		SELECT 1
		FROM Performances
		WHERE StageId = NEW.StageId
			AND (
				NEW.StartTime >= StartTime AND NEW.StartTime < EndTime OR
				NEW.EndTime > StartTime AND NEW.EndTime <= EndTime OR
				NEW.StartTime <= StartTime AND NEW.EndTime >= EndTime
			)
		) THEN
			RAISE EXCEPTION 'Preklapanje nastupa na istoj pozornici';
		END IF;
		RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevenetPerformaceOverlap
BEFORE INSERT OR UPDATE ON PERFORMANCES
FOR EACH ROW
EXECUTE FUNCTION checkStagePerformanceOverlap()

CREATE TYPE ticketType AS ENUM ('dayPass', 'festivalPass', 'campPass', 'vipPass');

CREATE TABLE TicketDescriptions (
	TicketDescriptionId SERIAL PRIMARY KEY,
	Description VARCHAR(100) NOT NULL
);

CREATE TABLE TicketValidities (
	TicketId INT NOT NULL REFERENCES Tickets(TicketId),
	ValidDate DATE,
	PRIMARY KEY (TicketId, ValidDate)
);

CREATE TABLE Tickets (
	TicketId SERIAL PRIMARY KEY,
	TicketType ticketType NOT NULL,
	TicketDescriptionId INT NOT NULL REFERENCES TicketDescriptions(TicketDescriptionId),
	FestivalId INT NOT NULL REFERENCES Festivals(FestivalId)
);


