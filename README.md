# ticket-management-system
# Public Transport Ticket Management System implementation with Oracle PL/SQL

Advanced Database Systems with Applications  
 \[DSCI 32012\] 

Assignment I Group ID : CS\_G10

Group Members: 

1. CS/2020/011 		Pawan Gunawardhana      
2. CS/2020/033		Tharindu Damruwan    
1. **Business Scenario**

Sri Lanka’s public transport network, including both bus and railway services, is a backbone for the country's daily commuting. However, the current system largely relies on manual ticketing, paper logs, and static schedules, leading to several operational drawbacks such as overcrowding, ticket fraud, and lack of real-time service visibility.

To address these issues, the **Public Transport Ticket Management System** was developed as a unified platform that leverages a structured relational database to modernize and automate the process. At the core of this system is a schema consisting of key entities such as *Passenger, Vehicle, Transport\_Route, Schedule, Ticket,* and *Payment.*

* *Passengers* can register with their details and book seats for any scheduled route.  
* Each *Vehicle* (bus or train) is assigned a specific *Transport\_Route* and linked to multiple travel *Schedules*.  
* The *Schedule* table manages timing, fare, and route allocation, ensuring up-to-date and accurate travel plans.  
* Through the *Ticket* table, bookings are recorded with seat numbers, travel dates, and confirmation statuses.  
* The *Payment* table logs associated payments, enabling secure and trackable financial transactions.

This ER-based structure facilitates real-time seat allocation, travel tracking, and booking status monitoring. Administrators can generate route-based or city-based analytics, monitor vehicle utilization, and enforce policies using database-level triggers and business logic.  
Our Public Transport Ticket Management System database has been deployed and is accessible using **Oracle SQL Developer**. You can connect to it live and explore the full schema, run queries, or test PL/SQL procedures. This makes it easy for testing, validation, and demonstration purposes.
