
----------------------------------------------------------------------------------------------------------------------------------

-- Enable DBMS_OUTPUT
SET SERVEROUTPUT ON;

-- Test 1: Register Passenger (Procedure)
DECLARE
BEGIN
    pkg_transport_mgmt.register_passenger('New Passenger', '0770000000');
    DBMS_OUTPUT.PUT_LINE('Passenger registration test passed.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in passenger registration: ' || SQLERRM);
END;
/

----------------------------------------------------------------------------------------------------------------------------------

-- Test 2: Book Ticket (Procedure)
DECLARE
BEGIN
    -- Book seat 25 on schedule 1002 (valid)
    pkg_transport_mgmt.book_ticket(105, 1002, 25);
    DBMS_OUTPUT.PUT_LINE('Ticket booking test passed.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in booking: ' || SQLERRM);
END;
/

-----------------------------------------------------------------------------------------------------------------------------------

-- Test 3: Try Booking Invalid Seat (Trigger: trg_validate_seat_no)
DECLARE
BEGIN
    -- Seat 150 (invalid for vehicle 2 with 100 seats)
    pkg_transport_mgmt.book_ticket(101, 1002, 150);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Seat validation trigger worked: ' || SQLERRM);
END;
/

-----------------------------------------------------------------------------------------------------------------------------------

-- Test 4: Cancel Ticket (Procedure)
DECLARE
BEGIN
    pkg_transport_mgmt.cancel_ticket(2003); -- Already cancelled
    pkg_transport_mgmt.cancel_ticket(2001); -- Valid cancellation
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Cancellation error: ' || SQLERRM);
END;
/

-----------------------------------------------------------------------------------------------------------------------------------

-- Test 5: Get Ticket Info (Function)
DECLARE
    v_info VARCHAR2(1000);
BEGIN
    v_info := pkg_transport_mgmt.get_ticket_info(2001);
    DBMS_OUTPUT.PUT_LINE('Ticket Info: ' || v_info);
END;
/

-----------------------------------------------------------------------------------------------------------------------------------

-- Test 6: Get Summary (Function)
DECLARE
    v_summary VARCHAR2(1000);
BEGIN
    v_summary := pkg_transport_mgmt.get_summary('ROUTE');
    DBMS_OUTPUT.PUT_LINE('Route Summary: ' || CHR(10) || v_summary);
    
    v_summary := pkg_transport_mgmt.get_summary('ALL');
    DBMS_OUTPUT.PUT_LINE('Overall Summary: ' || v_summary);
END;
/

-----------------------------------------------------------------------------------------------------------------------------------

-- Test 7:  Get Available Seats (Function)
declare
   v_available_seats number;
begin
   v_available_seats := pkg_transport_mgmt.get_available_seats(1001);
   dbms_output.put_line('There are: '|| v_available_seats || ' seats available.');
end;
/ 

-----------------------------------------------------------------------------------------------------------------------------------

-- Test 8: Test Double Payment (Trigger: trg_prevent_double_payment)
DECLARE
BEGIN
    INSERT INTO Payment VALUES (3005, 2001, 350, SYSDATE, 'CARD');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Double payment prevented: ' || SQLERRM);
END;
/

------------------------------------------------------------------------------------------------------------------------------------

-- Test 9: Test Overbooking (Trigger: trg_prevent_overbooking)
DECLARE
    i NUMBER;
BEGIN
    -- Book all remaining seats in schedule 1003 (30 seats)
    FOR i IN 1..30 LOOP
        INSERT INTO Ticket VALUES (ticket_seq.NEXTVAL, 101, 1003, SYSDATE, SYSDATE+1, i, 'CONFIRMED');
    END LOOP;
    -- Next booking should fail
    INSERT INTO Ticket VALUES (ticket_seq.NEXTVAL, 102, 1003, SYSDATE, SYSDATE+1, 31, 'CONFIRMED');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Overbooking prevented: ' || SQLERRM);
END;
/

------------------------------------------------------------------------------------------------------------------------------------

-- Test Composite Type Functions
-- Test A: Get Ticket Info as Record
DECLARE
    v_ticket_rec pkg_transport_mgmt.ticket_info_rec;
BEGIN
    v_ticket_rec := pkg_transport_mgmt.get_ticket_info_rec(2001);
    DBMS_OUTPUT.PUT_LINE('Ticket Details (Record):');
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_ticket_rec.ticket_id);
    DBMS_OUTPUT.PUT_LINE('Passenger: ' || v_ticket_rec.passenger);
    DBMS_OUTPUT.PUT_LINE('Route: ' || v_ticket_rec.route);
END;
/

------------------------------------------------------------------------------------------------------------------------------------

-- Test B: Get Summary as Table
DECLARE
    v_summary_rec pkg_transport_mgmt.route_summary_rec;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Route Summary (Table):');
    FOR rec IN (SELECT * FROM TABLE(pkg_transport_mgmt.get_summary_tbl)) LOOP
        DBMS_OUTPUT.PUT_LINE(rec.route || ' | Tickets: ' || rec.ticket_count || ' | Revenue: ' || rec.total_revenue);
    END LOOP;
END;
/
