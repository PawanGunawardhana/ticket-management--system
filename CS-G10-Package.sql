
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE pkg_transport_mgmt AS
    PROCEDURE register_passenger(p_name VARCHAR2, p_phone VARCHAR2);
    PROCEDURE book_ticket(p_passenger_id NUMBER, p_schedule_id NUMBER, p_seat_no NUMBER);  -- Changed to p_seat_no
    PROCEDURE cancel_ticket(p_ticket_id NUMBER);
    FUNCTION get_available_seats(p_schedule_id NUMBER) RETURN NUMBER;

-- Composite Data Types
 TYPE ticket_info_rec IS RECORD (
        ticket_id    NUMBER,
        passenger    VARCHAR2(50),
        route        VARCHAR2(100),
        departure    VARCHAR2(30),
        seat_no      NUMBER,
        fare         NUMBER,
        status       VARCHAR2(20)
    );
    
    TYPE route_summary_rec IS RECORD (
        route          VARCHAR2(100),
        ticket_count   NUMBER,
        total_revenue  NUMBER
    );
    TYPE route_summary_tbl IS TABLE OF route_summary_rec;

--Functions with Composite Returns
    FUNCTION get_ticket_info_rec(p_ticket_id NUMBER) RETURN ticket_info_rec;
    FUNCTION get_summary_tbl RETURN route_summary_tbl PIPELINED;

    FUNCTION get_ticket_info(p_ticket_id NUMBER) RETURN VARCHAR2;
    FUNCTION get_summary(p_summary_type VARCHAR2) RETURN VARCHAR2;

END pkg_transport_mgmt;
/
------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY pkg_transport_mgmt AS

---1-------------- Private functions------------------------------------------------------------------------------------------------ 
   
    
    FUNCTION calc_fare(p_schedule_id NUMBER) RETURN NUMBER IS
        v_fare_rate NUMBER;
    BEGIN
        SELECT s.fare_rate  -- Corrected to use fare_rate from schedule
        INTO v_fare_rate
        FROM schedule s
        WHERE s.schedule_id = p_schedule_id;
        RETURN v_fare_rate;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END calc_fare;

---2--------------------------------------------------------------------------------------------------------------------------------

    FUNCTION is_seat_available(p_schedule_id NUMBER, p_seat_no NUMBER) RETURN BOOLEAN IS  -- Changed to p_seat_no
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM ticket
        WHERE schedule_id = p_schedule_id
          AND seat_no = p_seat_no  -- Corrected to seat_no
          AND status = 'CONFIRMED';  -- Changed to match table's default status
        RETURN (v_count = 0);
    END is_seat_available;

------------------------------------------------------------------------------------------------------------------------------------
---P1---------------Public procedures/functions-------------------------------------------------------------------------------------
 
    PROCEDURE register_passenger(p_name VARCHAR2, p_phone VARCHAR2) IS
        v_passenger_id NUMBER;
    BEGIN
        SELECT passenger_seq.NEXTVAL INTO v_passenger_id FROM dual;
        INSERT INTO passenger(passenger_id, name, phone)
        VALUES (v_passenger_id, p_name, p_phone);
        DBMS_OUTPUT.PUT_LINE('Passenger registered with ID: ' || v_passenger_id);
    END register_passenger;
    
---P2-------------------------------------------------------------------------------------------------------------------------------    

    PROCEDURE book_ticket(p_passenger_id NUMBER, p_schedule_id NUMBER, p_seat_no NUMBER) IS  -- Changed to p_seat_no
        v_ticket_id NUMBER;
        v_fare      NUMBER;
        v_dummy     NUMBER;
    BEGIN
        -- Validation checks
        BEGIN
            SELECT 1 INTO v_dummy FROM passenger WHERE passenger_id = p_passenger_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20002, 'Passenger ID ' || p_passenger_id || ' does not exist.');
        END;

        BEGIN
            SELECT 1 INTO v_dummy FROM schedule WHERE schedule_id = p_schedule_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20003, 'Schedule ID ' || p_schedule_id || ' does not exist.');
        END;

        IF NOT is_seat_available(p_schedule_id, p_seat_no) THEN
            RAISE_APPLICATION_ERROR(-20004, 'Seat ' || p_seat_no || ' is already booked.');
        END IF;

        v_fare := calc_fare(p_schedule_id);

        -- Create ticket
        SELECT ticket_seq.NEXTVAL INTO v_ticket_id FROM dual;
        INSERT INTO ticket(ticket_id, passenger_id, schedule_id, seat_no, status, booking_date, travel_date)
        VALUES (v_ticket_id, p_passenger_id, p_schedule_id, p_seat_no, 'CONFIRMED', SYSDATE, 
               (SELECT departure_time FROM schedule WHERE schedule_id = p_schedule_id));

        -- Create payment
        INSERT INTO payment(payment_id, ticket_id, amount, payment_date)
        VALUES (payment_seq.NEXTVAL, v_ticket_id, v_fare, SYSDATE);

        DBMS_OUTPUT.PUT_LINE('Ticket booked. Ticket ID: ' || v_ticket_id || ', Fare: ' || v_fare);
    END book_ticket;
    
---P3--------------------------------------------------------------------------------------------------------------------------------        

    PROCEDURE cancel_ticket(p_ticket_id NUMBER) IS
        v_status VARCHAR2(20);
    BEGIN
        SELECT status INTO v_status FROM ticket WHERE ticket_id = p_ticket_id;

        IF v_status = 'CANCELLED' THEN
            DBMS_OUTPUT.PUT_LINE('Ticket ' || p_ticket_id || ' is already cancelled.');
            RETURN;
        END IF;

        UPDATE ticket SET status = 'CANCELLED' WHERE ticket_id = p_ticket_id;
        DBMS_OUTPUT.PUT_LINE('Ticket ' || p_ticket_id || ' has been cancelled.');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'Ticket ID ' || p_ticket_id || ' does not exist.');
    END cancel_ticket;
    
---F1--------------------------------------------------------------------------------------------------------------------------------

-- Enhanced Function with Record Type
    FUNCTION get_ticket_info_rec(p_ticket_id NUMBER) RETURN ticket_info_rec IS
        v_rec ticket_info_rec;
    BEGIN
        SELECT t.ticket_id,
               p.name,
               r.origin || ' to ' || r.destination,
               TO_CHAR(s.departure_time, 'DD-MON-YYYY HH24:MI'),
               t.seat_no,
               s.fare_rate,
               t.status
        INTO v_rec
        FROM ticket t
        JOIN passenger p ON t.passenger_id = p.passenger_id
        JOIN schedule s ON t.schedule_id = s.schedule_id
        JOIN transport_route r ON s.route_id = r.route_id
        WHERE t.ticket_id = p_ticket_id;

        RETURN v_rec;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20007, 'Ticket not found');
    END get_ticket_info_rec;
    
---F2----------------------------------------------------------------------------------------------------------------------------------    

-- Enhanced Function with Table Type
    FUNCTION get_summary_tbl RETURN route_summary_tbl PIPELINED IS
    BEGIN
        FOR rec IN (
            SELECT r.origin || ' to ' || r.destination AS route,
                   COUNT(*) AS ticket_count,
                   SUM(s.fare_rate) AS total_revenue
            FROM ticket t
            JOIN schedule s ON t.schedule_id = s.schedule_id
            JOIN transport_route r ON s.route_id = r.route_id
            GROUP BY r.origin, r.destination
        ) LOOP
            PIPE ROW(route_summary_rec(rec.route, rec.ticket_count, rec.total_revenue));
        END LOOP;
        RETURN;
    END get_summary_tbl;

---F3----------------------------------------------------------------------------------------------------------------------------------

    FUNCTION get_ticket_info(p_ticket_id NUMBER) RETURN VARCHAR2 IS
        v_info VARCHAR2(1000);
    BEGIN
        SELECT 'Ticket ID: ' || t.ticket_id ||
               ', Passenger: ' || p.name ||
               ', Route: ' || r.origin || ' to ' || r.destination ||  -- Using origin/destination
               ', Departure: ' || TO_CHAR(s.departure_time, 'DD-MON-YYYY HH24:MI') ||
               ', Seat: ' || t.seat_no ||  -- Corrected to seat_no
               ', Fare: ' || s.fare_rate ||  -- Using fare_rate from schedule
               ', Status: ' || t.status
        INTO v_info
        FROM ticket t
        JOIN passenger p ON t.passenger_id = p.passenger_id
        JOIN schedule s ON t.schedule_id = s.schedule_id
        JOIN transport_route r ON s.route_id = r.route_id
        WHERE t.ticket_id = p_ticket_id;

        RETURN v_info;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Ticket ID ' || p_ticket_id || ' not found.';
    END get_ticket_info;
    
---F4----------------------------------------------------------------------------------------------------------------------------------

    FUNCTION get_summary(p_summary_type VARCHAR2) RETURN VARCHAR2 IS
        v_summary VARCHAR2(1000);
    BEGIN
        IF UPPER(p_summary_type) = 'ROUTE' THEN
            FOR rec IN (
                SELECT r.origin || ' to ' || r.destination AS route,
                       COUNT(*) AS ticket_count,
                       SUM(s.fare_rate) AS total_revenue  -- Using fare_rate from schedule
                FROM ticket t
                JOIN schedule s ON t.schedule_id = s.schedule_id
                JOIN transport_route r ON s.route_id = r.route_id
                GROUP BY r.origin, r.destination
            ) LOOP
                v_summary := v_summary ||
                             'Route ' || rec.route || 
                             ': Tickets=' || rec.ticket_count ||
                             ', Revenue=' || rec.total_revenue || CHR(10);
            END LOOP;
        ELSIF UPPER(p_summary_type) = 'ALL' THEN
            SELECT COUNT(*) || ' tickets, Total Revenue: ' || SUM(s.fare_rate)
            INTO v_summary
            FROM ticket t
            JOIN schedule s ON t.schedule_id = s.schedule_id;
        ELSE
            RAISE_APPLICATION_ERROR(-20006, 'Invalid summary type. Use ''ROUTE'' or ''ALL''.');
        END IF;
        RETURN v_summary;
    END get_summary;
    
---F5---------------------------------------------------------------------------------------------------------------------------------
    
    FUNCTION get_available_seats(p_schedule_id NUMBER) RETURN NUMBER IS
        v_booked_seats NUMBER;
        v_capacity NUMBER;
    BEGIN
        -- Get total booked seats
        SELECT COUNT(*) INTO v_booked_seats
        FROM Ticket
        WHERE schedule_id = p_schedule_id AND status = 'CONFIRMED';

        -- Get vehicle capacity
        SELECT v.seats_available INTO v_capacity
        FROM Schedule s
        JOIN Vehicle v ON s.vehicle_id = v.vehicle_id
        WHERE s.schedule_id = p_schedule_id;

        RETURN v_capacity - v_booked_seats;
    END get_available_seats;
    
--------------------------------------------------------------------------------------------------------------------------------------   
END pkg_transport_mgmt;
/
COMMIT;
