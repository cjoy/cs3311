# 1. In the context of database application development (aka "database engineering"), what are the aims of data modelling?

Data modelling is essentially an abstracted model of a database based on its requirements.
Data modelling aims to describe:
- attributes
- relationships
- constraints

# 2. Describe the similarities and differences between the following similarly-named concepts:
* relationship in the ODL (object definition language) object-oriented design language
- logical: abstract for conceptual design
- describes the association between objects in a pair of ODL classes

* relationship in the entity-relationship data model
- logical: abstract for conceptual design
- describes the relationship between n entities
- relationship set between two entity sets are similar

* relation in the relational data model
- physical: record-based, used for implementation

# 3. Why is the notion of a key not as important in the OO data model as it is in the ER and relational models?
- an OO data model has an OID that is assigned when the object is first assigned.
- ER and relational models usually don't have preassigned IDs, and must relay on an attribute to uniquely distinguish between them.

# 4. What kind of data, relationships and constraints exist in this scenario?
* Patients are identified by an SSN, and their names, addresses and ages must be recorded.
* Doctors are identified by an SSN. For each doctor, the name, specialty and years ofexperience must be recorded.
* Each pharmacy has a name, address and phone number. A pharmacy must have a manager.
* A pharmacist is identified by an SSN, he/she can only work for one pharmacy. For eachpharmacist, the name, qualification must be recorded.
* For each drug, the trade name and formula must be recorded.
* Every patient has a primary physician. Every doctor has at least one patient.
* Each pharmacy sells several drugs, and has a price for each. A drug could be sold at severalpharmacies, and the price could vary between pharmacies.
* Doctors prescribe drugs for patients. A doctor could prescribe one or more drugs for severalpatients, and a patient could obtain prescriptions from several doctors. Each prescription has adate and quantity associated with it

+ Data:
- patient: ssn, name, address, age, physician
- doctors: ssn, name, speciality, carrer_start (or years_of_experience)
- pharmacy: name, address, phone_number, manager
- pharmacist: ssn, name, pharmacy
- qualificiation: name, description, date, pharmacist
- pharma_drug: pharmacy, drug, price
- drug: name 
- prescription: drug, patient, doctor

+ Relationships:
- doctors treat patient
- doctors prescribe drugs to patients
- patients buy drugs
- drugs are sold in pharacies

+ Constrainsts:
- pharmacist can only work in one pharamacy
- every person has an unique ssn 
- doctor can treat one or more patient


# 5. What kind of data, relationships and constraints exist in this scenario?
* for each person, we need to record their tax file number (TFN), their real name, and their address
- everyone who earns money in Australia has a distinct tax file number
* authors write books, and may publish books using a ``pen-name'' (a name which appears as the author of the book and is different to their real name)
* editors ensure that books are written in a manner that is suitable for publication
* every editor works for just one publisher
* editors and authors have quite different skills; someone who is an editor cannot be an author, and vice versa
* a book may have several authors, just one author, or no authors (published anonymously)
* every book has one editor assigned to it, who liaises with the author(s) in getting the book ready for publication
* each book has a title, and an edition number (e.g. 1st, 2nd, 3rd)
* each published book is assigned a unique 13-digit number (its ISBN); 
* different editions of the same book will have different ISBNs
* publishers are companies that publish (market/distribute) books
* each publisher is required to have a unique Australian business number (ABN)
* a publisher also has a name and address that need to be recorded
* a particular edition of a book is published by exactly one publisher

+ Data:
- person: tfn, name, address
- author: pen_name, person
- book: title, editor_number, publisher, isbn, published(boolean)
- editor: publisher, name
- publisher: abn, address, name

+ Relationships:
- one author can publish many books
- every author is a person
- each edition of a particular book has one publisher

+ Constraints:
- people have unique tfns (primary key)
- authors have one pen name and are real people
- editors can't be authors
- published books have unique isbn's (regardless of the edition number)

#6. Consider some typical operations in the myUNSW system ...
* student enrols in a lab class
* student enrols in a course
* system prints a student transcript

For each of these operations:
a. identify what data items are required
b. consider relationships between these data items
c. consider constraints on the data and relationships

* student enrols in a lab class
+ data: 
 - student: id, name, etc...
 - lab_enrolment: student, lab
 - lab: time, instructure, course, location
+ relationships:
 - student can enrol in 0 or many labs
 - lab_enrolment represents only one lab
+ constraints
 - students can only enrol in one lab for one course

# 7. Researchers work on different research projects, and the connection between them can be modelled by a WorksOn relationship. Consider the following two different ER diagrams to represent this situation.

a) 
- Many researchers (staff members) can work one or many projects
- When a rsearcher works on a project, time is recorded.

# 8. Consider the following ODL definition to describe researchers working on and managing researchprojects:
```
iterface Researcher {
    attribute string name;
    attribute int staffNumber;
    relationship Project worksOn inverse Project::workers;
    relationship Project manages inverse Project::managedBy;   
};   

interface Project {
    attribute real number;
    attribute string commander;
    relationship Set<Researcher> workers inverse Researcher::worksOn;
    relationship Researcher managedBy inverse Researcher::manages;
};
```
This definition is based on the assumption that each researcher only works on one project, that aresearcher manages at most one project, and that each project has only one manager.
Show how this definition would change if:

+ each researcher's title (e.g. Dr.) is included
 - attribute 'title' is added to Researcher
+ people's names are broken into separate family and given names
 - name is a composite attribute, being split into family name and given name
+ each project has a total budget allocation to be recorded
 - attribute 'budget' is added onto the Project interface
+ a researcher is allowed to be work on more than one project
 - relationship Project manages inverse Rsearcher:WorksOn
+ a project may have several managers

# 9. Show how you would represent the following OO classes as ER entities with their corresponding attributes:

# 10. Show how you would represent each relationship from the following ODL model in an ER model:

# 11. Draw an ER diagram for the following application from the manufacturing industry:

# 12. The following two ER diagrams give alternative design choices for associating a person with theirfavourite types of food. Explain when you might choose to use the second rather than the first:

# 13. Consider a relationship Teaches between teachers and courses. For each situation described below, give an ER diagram that accurately models that situation:

a. Teachers may teach the same course in several semesters, and each must be recorded
b. Teachers may teach the same course in several semesters, but only the current offering needsto be recorded (assume this in the following parts)
c. Every teacher must teach some coursed.
d. Every teacher teaches exactly one coursee.
e. Every teacher teaches exactly one course, and every course must be taught by some teacher
f. A course may be taught jointly by a team of teachers. 

You may assume that the only attribute of interest for teachers is their staff number while for coursesit is the course code (e.g. COMP3311). You may introduce any new attributes, entities and relationships that you think are necessary.

# 14. Assume there is a Person entity type. Each person has a home address. More than one person canlive at the same home address.
a. Create two, different ER diagrams to depict Persons and their addresses, one with Addressas an attribute, the other with Address as an entity.

b. Why would we choose one rather than the other?

c. Assume that we have a Electric Company entity type. Only one of these companiessupplies power to each home address. Add that information to each ER diagram.

# 15. Give an ODL design for a database recording information about teams, players,and their fans, including:
a. For each team, its name, its players, its captain (one of its players) and the colours of its uniform.

b. For each player, their name and team.

c. For each fan, their name, favourite teams, favourite players, and favourite colour.

# 16. Repeat the previous question, but produce an ER design instead.


# 17. 
A trucking company called "Truckers" is responsible for picking up shipments from the warehousesof a retail chain called "Maze Brothers" and delivering the shipments to individual retail storelocations of "Maze Brothers". Currently there are 6 warehouse locations and 45 "Maze Brothers"retail stores. A truck may carry several shipments during a single trip, which is identified by a Trip#,and delivers those shipments to multiple stores. Each shipment is identified by a Shipment# andincludes data on shipment volume, weight, destination, etc. Trucks have different capacities for boththe volumes they can hold and the weights they can carry. The "Truckers" company currently has150 trucks, and a truck makes 3 to 4 trips each week. A database - to be used by both "Truckers"and "Maze Brothers" - is being designed to keep track of truck usage and deliveries and to help inscheduling trucks to provide timely deliveries to the stores.

Design an ER model for the above application. State all assumptions.

# 18.
Give an ODL design for a University administration database that records information aboutfaculties, schools, lecturers, students, courses, classes, buildings, rooms, marks. The model needsto include:
a. for each faculty, its name, its schools and its dean
b. for each school, its name, the location of its school office, its head and its academic staff
c. for each lecturer, their names, bithdate, position, staff number, school, office, the courses theyhave convened, and the classes they have run
d. for each student, their names, birthdate, student number, degree enrolled in, courses studied,and marks for each course
e. for each course, its code, its name, the session it was offered, its lecturer(s), its students, itsclasses
f. for each class, what kind of class (lecture, tutorial, lab class, ...), its day and time (starting andfinishing), who teaches it, which students attend it, where it's held
g. for each building, its name and map reference
h. for each room, its name, its capacity, type of room (office, lecture theatre, tutorial room,laboratory, ...) and the building where it is located

An assumption: staff and student numbers are unique over the union of the sets of staff and studentnumbers (i.e. each person has a unique identifying number within the University).

Another assumption: the lecturer who "convenes" a course would be called "lecturer-in-charge" atUNSW; lecturers typically teach classes in the courses they convene; they may also teach classes inother courses; a given class is only taught by one lecturer.State all other assumptions

# 19. Repeat the previous question, but produce an ER design instead.

# 20. Give an ER design to model the following scenario ...
- Patients are identified by an SSN, and their names, addresses and ages must be recorded.
- Doctors are identified by an SSN. For each doctor, the name, specialty and years ofexperience must be recorded.
- Each pharmacy has a name, address and phone number. A pharmacy must have a manager.
- A pharmacist is identified by an SSN, he/she can only work for one pharmacy. For eachpharmacist, the name, qualification must be recorded.
- For each drug, the trade name and formula must be recorded.
Every patient has a primary physician. Every doctor has at least one patient.
- Each pharmacy sells several drugs, and has a price for each. A drug could be sold at severalpharmacies, and the price could vary between pharmacies.
- Doctors prescribe drugs for patients. A doctor could prescribe one or more drugs for severalpatients, and a patient could obtain prescriptions from several doctors. Each prescription has adate and quantity associated with it.

State all assumptions used in developing your data model.

# 21. Give an ER design to model the following scenario ...
- for each person, we need to record their tax file number (TFN), their real name, and their address.
- everyone who earns money in Australia has a distinct tax file number
- authors write books, and may publish books using a ``pen-name'' (a name which appears asthe author of the book and is different to their real name)
- editors ensure that books are written in a manner that is 
- every editor works for just one publisher
- editors and authors have quite different skills; someone who is an editor cannot be an author,and vice versa
- a book may have several authors, just one author, or no authors 
- every book has one editor assigned to it, who liaises with the author(s) in getting the bookready for publication
- each book has a title, and an edition number (e.g. 1st, 2nd, 3rd)
- each published book is assigned a unique 13-digit number (its ISBN); different editions of thesame book will have different ISBNs
- publishers are companies that publish (market/distribute) books
- each publisher is required to have a unique Australian business number (ABN)
- a publisher also has a name and address that need to be recorded
- a particular edition of a book is published by exactly one publisher

State all assumptions used in developing your data model.

# 22. Give an ER design to model the following scenario ...
- a driver has an employee id, a name and a birthday
- a bus has a make, model, registration number and capacity
- a bus may also have features (e.g. air-conditioned, disabled access, video screens, etc.)
- a bus-stop (normally abbreviated to simply stop) is a defined place where a bus may stop topick up or set down passengers
- each stop has a name, which is displayed on the timetable (e.g. ``Central Station'')
- each stop also has a location (street address) (e.g. ``North side of Eddy Avenue'')
- a route describes a sequence of one or more stops that a bus will follow
- each route has a number (e.g. route 372, from Coogee to Circular Quay)
- each route has a direction: ``inbound'' or ``outbound'' (e.g. 372 Coogee to Circular Quay is ``inbound'', 372 Circular Quay to Coogee is ``outbound'')
- for each stop on a route, we note how long it should take to reach that stop from the first stop
- the time-to-reach the first stop on a route is zero
- stops may be used on several routes; some stops may not (currently) be used on any route
- a schedule specifies an instance of a route (e.g. the 372 departing Circular Quay at 10:05am)
- schedules are used to produce the timetables displayed on bus-stops
- a service denotes a specific bus running on a specific schedule on a particular day with aparticular driver
- services are used internally by the bus company to keep track of bus/driver allocations
- the number of minutes that each bus service arrives late at its final stop needs to be recorded

State all assumptions used in developing your data model.