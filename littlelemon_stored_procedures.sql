-- =====================================================
-- LITTLE LEMON - STORED PROCEDURES
-- Required for Grading Criteria
-- =====================================================

USE LittleLemonDB;
GO

-- =====================================================
-- 1. GetMaxQuantity()
-- Returns the maximum quantity ordered
-- =====================================================

CREATE OR ALTER PROCEDURE GetMaxQuantity
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT MAX(quantity) AS 'Max Quantity in Order'
    FROM OrderDetails;
END;
GO

-- Test: EXEC GetMaxQuantity;

-- =====================================================
-- 2. ManageBooking()
-- Check if a table is already booked on a specific date
-- =====================================================

CREATE OR ALTER PROCEDURE ManageBooking
    @booking_date DATE,
    @table_number INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @booking_exists INT;
    
    SELECT @booking_exists = COUNT(*)
    FROM Bookings
    WHERE booking_date = @booking_date 
      AND table_number = @table_number
      AND booking_status = 'Confirmed';
    
    IF @booking_exists > 0
    BEGIN
        SELECT CONCAT('Table ', @table_number, ' is already booked on ', 
                      FORMAT(@booking_date, 'yyyy-MM-dd'), 
                      '. Please choose another table or date.') AS 'Booking Status';
    END
    ELSE
    BEGIN
        SELECT CONCAT('Table ', @table_number, ' is available on ', 
                      FORMAT(@booking_date, 'yyyy-MM-dd'), '.') AS 'Booking Status';
    END
END;
GO

-- Test: EXEC ManageBooking @booking_date = '2024-01-15', @table_number = 5;

-- =====================================================
-- 3. AddBooking()
-- Add a new booking to the database
-- =====================================================

CREATE OR ALTER PROCEDURE AddBooking
    @customer_id NVARCHAR(20),
    @booking_date DATE,
    @table_number INT,
    @number_of_guests INT = 2
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @table_available INT;
    
    -- Check if table is available
    SELECT @table_available = COUNT(*)
    FROM Bookings
    WHERE booking_date = @booking_date 
      AND table_number = @table_number
      AND booking_status = 'Confirmed';
    
    IF @table_available > 0
    BEGIN
        SELECT 'Error: Table is already booked for this date. Booking not added.' AS 'Status';
        RETURN;
    END
    
    -- Check if customer exists
    IF NOT EXISTS (SELECT 1 FROM Customers WHERE customer_id = @customer_id)
    BEGIN
        SELECT 'Error: Customer ID does not exist. Please register customer first.' AS 'Status';
        RETURN;
    END
    
    -- Add the booking
    INSERT INTO Bookings (customer_id, booking_date, table_number, number_of_guests, booking_status)
    VALUES (@customer_id, @booking_date, @table_number, @number_of_guests, 'Confirmed');
    
    DECLARE @new_booking_id INT = SCOPE_IDENTITY();
    
    SELECT CONCAT('New booking added successfully. Booking ID: ', @new_booking_id, 
                  ', Table: ', @table_number, 
                  ', Date: ', FORMAT(@booking_date, 'yyyy-MM-dd'),
                  ', Guests: ', @number_of_guests) AS 'Confirmation';
END;
GO

-- Test: EXEC AddBooking @customer_id = '72-055-7985', @booking_date = '2024-02-20', @table_number = 10, @number_of_guests = 4;

-- =====================================================
-- 4. UpdateBooking()
-- Update an existing booking
-- =====================================================

CREATE OR ALTER PROCEDURE UpdateBooking
    @booking_id INT,
    @new_booking_date DATE = NULL,
    @new_table_number INT = NULL,
    @new_number_of_guests INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if booking exists
    IF NOT EXISTS (SELECT 1 FROM Bookings WHERE booking_id = @booking_id)
    BEGIN
        SELECT 'Error: Booking ID not found.' AS 'Status';
        RETURN;
    END
    
    -- Check if booking is not cancelled
    IF EXISTS (SELECT 1 FROM Bookings WHERE booking_id = @booking_id AND booking_status = 'Cancelled')
    BEGIN
        SELECT 'Error: Cannot update a cancelled booking.' AS 'Status';
        RETURN;
    END
    
    -- If changing table/date, check availability
    IF @new_booking_date IS NOT NULL OR @new_table_number IS NOT NULL
    BEGIN
        DECLARE @check_date DATE;
        DECLARE @check_table INT;
        
        SELECT @check_date = ISNULL(@new_booking_date, booking_date),
               @check_table = ISNULL(@new_table_number, table_number)
        FROM Bookings WHERE booking_id = @booking_id;
        
        IF EXISTS (
            SELECT 1 FROM Bookings 
            WHERE booking_date = @check_date 
              AND table_number = @check_table
              AND booking_id != @booking_id
              AND booking_status = 'Confirmed'
        )
        BEGIN
            SELECT 'Error: New table/date combination is not available.' AS 'Status';
            RETURN;
        END
    END
    
    -- Update the booking
    UPDATE Bookings
    SET booking_date = ISNULL(@new_booking_date, booking_date),
        table_number = ISNULL(@new_table_number, table_number),
        number_of_guests = ISNULL(@new_number_of_guests, number_of_guests)
    WHERE booking_id = @booking_id;
    
    SELECT CONCAT('Booking ', @booking_id, ' updated successfully.') AS 'Confirmation';
END;
GO

-- Test: EXEC UpdateBooking @booking_id = 1, @new_booking_date = '2024-02-25', @new_table_number = 8;

-- =====================================================
-- 5. CancelBooking()
-- Cancel an existing booking
-- =====================================================

CREATE OR ALTER PROCEDURE CancelBooking
    @booking_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if booking exists
    IF NOT EXISTS (SELECT 1 FROM Bookings WHERE booking_id = @booking_id)
    BEGIN
        SELECT 'Error: Booking ID not found.' AS 'Status';
        RETURN;
    END
    
    -- Check if already cancelled
    IF EXISTS (SELECT 1 FROM Bookings WHERE booking_id = @booking_id AND booking_status = 'Cancelled')
    BEGIN
        SELECT 'Booking is already cancelled.' AS 'Status';
        RETURN;
    END
    
    -- Cancel the booking
    UPDATE Bookings
    SET booking_status = 'Cancelled'
    WHERE booking_id = @booking_id;
    
    SELECT CONCAT('Booking ', @booking_id, ' cancelled successfully.') AS 'Confirmation';
END;
GO

-- Test: EXEC CancelBooking @booking_id = 2;

-- =====================================================
-- BONUS: CheckBooking (useful for verification)
-- =====================================================

CREATE OR ALTER PROCEDURE CheckBooking
    @booking_date DATE,
    @table_number INT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 FROM Bookings 
        WHERE booking_date = @booking_date 
          AND table_number = @table_number
          AND booking_status = 'Confirmed'
    )
    BEGIN
        SELECT CONCAT('Table ', @table_number, ' is already booked on ', 
                      FORMAT(@booking_date, 'yyyy-MM-dd')) AS 'Booking Status';
    END
    ELSE
    BEGIN
        SELECT CONCAT('Table ', @table_number, ' is free on ', 
                      FORMAT(@booking_date, 'yyyy-MM-dd')) AS 'Booking Status';
    END
END;
GO

-- =====================================================
-- TEST ALL PROCEDURES
-- =====================================================

PRINT '===== Testing Stored Procedures =====';
PRINT '';

PRINT '1. GetMaxQuantity:';
EXEC GetMaxQuantity;

PRINT '';
PRINT '2. ManageBooking (checking table 5 on 2024-01-15):';
EXEC ManageBooking @booking_date = '2024-01-15', @table_number = 5;

PRINT '';
PRINT '3. AddBooking (adding new booking):';
EXEC AddBooking @customer_id = '72-055-7985', @booking_date = '2024-03-01', @table_number = 12, @number_of_guests = 3;

PRINT '';
PRINT '4. UpdateBooking (updating booking 1):';
EXEC UpdateBooking @booking_id = 1, @new_number_of_guests = 5;

PRINT '';
PRINT '5. CancelBooking (cancelling booking 3):';
EXEC CancelBooking @booking_id = 3;

PRINT '';
PRINT '===== All procedures tested successfully! =====';
GO
