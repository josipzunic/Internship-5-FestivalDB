Basic database for tracking festivals. <br />
Folder csv contains csv files with data for the database. <br />
Data is imported in pgAdmin 4 by right clicking on the table we want to add data to and choosing the "Import/Export data" option from the dropdown menu <\br>
Data should be imported in a specific order: <br />
1. Festivals <br />
2. WorkshopDescriptions <br />
3. StaffJobs <br />
4. Performers <br />
5. Instructors <br />
6. Stage <br />
7. Tickets <br />
8. Performances <br />
9. Atendees <br />
10. Purchases <br />
11. PurchasedItems <br />
12. Workshops <br />
13. WorkshopApplications <br />
14. Staff <br />
15. MembershipCardHolders <br />
The file tables.sql contains the tables used during development of the database while the file cleanTables.sql contains the clean version to be used when testing the code. Code from
cleanTables.sql was tested and should be able to be ran all at once. <br />
The file queries.sql contains the queries that needed to be checked. Two queries, the ones that check for attendees from Split and attendees with email ending with gmail.com
will display nothing before inserting attendees that match those requirements. The file insert.sql contains script for adding those attendees since mockaroo couldn't generate those. 
I suggest adding those attendees after populating the database since that was the tested version.
