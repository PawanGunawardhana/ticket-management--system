---1---------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_validate_seat_no
BEFORE INSERT OR UPDATE OF seat_no ON Ticket
FOR EACH ROW
DECLARE
    v_capacity NUMBER;
BEGIN
    SELECT v.seats_available INTO v_capacity
    FROM Schedule s
    JOIN Vehicle v ON s.vehicle_id = v.vehicle_id
    WHERE s.schedule_id = :NEW.schedule_id;

    IF :NEW.seat_no < 1 OR :NEW.seat_no > v_capacity THEN
        RAISE_APPLICATION_ERROR(-20010, 'Seat number ' || :NEW.seat_no || ' is invalid. Valid range is 1 to ' || v_capacity);
    END IF;
END;
/

---2----------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_prevent_recancel
BEFORE UPDATE OF status ON Ticket
FOR EACH ROW
BEGIN
    IF :OLD.status = 'CANCELLED' AND :NEW.status = 'CANCELLED' THEN
        RAISE_APPLICATION_ERROR(-20011, 'Ticket is already cancelled.');
    END IF;
END;
/

---3----------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_prevent_double_payment
BEFORE INSERT ON Payment
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM Payment
    WHERE ticket_id = :NEW.ticket_id;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20013, 'Payment already exists for this ticket.');
    END IF;
END;
/

---4----------------------------------------------------------------------------------------------------------------------------------------

-- Auto-Update seat availability on Cancellation  
CREATE OR REPLACE TRIGGER trg_update_seat_on_cancel
AFTER UPDATE ON ticket
FOR EACH ROW
WHEN (OLD.status = 'CONFIRMED' AND NEW.status = 'CANCELLED')
BEGIN
    UPDATE schedule
    SET available_seats = available_seats + 1
    WHERE schedule_id = :NEW.schedule_id;
END;
/

---5----------------------------------------------------------------------------------------------------------------------------------------

-- Prevent Overbooking
CREATE OR REPLACE TRIGGER trg_prevent_overbooking
BEFORE INSERT ON ticket
FOR EACH ROW
DECLARE
    v_available_seats NUMBER;
BEGIN
    v_available_seats := pkg_transport_mgmt.get_available_seats(:NEW.schedule_id);
    IF v_available_seats <= 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'No seats available for this schedule.');
    END IF;
END;
/

COMMIT;
/
