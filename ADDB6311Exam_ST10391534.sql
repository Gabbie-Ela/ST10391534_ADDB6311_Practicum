CREATE TABLE EVENT (
    EVENT_ID INT PRIMARY KEY,
    EVENT_NAME VARCHAR(100),
    EVENT_RATE DECIMAL(10,2)
);


CREATE TABLE ARTIST (
    ARTIST_ID VARCHAR(10) PRIMARY KEY,
    ARTIST_NAME VARCHAR(100),
    ARTIST_EMAIL VARCHAR(100)
);


CREATE TABLE BOOKINGS (
    BOOKING_ID INT PRIMARY KEY,
    BOOKING_DATE DATE,
    EVENT_ID INT,
    ARTIST_ID VARCHAR(10),
    FOREIGN KEY (EVENT_ID) REFERENCES EVENT(EVENT_ID),
    FOREIGN KEY (ARTIST_ID) REFERENCES ARTIST(ARTIST_ID)
);


INSERT INTO EVENT (EVENT_ID, EVENT_NAME, EVENT_RATE) VALUES (1001, 'Open Air Comedy Festival', 300.00);
INSERT INTO EVENT (EVENT_ID, EVENT_NAME, EVENT_RATE) VALUES (1002, 'Mountain Side Music Festival', 280.00);
INSERT INTO EVENT (EVENT_ID, EVENT_NAME, EVENT_RATE) VALUES (1003, 'Beach Music Festival', 195.00);



INSERT INTO ARTIST (ARTIST_ID, ARTIST_NAME, ARTIST_EMAIL) VALUES ('A_101', 'Max Trillion', 'maxt@isat.com');
INSERT INTO ARTIST (ARTIST_ID, ARTIST_NAME, ARTIST_EMAIL) VALUES ('A_102', 'Music Mayhem', 'mayhem@ymail.com');
INSERT INTO ARTIST (ARTIST_ID, ARTIST_NAME, ARTIST_EMAIL) VALUES ('A_103', 'LOL Man', 'lol@isat.com');


INSERT INTO BOOKINGS (BOOKING_ID, BOOKING_DATE, EVENT_ID, ARTIST_ID) VALUES (1, TO_DATE('2024-07-15', 'YYYY-MM-DD'), 1002, 'A_101');
INSERT INTO BOOKINGS (BOOKING_ID, BOOKING_DATE, EVENT_ID, ARTIST_ID) VALUES (2, TO_DATE('2024-07-15', 'YYYY-MM-DD'), 1002, 'A_102');
INSERT INTO BOOKINGS (BOOKING_ID, BOOKING_DATE, EVENT_ID, ARTIST_ID) VALUES (3, TO_DATE('2024-08-27', 'YYYY-MM-DD'), 1001, 'A_103');
INSERT INTO BOOKINGS (BOOKING_ID, BOOKING_DATE, EVENT_ID, ARTIST_ID) VALUES (4, TO_DATE('2024-08-30', 'YYYY-MM-DD'), 1003, 'A_101');
INSERT INTO BOOKINGS (BOOKING_ID, BOOKING_DATE, EVENT_ID, ARTIST_ID) VALUES (5, TO_DATE('2024-08-30', 'YYYY-MM-DD'), 1003, 'A_102');



SELECT 
    B.BOOKING_ID,
    b.BOOKING_DATE,
    E.EVENT_NAME,
    E.EVENT_RATE,
    A.ARTIST_NAME,
    A.ARTIST_EMAIL
FROM 
    BOOKINGS B
    JOIN EVENT E ON B.EVENT_ID = E.EVENT_ID
    JOIN ARTIST A ON B.ARTIST_ID = A.ARTIST_ID;
 
    

SELECT 
    A.ARTIST_ID,
    A.ARTIST_NAME,
    A.ARTIST_EMAIL,
    COUNT(B.BOOKING_ID) AS NUM_PERFORMANCES
FROM 
    ARTIST A
    LEFT JOIN BOOKINGS B ON A.ARTIST_ID = B.ARTIST_ID
GROUP BY 
    A.ARTIST_ID, A.ARTIST_NAME, A.ARTIST_EMAIL
HAVING 
    COUNT(B.BOOKING_ID) = (
        SELECT MIN(COUNT(*))
        FROM BOOKINGS
        GROUP BY ARTIST_ID
    );



SELECT 
    A.ARTIST_NAME,
    SUM(E.EVENT_RATE) AS TOTAL_REVENUE
FROM 
    BOOKINGS B
    JOIN ARTIST A ON B.ARTIST_ID = A.ARTIST_ID
    JOIN EVENT E ON B.EVENT_ID = E.EVENT_ID
GROUP BY 
    A.ARTIST_NAME;



SET SERVEROUTPUT ON;

DECLARE
    v_artist_name   ARTIST.ARTIST_NAME%TYPE;
    v_booking_date  BOOKINGS.BOOKING_DATE%TYPE;
    
    CURSOR booking_cursor IS
        SELECT A.ARTIST_NAME, B.BOOKING_DATE
        FROM BOOKINGS B
        JOIN ARTIST A ON B.ARTIST_ID = A.ARTIST_ID
        WHERE B.EVENT_ID = 1001;
BEGIN
    FOR record IN booking_cursor LOOP
        v_artist_name := record.ARTIST_NAME;
        v_booking_date := record.BOOKING_DATE;
        
        DBMS_OUTPUT.PUT_LINE('Artist: ' || v_artist_name || ' | Booking Date: ' || TO_CHAR(v_booking_date, 'YYYY-MM-DD'));
    END LOOP;
END;
/


SET SERVEROUTPUT ON;

DECLARE
    v_event_name   EVENT.EVENT_NAME%TYPE;
    v_event_rate   EVENT.EVENT_RATE%TYPE;
    v_discounted   NUMBER;

    CURSOR event_cursor IS
        SELECT EVENT_NAME, EVENT_RATE
        FROM EVENT;
BEGIN
    FOR rec IN event_cursor LOOP
        v_event_name := rec.EVENT_NAME;
        v_event_rate := rec.EVENT_RATE;

        IF v_event_rate > 250 THEN
            v_discounted := v_event_rate * 0.9;  -- 10% discount
            DBMS_OUTPUT.PUT_LINE(
                'Event: ' || v_event_name || 
                ' | Original Price: R' || v_event_rate || 
                ' | Discounted Price: R' || TO_CHAR(ROUND(v_discounted, 2))
            );
        ELSE
            DBMS_OUTPUT.PUT_LINE(
                'Event: ' || v_event_name || 
                ' | Price: R' || v_event_rate || 
                ' (No Discount)'
            );
        END IF;
    END LOOP;
END;
/



CREATE OR REPLACE VIEW Event_Schedules AS
SELECT 
    E.EVENT_NAME,
    B.BOOKING_DATE
FROM 
    BOOKINGS B
    JOIN EVENT E ON B.EVENT_ID = E.EVENT_ID
WHERE 
    B.BOOKING_DATE BETWEEN TO_DATE('2024-07-01', 'YYYY-MM-DD') 
                        AND TO_DATE('2024-08-28', 'YYYY-MM-DD');
SELECT * FROM Event_Schedules;



CREATE OR REPLACE PROCEDURE Get_Bookings_By_Artist (
    p_artist_name IN VARCHAR2 
)
IS
BEGIN
    FOR rec IN (
        SELECT 
            B.BOOKING_ID,
            A.ARTIST_NAME,
            B.BOOKING_DATE,
            E.EVENT_NAME,
            E.EVENT_RATE
        FROM 
            BOOKINGS B
            JOIN ARTIST A ON B.ARTIST_ID = A.ARTIST_ID
            JOIN EVENT E ON B.EVENT_ID = E.EVENT_ID
        WHERE 
            A.ARTIST_NAME = p_artist_name
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Booking ID: ' || rec.BOOKING_ID || 
                             ' | Artist: ' || rec.ARTIST_NAME || 
                             ' | Date: ' || TO_CHAR(rec.BOOKING_DATE, 'YYYY-MM-DD') || 
                             ' | Event: ' || rec.EVENT_NAME || 
                             ' | Rate: R' || rec.EVENT_RATE);
    END LOOP;
END;
/
SET SERVEROUTPUT ON;

BEGIN
    Get_Bookings_By_Artist('Max Trillion');
END;
/



CREATE OR REPLACE FUNCTION Get_Artist_Revenue (
    p_artist_name IN ARTIST.ARTIST_NAME%TYPE
) 
RETURN NUMBER
IS
    v_total_revenue NUMBER := 0;
BEGIN
    SELECT 
        NVL(SUM(E.EVENT_RATE), 0)
    INTO 
        v_total_revenue
    FROM 
        BOOKINGS B
        JOIN ARTIST A ON B.ARTIST_ID = A.ARTIST_ID
        JOIN EVENT E ON B.EVENT_ID = E.EVENT_ID
    WHERE 
        A.ARTIST_NAME = p_artist_name;

    RETURN v_total_revenue;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No bookings found for artist: ' || p_artist_name);
        RETURN 0;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: ' || SQLERRM);
        RETURN -1;
END;
/



SET SERVEROUTPUT ON;

DECLARE
    v_revenue NUMBER;
BEGIN
    v_revenue := Get_Artist_Revenue('Music Mayhem');

    IF v_revenue = -1 THEN
        DBMS_OUTPUT.PUT_LINE('Error calculating revenue.');
    ELSIF v_revenue = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No bookings for this artist.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Total revenue for Music Mayhem: R' || v_revenue);
    END IF;
END;
/

ALTER USER C##ONEUSER QUOTA UNLIMITED ON USERS;







