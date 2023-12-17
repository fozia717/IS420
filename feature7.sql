feature 7
CREATE OR REPLACE PROCEDURE extend_session(
  p_session_id IN NUMBER,
  p_current_time IN TIMESTAMP,
  p_hours_to_extend IN INT
)
IS
  v_start_time TIMESTAMP;
  v_end_time TIMESTAMP;
  v_max_length NUMBER;
  v_extended_end_time TIMESTAMP;
BEGIN
  -- Check if parking session exists
  SELECT start_time, end_time
  INTO v_start_time, v_end_time
  FROM parking_sessions
  WHERE session_id = p_session_id;

  -- Check if extending the session exceeds the maximal length of the parking zone
  SELECT max_parking_length
  INTO v_max_length
  FROM parking_zone
  WHERE zone_id = (SELECT zone_id FROM parking_sessions WHERE session_id = p_session_id);

  -- Calculate the extended end time
  v_extended_end_time := v_end_time + NUMTODSINTERVAL(p_hours_to_extend, 'HOUR');

  IF v_extended_end_time > v_max_length THEN
    DBMS_OUTPUT.PUT_LINE('Cannot extend the session because maximal length reached');
    RETURN;
  END IF;

  -- Extend the end time of the parking session
  v_end_time := v_extended_end_time;

  -- Update the parking session with the new end time
  UPDATE parking_sessions
  SET end_time = v_end_time
  WHERE session_id = p_session_id;

DBMS_OUTPUT.PUT_LINE('Session ' || p_session_id || ' extended by ' || p_hours_to_extend || ' hours  ' || TO_CHAR(v_extended_end_time, 'YYYY-MM-DD HH24:MI:SS'));
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Invalid session ID');
END;
/

BEGIN
  extend_session(1, TIMESTAMP '2021-05-01 12:00:00', 2);
  extend_session(2, TIMESTAMP '2021-05-01 12:00:00', 20);
  extend_session(100, TIMESTAMP '2021-05-01 12:00:00', 4);
END;
/
---------------------------------------------------------------------------
DROP TABLE payment_transaction CASCADE CONSTRAINTS;
DROP TABLE message CASCADE CONSTRAINTS;
DROP TABLE parking_sessions CASCADE CONSTRAINTS;
DROP TABLE parking_zone CASCADE CONSTRAINTS;
DROP TABLE vehicle CASCADE CONSTRAINTS;
DROP TABLE customers CASCADE CONSTRAINTS;

CREATE TABLE customers (
  customer_id INT PRIMARY KEY,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  email VARCHAR(100),
  phone_number VARCHAR(20),
  address_line1 VARCHAR(100),
  city VARCHAR(50),
  state VARCHAR(50),
  postal_code VARCHAR(20)
);

CREATE TABLE vehicle (
  vehicle_id VARCHAR(30) PRIMARY KEY,
  state_v VARCHAR(15),
  maker VARCHAR(15),
  model_v VARCHAR(15),
  year_v VARCHAR(4),
  color VARCHAR(10),
  license_pl VARCHAR(10)
);

CREATE TABLE parking_sessions (
  session_id NUMBER PRIMARY KEY,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  zone_id NUMBER,
  vehicle_id VARCHAR2(30),
  customer_id NUMBER,
  total_charge FLOAT,
  CONSTRAINT fk_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_vehicle_id FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id)
);

CREATE TABLE message (
  message_id NUMBER PRIMARY KEY,
  message_body VARCHAR(200),
  message_time TIMESTAMP, 
  customer_id NUMBER,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE payment_transaction (
  payment_id NUMBER PRIMARY KEY, 
  pay_amount NUMBER,
  hours INT,
  pay_time INT, 
  session_id NUMBER,
  CONSTRAINT fk_session_id FOREIGN KEY (session_id) REFERENCES parking_sessions(session_id)
);

CREATE TABLE parking_zone (
  zone_id NUMBER PRIMARY KEY,
  zone_name VARCHAR2(50),
  max_parking_length NUMBER,
  start_date date,
  end_date date,
  effective_start_time TIMESTAMP,
  effective_end_time TIMESTAMP,
  occupied NUMBER
);

INSERT INTO customers VALUES
  (1, 'John', 'Doe', 'johndoe@gmail.com', '(240)555-1234', '123 Main St', 'Silver Spring', 'MD', '12345');

INSERT INTO customers VALUES
  (2, 'Jane', 'Smith', 'janesmith@gmail.com', '(202)555-5678', '456 Elm St', 'Baltimore', 'MD', '67890');
  
INSERT INTO customers VALUES
  (3, 'Bob', 'Johnson', 'bobjohnson@gmail.com', '(301)555-2468', '789 Oak St', 'Rockville', 'MD', '13579');

INSERT INTO vehicle VALUES 
  ('VX7878', 'Maryland', 'Tesla', 'model S', '2020', 'White', '9EX889');

INSERT INTO vehicle VALUES 
  ('MD9000', 'NewYork', 'Toyota', 'Land Cruiser', '2022', 'Black', '999MDX');

INSERT INTO vehicle VALUES 
  ('LY2343', 'California', 'Porsche', 'Cayenne', '2018', 'Red', '2MK9YU');

INSERT INTO parking_sessions VALUES
  (1, TIMESTAMP '2021-05-01 10:00:00', TIMESTAMP '2021-05-01 14:00:00', 3, 'VX7878', 1, 8.50);

INSERT INTO parking_sessions VALUES
  (2, TIMESTAMP '2021-05-02 11:30:00', TIMESTAMP '2021-05-02 13:30:00', 2, 'MD9000', 1, 5.75);

INSERT INTO parking_sessions VALUES
  (3, TIMESTAMP '2021-05-03 09:00:00', TIMESTAMP '2021-05-03 12:00:00', 1, 'LY2343', 2, 10.25);

INSERT INTO parking_sessions VALUES
  (4, TIMESTAMP '2021-05-04 13:00:00', TIMESTAMP '2021-05-04 16:00:00', 3, 'VX7878', 2, 12.50);

INSERT INTO parking_sessions VALUES
  (5, TIMESTAMP '2021-05-05 08:30:00', TIMESTAMP '2021-05-05 11:30:00', 2, 'MD9000', 3, 7.75);

INSERT INTO parking_sessions VALUES
  (6, TIMESTAMP '2021-05-06 12:00:00', TIMESTAMP '2021-05-06 15:00:00', 1, 'LY2343', 3, 10.00);

INSERT INTO payment_transaction VALUES
  (1, 50.00, 2, 1622947013, 1);

INSERT INTO payment_transaction VALUES
  (2, 25.75, 1, 1622947425, 2);

INSERT INTO payment_transaction VALUES
  (3, 60.25, 3, 1622947898, 3);

INSERT INTO payment_transaction VALUES
  (4, 75.50, 2, 1622948376, 4);

INSERT INTO payment_transaction VALUES
  (5, 35.75, 1, 1622948803, 5);

INSERT INTO payment_transaction VALUES
  (6, 50.00, 2, 1622949189, 6);

INSERT INTO message VALUES
  (1, 'Reminder: Your parking session will expire in 15 minutes.', TIMESTAMP '2021-05-01 13:45:00', 1);

INSERT INTO message VALUES
  (2, 'Thank you for using our parking services. We value your feedback.', TIMESTAMP '2021-05-02 14:30:00', 1);

INSERT INTO message VALUES
  (3, 'Your parking session has started.', TIMESTAMP '2021-05-03 09:00:00', 2);

INSERT INTO message VALUES
  (4, 'Your parking session will end in 15 minutes.', TIMESTAMP '2021-05-04 15:45:00', 2);

INSERT INTO message VALUES
  (5, 'Reminder: Your parking session will expire in 30 minutes.', TIMESTAMP '2021-05-05 11:00:00', 3);

INSERT INTO message VALUES
  (6, 'Please provide feedback regarding your parking experience.', TIMESTAMP '2021-05-06 14:15:00', 3);

INSERT INTO parking_zone VALUES
  (1, 'Zone A', 4,date '2021-05-02', date '2021-05-02', TIMESTAMP '2021-05-01 00:00:00', TIMESTAMP '2021-05-01 23:59:59', 2);

INSERT INTO parking_zone VALUES
  (2, 'Zone B', 3,date '2021-05-02', date '2021-05-02', TIMESTAMP '2021-05-02 00:00:00', TIMESTAMP '2021-05-02 23:59:59', 1);

INSERT INTO parking_zone VALUES
  (3, 'Zone C', 5, date '2021-05-03', date '2021-05-03', TIMESTAMP '2021-05-03 00:00:00', TIMESTAMP '2021-05-03 23:59:59', 1); 
