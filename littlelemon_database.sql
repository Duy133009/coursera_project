-- =====================================================
-- LITTLE LEMON DATABASE - SQL SERVER
-- Restaurant Management System
-- =====================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'LittleLemonDB')
    DROP DATABASE LittleLemonDB;
GO

CREATE DATABASE LittleLemonDB;
GO

USE LittleLemonDB;
GO

-- =====================================================
-- LOOKUP TABLES
-- =====================================================

-- Cuisines
CREATE TABLE Cuisines (
    cuisine_id INT IDENTITY(1,1) PRIMARY KEY,
    cuisine_name NVARCHAR(100) NOT NULL UNIQUE
);
GO

-- Countries
CREATE TABLE Countries (
    country_id INT IDENTITY(1,1) PRIMARY KEY,
    country_name NVARCHAR(100) NOT NULL UNIQUE,
    country_code NVARCHAR(5)
);
GO

-- Cities
CREATE TABLE Cities (
    city_id INT IDENTITY(1,1) PRIMARY KEY,
    city_name NVARCHAR(100) NOT NULL,
    country_id INT NOT NULL,
    postal_code NVARCHAR(20),
    CONSTRAINT FK_Cities_Countries FOREIGN KEY (country_id) 
        REFERENCES Countries(country_id)
);
GO

-- =====================================================
-- MENU TABLES
-- =====================================================

-- Menu Items (Starters, Courses, Desserts, Drinks, Sides)
CREATE TABLE MenuItems (
    menu_item_id INT IDENTITY(1,1) PRIMARY KEY,
    item_name NVARCHAR(255) NOT NULL,
    item_type NVARCHAR(50) NOT NULL, -- 'Starter', 'Course', 'Dessert', 'Drink', 'Side'
    cuisine_id INT,
    price DECIMAL(10, 2) DEFAULT 0.00,
    CONSTRAINT FK_MenuItems_Cuisines FOREIGN KEY (cuisine_id) 
        REFERENCES Cuisines(cuisine_id),
    CONSTRAINT CHK_ItemType CHECK (item_type IN ('Starter', 'Course', 'Dessert', 'Drink', 'Side'))
);
GO

-- =====================================================
-- CUSTOMER & ORDER TABLES
-- =====================================================

-- Customers
CREATE TABLE Customers (
    customer_id NVARCHAR(20) PRIMARY KEY,
    customer_name NVARCHAR(150) NOT NULL,
    city_id INT,
    email NVARCHAR(100),
    phone NVARCHAR(20),
    created_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Customers_Cities FOREIGN KEY (city_id) 
        REFERENCES Cities(city_id)
);
GO

-- Orders
CREATE TABLE Orders (
    order_id NVARCHAR(20) PRIMARY KEY,
    customer_id NVARCHAR(20) NOT NULL,
    order_date DATE NOT NULL,
    delivery_date DATE,
    total_cost DECIMAL(12, 2) DEFAULT 0.00,
    sales DECIMAL(12, 2) DEFAULT 0.00,
    discount DECIMAL(5, 2) DEFAULT 0.00,
    delivery_cost DECIMAL(10, 2) DEFAULT 0.00,
    order_status NVARCHAR(20) DEFAULT 'Pending',
    created_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (customer_id) 
        REFERENCES Customers(customer_id)
);
GO

-- Order Details
CREATE TABLE OrderDetails (
    order_detail_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id NVARCHAR(20) NOT NULL,
    menu_item_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (order_id) 
        REFERENCES Orders(order_id) ON DELETE CASCADE,
    CONSTRAINT FK_OrderDetails_MenuItems FOREIGN KEY (menu_item_id) 
        REFERENCES MenuItems(menu_item_id)
);
GO

-- =====================================================
-- BOOKING TABLE (for Stored Procedures)
-- =====================================================

CREATE TABLE Bookings (
    booking_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id NVARCHAR(20) NOT NULL,
    booking_date DATE NOT NULL,
    table_number INT NOT NULL,
    number_of_guests INT DEFAULT 2,
    booking_status NVARCHAR(20) DEFAULT 'Confirmed',
    created_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Bookings_Customers FOREIGN KEY (customer_id) 
        REFERENCES Customers(customer_id),
    CONSTRAINT CHK_BookingStatus CHECK (booking_status IN ('Confirmed', 'Cancelled', 'Completed'))
);
GO

-- Staff Table (optional, for reference)
CREATE TABLE Staff (
    staff_id INT IDENTITY(1,1) PRIMARY KEY,
    staff_name NVARCHAR(150) NOT NULL,
    role NVARCHAR(50) NOT NULL,
    salary DECIMAL(10, 2)
);
GO

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX idx_orders_customer ON Orders(customer_id);
CREATE INDEX idx_orders_date ON Orders(order_date);
CREATE INDEX idx_bookings_date ON Bookings(booking_date);
CREATE INDEX idx_bookings_table ON Bookings(table_number);
GO

-- =====================================================
-- INSERT SAMPLE DATA
-- =====================================================

-- Cuisines
INSERT INTO Cuisines (cuisine_name) VALUES 
('Greek'), ('Italian'), ('Turkish'), ('Mexican'), ('French'), ('Japanese');
GO

-- Countries
INSERT INTO Countries (country_name, country_code) VALUES 
('China', 'CN'), ('North Korea', 'KP'), ('Peru', 'PE'), 
('United States', 'US'), ('Germany', 'DE'), ('Japan', 'JP');
GO

-- Cities
INSERT INTO Cities (city_name, country_id, postal_code) VALUES 
('Daruoyan', 1, '993-0031'),
('Ongjin', 2, '216282'),
('Quince Mil', 3, '663246'),
('New York', 4, '10001'),
('Berlin', 5, '10115');
GO

-- Menu Items
INSERT INTO MenuItems (item_name, item_type, cuisine_id, price) VALUES 
('Greek salad', 'Course', 1, 12.00),
('Pizza', 'Course', 2, 15.00),
('Bean soup', 'Course', 2, 10.00),
('Olives', 'Starter', 1, 6.00),
('Flatbread', 'Starter', 2, 5.00),
('Minestrone', 'Starter', 2, 8.00),
('Greek yoghurt', 'Dessert', 1, 7.00),
('Ice cream', 'Dessert', 2, 6.00),
('Cheesecake', 'Dessert', 2, 8.00),
('Athens White wine', 'Drink', 1, 15.00),
('Corfu Red Wine', 'Drink', 1, 18.00),
('Italian Coffee', 'Drink', 2, 5.00),
('Tapas', 'Side', 1, 8.00),
('Potato salad', 'Side', 2, 6.00),
('Bruschetta', 'Side', 2, 7.00);
GO

-- Sample Customers
INSERT INTO Customers (customer_id, customer_name, city_id) VALUES 
('72-055-7985', 'Laney Fadden', 1),
('65-353-0657', 'Giacopo Bramich', 2),
('90-876-6799', 'Lia Bonar', 3);
GO

-- Sample Orders
INSERT INTO Orders (order_id, customer_id, order_date, delivery_date, total_cost, sales, discount, delivery_cost) VALUES 
('54-366-6861', '72-055-7985', '2020-06-15', '2020-03-26', 125.00, 187.50, 20.00, 60.51),
('63-761-3686', '65-353-0657', '2020-08-25', '2020-07-17', 235.00, 352.50, 15.00, 96.75),
('65-351-6434', '90-876-6799', '2021-08-17', '2020-04-24', 75.00, 112.50, 10.52, 36.37);
GO

-- Sample Bookings
INSERT INTO Bookings (customer_id, booking_date, table_number, number_of_guests) VALUES 
('72-055-7985', '2024-01-15', 5, 4),
('65-353-0657', '2024-01-16', 3, 2),
('90-876-6799', '2024-01-17', 7, 6);
GO

-- =====================================================
-- VIEW: Order Summary
-- =====================================================

CREATE VIEW vw_OrderSummary AS
SELECT 
    o.order_id,
    o.order_date,
    c.customer_name,
    ct.city_name,
    co.country_name,
    o.total_cost,
    o.sales,
    o.discount,
    o.delivery_cost
FROM Orders o
INNER JOIN Customers c ON o.customer_id = c.customer_id
LEFT JOIN Cities ct ON c.city_id = ct.city_id
LEFT JOIN Countries co ON ct.country_id = co.country_id;
GO

PRINT 'LittleLemonDB created successfully!';
GO
