CREATE TYPE status AS ENUM ('planned', 'active', 'completed');
CREATE TYPE location AS ENUM ('main', 'forest', 'beach');
CREATE TYPE performer AS ENUM ('bend', 'DJ', 'soloist');
CREATE TYPE ticketType AS ENUM ('dayPass', 'festivalPass', 'campPass', 'vipPass');
CREATE TYPE difficulty as ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE applicationStatus AS ENUM ('applied', 'cancelled', 'attended');
CREATE TYPE validityStatus AS ENUM ('active', 'expired');


CREATE TABLE Festivals (
	FestivalId SERIAL PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	City VARCHAR(100) NOT NULL,
	Capacity INT NOT NULL,
	Status status NOT NULL,
	HasCamp BOOLEAN DEFAULT FALSE,
    DateOfStart TIMESTAMP NOT NULL,
	DateOfEnd TIMESTAMP NOT NULL,
	CHECK(DateOfStart < DateOfEnd),
	CHECK(Capacity > 0)
);
	
CREATE TABLE Stage (
	StageId SERIAL PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	Location location NOT NULL,
	MaxPeopleFirstRows INT NOT NULL,
	Covered BOOLEAN NOT NULL,
	FestivalId INT NOT NULL REFERENCES Festivals(FestivalId)
);


CREATE TABLE Performers (
	PerformerId SERIAL PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	Country VARCHAR(100) NOT NULL,
	Genre VARCHAR(100) NOT NULL,
	MembersCount INT DEFAULT 1,
	PerformerType performer,
	IsActive BOOLEAN DEFAULT TRUE,
	CHECK(MembersCount > 0)
);
	

CREATE TABLE Performances (
	PerformanceId SERIAL PRIMARY KEY,
	StartTime TIMESTAMP NOT NULL,
	EndTime TIMESTAMP NOT NULL,
	ExpectedAttendance INT NOT NULL,
	FestivalId INT NOT NULL REFERENCES Festivals(FestivalId),
    StageId INT NOT NULL REFERENCES Stage(StageId),
    PerformerId INT NOT NULL REFERENCES Performers(PerformerId),
	CHECK(StartTime < EndTime)
);
	
CREATE OR REPLACE FUNCTION checkStagePerformanceOverlap()
RETURNS TRIGGER AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Festivals f
        JOIN Stage s ON s.FestivalId = f.FestivalId
        WHERE s.StageId = NEW.StageId
            AND NEW.StartTime >= f.DateOfStart::timestamp
            AND NEW.EndTime <= (f.DateOfEnd::timestamp + INTERVAL '1 day') 
    ) THEN
        RAISE EXCEPTION 'Performance times (% to %) are outside the festival dates for Stage %', 
            NEW.StartTime, NEW.EndTime, NEW.StageId;
    END IF;
    

    IF EXISTS (
        SELECT 1
        FROM Performances
        WHERE StageId = NEW.StageId
            AND PerformanceId != COALESCE(NEW.PerformanceId, -1) 
            AND (
                (NEW.StartTime >= StartTime AND NEW.StartTime < EndTime) OR
                (NEW.EndTime > StartTime AND NEW.EndTime <= EndTime) OR
                (NEW.StartTime <= StartTime AND NEW.EndTime >= EndTime)
            )
    ) THEN
        RAISE EXCEPTION 'Performance on Stage % from % to % overlaps with an existing performance', 
            NEW.StageId, NEW.StartTime, NEW.EndTime;
    END IF;
    

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER prevenetPerformaceOverlap
BEFORE INSERT OR UPDATE ON PERFORMANCES
FOR EACH ROW
EXECUTE FUNCTION checkStagePerformanceOverlap();

CREATE TABLE Tickets (
	TicketId SERIAL PRIMARY KEY,
	TicketType ticketType NOT NULL,
	FestivalId INT NOT NULL REFERENCES Festivals(FestivalId),
    Price NUMERIC(10,2) NOT NULL,
    TicketDescription VARCHAR(100) NOT NULL,
	CHECK(Price >= 0)
);
	
CREATE TABLE Atendees (
	AtendeeId SERIAL PRIMARY KEY,
	Name VARCHAR(50) NOT NULL,
	Surname VARCHAR(50) NOT NULL,
	DateOfBirth TIMESTAMP NOT NULL,
	City VARCHAR(50) NOT NULL,
	Email VARCHAR(100) NOT NULL,
	Country VARCHAR(50) NOT NULL,
	CHECK (DateOfBirth <= CURRENT_DATE),
	UNIQUE (Email)
);

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
	Quantity INT NOT NULL,
	CHECK (Quantity >= 0)
);

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
	Duration INTERVAL NOT NULL,
	CHECK (Capacity > 0)
);
	
CREATE TABLE Instructors (
	InstructorId SERIAL PRIMARY KEY,
	Name VARCHAR(100),
	Surname VARCHAR(100),
	DateOfBirth TIMESTAMP,
	WorkshopDescription INT NOT NULL REFERENCES WorkshopDescriptions(WorkshopDescriptionId),
	YearsOfExperience INT NOT NULL,
	CHECK(EXTRACT(YEAR FROM AGE(CURRENT_DATE, DateOfBirth)) >= 18),
	CHECK(YearsOfExperience >= 2)
);
	
CREATE TABLE WorkshopApplications (
	AtendeeId INT NOT NULL REFERENCES Atendees(AtendeeId),
	WorkshopId INT NOT NULL REFERENCES Workshops(WorkshopId),
	ApplicationStatus applicationStatus NOT NULL,
	TimeOfApplication TIMESTAMP NOT NULL,
	WorkshopApplicationId SERIAL PRIMARY KEY
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
	IsCertified BOOLEAN DEFAULT FALSE,
	CHECK(EXTRACT(YEAR FROM AGE(CURRENT_DATE, DateOfBirth)) >= 21)
);

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