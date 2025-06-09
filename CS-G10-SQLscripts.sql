-- Drop tables if already exist (for testing purposes)

-- DROP TABLE Payment CASCADE CONSTRAINTS;
-- DROP TABLE Ticket CASCADE CONSTRAINTS;
-- DROP TABLE Schedule CASCADE CONSTRAINTS;
-- DROP TABLE Passenger CASCADE CONSTRAINTS;
-- DROP TABLE Vehicle CASCADE CONSTRAINTS;
-- DROP TABLE Transport_Route CASCADE CONSTRAINTS;

-- Create tables

CREATE TABLE Transport_Route (
  route_id NUMBER PRIMARY KEY,
  transport_type VARCHAR2(20),
  origin VARCHAR2(50),
  destination VARCHAR2(50),
  distance_km NUMBER
);

CREATE TABLE Vehicle (
  vehicle_id NUMBER PRIMARY KEY,
  plate_number VARCHAR2(20),
  transport_type VARCHAR2(20),
  seats_available NUMBER
);

CREATE TABLE Passenger (
  passenger_id NUMBER PRIMARY KEY,
  name VARCHAR2(50),
  phone VARCHAR2(20),
  email VARCHAR2(100)
);

CREATE TABLE Schedule (
  schedule_id NUMBER PRIMARY KEY,
  vehicle_id NUMBER,
  route_id NUMBER,
  departure_time DATE,
  arrival_time DATE,
  fare_rate NUMBER,
  available_seats NUMBER,
  FOREIGN KEY (vehicle_id) REFERENCES Vehicle(vehicle_id),
  FOREIGN KEY (route_id) REFERENCES Transport_Route(route_id)
);



CREATE TABLE Ticket (
  ticket_id NUMBER PRIMARY KEY,
  passenger_id NUMBER,
  schedule_id NUMBER,
  booking_date DATE DEFAULT SYSDATE,
  travel_date DATE,
  seat_no NUMBER,
  status VARCHAR2(20) DEFAULT 'CONFIRMED',
  FOREIGN KEY (passenger_id) REFERENCES Passenger(passenger_id),
  FOREIGN KEY (schedule_id) REFERENCES Schedule(schedule_id)
);

CREATE TABLE Payment (
  payment_id NUMBER PRIMARY KEY,
  ticket_id NUMBER,
  amount NUMBER,
  payment_date DATE,
  payment_method VARCHAR2(20) DEFAULT 'CARD',
  FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id)
);

CREATE SEQUENCE passenger_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ticket_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE payment_seq START WITH 1 INCREMENT BY 1;

-- Insert dummy data 

BEGIN
  INSERT INTO Transport_Route (route_id, transport_type, origin, destination, distance_km) VALUES (1, 'Bus', 'Colombo', 'Kandy', 115);
  INSERT INTO Transport_Route (route_id, transport_type, origin, destination, distance_km) VALUES (2, 'Train', 'Colombo', 'Galle', 120);
  INSERT INTO Transport_Route (route_id, transport_type, origin, destination, distance_km) VALUES (3, 'Bus', 'Kandy', 'Nuwara Eliya', 75);
  INSERT INTO Transport_Route (route_id, transport_type, origin, destination, distance_km) VALUES (4, 'Train', 'Galle', 'Matara', 35);

  INSERT INTO Vehicle (vehicle_id, plate_number, transport_type, seats_available) VALUES (1, 'WP CA 1234', 'Bus', 40);
  INSERT INTO Vehicle (vehicle_id, plate_number, transport_type, seats_available) VALUES (2, 'WP TA 5678', 'Train', 100);
  INSERT INTO Vehicle (vehicle_id, plate_number, transport_type, seats_available) VALUES (3, 'WP CB 9101', 'Bus', 30);
  INSERT INTO Vehicle (vehicle_id, plate_number, transport_type, seats_available) VALUES (4, 'WP TB 1121', 'Train', 80);

  INSERT INTO Passenger (passenger_id, name, phone, email) VALUES (101, 'Tharindu Gunarathne', '0711234567', 'tharindu@example.com');
  INSERT INTO Passenger (passenger_id, name, phone, email) VALUES (102, 'Pawan Gunarawardhana', '0727654321', 'pawan@example.com');
  INSERT INTO Passenger (passenger_id, name, phone, email) VALUES (103, 'Amal Silva', '0779876543', 'amal.silva@example.com');
  INSERT INTO Passenger (passenger_id, name, phone, email) VALUES (104, 'Kasun Fernando', '0702345678', 'kasun.fernando@example.com');
  INSERT INTO Passenger (passenger_id, name, phone, email) VALUES (105, 'Dilani Kumari', '0763456789', 'dilani.kumari@example.com');

  INSERT INTO Schedule (schedule_id, vehicle_id, route_id, departure_time, arrival_time, fare_rate) VALUES (1001, 1, 1, TO_DATE('2025-05-20 08:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-05-20 12:00', 'YYYY-MM-DD HH24:MI'), 350);
  INSERT INTO Schedule (schedule_id, vehicle_id, route_id, departure_time, arrival_time, fare_rate) VALUES (1002, 2, 2, TO_DATE('2025-05-21 09:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-05-21 14:30', 'YYYY-MM-DD HH24:MI'), 500);
  INSERT INTO Schedule (schedule_id, vehicle_id, route_id, departure_time, arrival_time, fare_rate) VALUES (1003, 3, 3, TO_DATE('2025-05-22 07:30', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-05-22 10:30', 'YYYY-MM-DD HH24:MI'), 250);
  INSERT INTO Schedule (schedule_id, vehicle_id, route_id, departure_time, arrival_time, fare_rate) VALUES (1004, 4, 4, TO_DATE('2025-05-23 10:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2025-05-23 11:30', 'YYYY-MM-DD HH24:MI'), 150);

  INSERT INTO Ticket (ticket_id, passenger_id, schedule_id, booking_date, travel_date, seat_no, status) VALUES (2001, 101, 1001, SYSDATE - 5, TO_DATE('2025-05-20', 'YYYY-MM-DD'), 5, 'CONFIRMED');
  INSERT INTO Ticket (ticket_id, passenger_id, schedule_id, booking_date, travel_date, seat_no, status) VALUES (2002, 102, 1002, SYSDATE - 4, TO_DATE('2025-05-21', 'YYYY-MM-DD'), 12, 'CONFIRMED');
  INSERT INTO Ticket (ticket_id, passenger_id, schedule_id, booking_date, travel_date, seat_no, status) VALUES (2003, 103, 1003, SYSDATE - 3, TO_DATE('2025-05-22', 'YYYY-MM-DD'), 7, 'CANCELLED');
  INSERT INTO Ticket (ticket_id, passenger_id, schedule_id, booking_date, travel_date, seat_no, status) VALUES (2004, 104, 1004, SYSDATE - 2, TO_DATE('2025-05-23', 'YYYY-MM-DD'), 15, 'CONFIRMED');
  INSERT INTO Ticket (ticket_id, passenger_id, schedule_id, booking_date, travel_date, seat_no, status) VALUES (2005, 105, 1002, SYSDATE - 1, TO_DATE('2025-05-21', 'YYYY-MM-DD'), 20, 'CONFIRMED');

  INSERT INTO Payment (payment_id, ticket_id, amount, payment_date, payment_method) VALUES (3001, 2001, 350, SYSDATE - 5, 'CARD');
  INSERT INTO Payment (payment_id, ticket_id, amount, payment_date, payment_method) VALUES (3002, 2002, 500, SYSDATE - 4, 'CASH');
  INSERT INTO Payment (payment_id, ticket_id, amount, payment_date, payment_method) VALUES (3003, 2004, 150, SYSDATE - 2, 'CARD');
  INSERT INTO Payment (payment_id, ticket_id, amount, payment_date, payment_method) VALUES (3004, 2005, 500, SYSDATE - 1, 'MOBILE_PAY');

  COMMIT;
  
END;
/

UPDATE Schedule s
SET available_seats = (
    SELECT v.seats_available
    FROM Vehicle v
    WHERE v.vehicle_id = s.vehicle_id
);
/
COMMIT;
