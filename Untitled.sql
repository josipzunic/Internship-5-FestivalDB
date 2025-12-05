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
DROP CONSTRAINT "startvsendtime";

ALTER TABLE Festivals
	ADD CONSTRAINT StartVsEndTime
	CHECK(DateOfStart < DateOfEnd)

ALTER TABLE Festivals
	ADD CONSTRAINT NegativeCapacity
	CHECK(Capacity > 0)



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

ALTER TABLE Performers
	ADD CONSTRAINT NegativePerformers
	CHECK(MembersCount > 0)

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
DROP CONSTRAINT "startvsendtime";

ALTER TABLE Performances
	ADD CONSTRAINT StartVsEndTime
	CHECK(StartTime < EndTime)

CREATE OR REPLACE FUNCTION checkFrontRowOccupation()
RETURNS TRIGGER AS $$
DECLARE 
	maxInFirstRow INT;
BEGIN
	SELECT MaxPeopleFirstRows
	INTO maxInFirstRow
	FROM Stage
	WHERE StageId = NEW.StageId;
	IF NEW.ExpectedAttendance < 0 OR NEW.ExpectedAttendance > maxInFirstRow THEN
		return NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER preventFrontRowOverfilling
BEFORE INSERT OR UPDATE ON PERFORMANCES
FOR EACH ROW
EXECUTE FUNCTION checkFrontRowOccupation()
	
	

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

CREATE TABLE Tickets (
	TicketId SERIAL PRIMARY KEY,
	TicketType ticketType NOT NULL,
	TicketDescriptionId INT NOT NULL REFERENCES TicketDescriptions(TicketDescriptionId),
	FestivalId INT NOT NULL REFERENCES Festivals(FestivalId)
);

CREATE TABLE TicketValidities (
	TicketId INT NOT NULL REFERENCES Tickets(TicketId),
	ValidDate DATE,
	PRIMARY KEY (TicketId, ValidDate)
);


ALTER TABLE Tickets
ADD COLUMN Price NUMERIC(10,2) NOT NULL;

ALTER TABLE Tickets
	ADD CONSTRAINT NegativePrice
	CHECK(Price >= 0)

CREATE TABLE Atendees (
	AtendeeId SERIAL PRIMARY KEY,
	Name VARCHAR(50) NOT NULL,
	Surname VARCHAR(50) NOT NULL,
	DateOfBirth TIMESTAMP NOT NULL,
	City VARCHAR(50) NOT NULL,
	Email VARCHAR(100) NOT NULL,
	Country VARCHAR(50) NOT NULL
);

ALTER TABLE Atendees
	ADD CONSTRAINT ValidDateOfBirth
	CHECK (DateOfBirth <= CURRENT_DATE)

ALTER TABLE Atendees
	ADD UNIQUE (Email);

CREATE TABLE Purchases (
	AtendeeId INT NOT NULL REFERENCES Atendees(AtendeeId),
	FestivalId INT NOT NULL REFERENCES Festivals(FestivalId),
	PurchaseDate TIMESTAMP NOT NULL DEFAULT NOW(),
	PurchaseId SERIAL PRIMARY KEY
);

CREATE TABLE PurchasedItems (
	PurchasedItemId SERIAL PRIMARY KEY,
	PurchaseId INT NOT NULL REFERENCES Purchases(PurchaseId),
	TicketId INT NOT NULL REFERENCES Tickets(TicketId),
	Quantity INT NOT NULL
);

ALTER TABLE PurchasedItems
	ADD CONSTRAINT NegativeQuantity
	CHECK (Quantity >= 0)

CREATE TYPE difficulty as ENUM ('beginner', 'intermediate', 'advanced');

CREATE TABLE WorkshopDescriptions (
	WorkshopDescriptionId SERIAL PRIMARY KEY,
	WorkshopDescription VARCHAR(100) NOT NULL
);

CREATE TABLE Workshops (
	WorkshopDescriptionId INT NOT NULL REFERENCES WorkshopDescriptions(WorkshopDescriptionId),
	WorkshopId SERIAL PRIMARY KEY,
	FestivalId INT NOT NULL REFERENCES Festivals(FestivalId),
	Name VARCHAR(50) NOT NULL,
	Difficulty difficulty NOT NULL,
	Capacity INT NOT NULL,
	PriorKnowledgeNeeded BOOLEAN DEFAULT FALSE,
	Duration INTERVAL NOT NULL
);

ALTER TABLE Workshops
	ADD CONSTRAINT WorkshopCapacity
	CHECK (Capacity > 0)

ALTER TABLE Workshops
	ADD CONSTRAINT WorkshopDuration
	CHECK (Duration > INTERVAL '0')

CREATE TABLE Instructors (
	InstructorId SERIAL PRIMARY KEY,
	Name VARCHAR(100),
	Surname VARCHAR(100),
	DateOfBirth TIMESTAMP,
	WorkshopDescription INT NOT NULL REFERENCES WorkshopDescriptions(WorkshopDescriptionId),
	YearsOfExperience INT NOT NULL
);


ALTER TABLE Instructors
	ADD CONSTRAINT InstructorUnderage
	CHECK(EXTRACT(YEAR FROM AGE(CURRENT_DATE, DateOfBirth)) >= 18)

ALTER TABLE Instructors
	ADD CONSTRAINT InstructorInexperienced
	CHECK(YearsOfExperience >= 2)

CREATE TYPE applicationStatus AS ENUM ('applied', 'cancelled', 'attended');

CREATE TABLE WorkshopApplications (
	AtendeeId INT NOT NULL REFERENCES Atendees(AtendeeId),
	WorkshopId INT NOT NULL REFERENCES Workshops(WorkshopId),
	ApplicationStatus applicationStatus NOT NULL,
	TimeOfApplication TIMESTAMP NOT NULL,
	UNIQUE (AtendeeId, WorkshopId)
);

CREATE TABLE StaffJobs (
	StaffJobId SERIAL PRIMARY KEY,
	StaffJobDescription VARCHAR(50) NOT NULL
);

CREATE TABLE Staff (
	StaffId SERIAL PRIMARY KEY,
	StaffJobId INT NOT NULL REFERENCES StaffJobs(StaffJobId),
	FestivalId INT NOT NULL REFERENCES Festivals(FestivalId),
	Name VARCHAR(100) NOT NULL,
	Surname VARCHAR(100) NOT NULL,
	DateOfBirth TIMESTAMP NOT NULL,
	ContactPhone VARCHAR(100) NOT NULL,
	IsCertified BOOLEAN DEFAULT FALSE
);

ALTER TABLE Staff
	ADD CONSTRAINT StaffUnderage
	CHECK(EXTRACT(YEAR FROM AGE(CURRENT_DATE, DateOfBirth)) >= 21)

CREATE TYPE validityStatus AS ENUM ('active', 'expired');

CREATE TABLE MembershipCardHolders (
	MembershipCardHolderId SERIAL PRIMARY KEY,
	AtendeeId INT NOT NULL REFERENCES Atendees(AtendeeId),
	Status validityStatus NOT NULL
);

CREATE OR REPLACE FUNCTION checkMembershipCardCondition()
RETURNS TRIGGER AS $$
DECLARE
	totalSpent NUMERIC;
	festivalCount INT;
BEGIN 
	SELECT 
		SUM (PurchasedItems.Quantity*Tickets.Price),
		COUNT (DISTINCT Purchases.FestivalId)
	INTO totalSpent, festivalCount
	FROM Purchases 
	JOIN PurchasedItems ON Purchases.PurchaseId = PurchasedItems.PurchaseId
	JOIN Tickets ON PurchasedItems.TicketId = Tickets.TicketId
	WHERE Purchases.AtendeeId = NEW.AtendeeId;
	IF COALESCE(totalSpent,0) <= 600 OR festivalCount <= 3
		THEN RETURN NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER membership_card_check
BEFORE INSERT ON MembershipCardHolders
FOR EACH ROW
EXECUTE FUNCTION checkMembershipCardCondition();
		

