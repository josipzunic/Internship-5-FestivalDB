SELECT workshops.*, Festivals.DateOfStart FROM workshops
JOIN Festivals ON Workshops.FestivalId = Festivals.FestivalId
WHERE Workshops.difficulty = 'advanced'
AND EXTRACT(YEAR FROM Festivals.DateOfStart) = 2025

SELECT Performers.Name,  Festivals.Name, Stage.Name, Performances.StartTime, Performances.ExpectedAttendance FROM Performances
JOIN Performers ON Performances.PerformerId = Performers.PerformerId
JOIN Festivals ON Performances.FestivalId = Festivals.FestivalId
JOIN Stage ON Performances.StageId = Stage.StageId
WHERE Performances.ExpectedAttendance > 10000

SELECT Festivals.* FROM Festivals
WHERE EXTRACT(YEAR FROM Festivals.DateOfStart) = 2025

SELECT Workshops.* FROM Workshops
WHERE Workshops.Difficulty = 'advanced'

SELECT Workshops.* FROM Workshops
WHERE Workshops.Duration > INTERVAL '4'

SELECT Workshops.* FROM Workshops
WHERE Workshops.PriorKnowledgeNeeded = TRUE

SELECT Instructors.* FROM Instructors
WHERE Instructors.YearsOfExperience > 10

SELECT Instructors.* FROM Instructors
WHERE EXTRACT(YEAR FROM Instructors.DateOfBirth) < 1985

SELECT Atendees.* FROM Atendees
WHERE Atendees.City = 'Split'

SELECT Atendees.* FROM Atendees
WHERE Atendees.Email LIKE '%gmail.com'

SELECT Atendees.* FROM Atendees
WHERE -EXTRACT(YEAR FROM Atendees.DateOfBirth) + EXTRACT(YEAR FROM NOW()) < 25

SELECT Tickets.* FROM Tickets
WHERE Tickets.Price > 120

SELECT Tickets.* FROM Tickets
WHERE Tickets.TicketType = 'vipPass'

SELECT Tickets.* FROM Tickets
WHERE Tickets.TicketType = 'vipPass' OR Tickets.TicketType = 'festivalPass' OR Tickets.TicketType = 'campPass'

SELECT Staff.* FROM Staff
WHERE Staff.IsCertified = TRUE

