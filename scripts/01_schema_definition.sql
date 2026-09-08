CREATE DATABASE IF NOT EXISTS flipkart_logistics;
USE flipkart_logistics;

-- 1. Orders Dataset Table
CREATE TABLE IF NOT EXISTS orders (
    Order_ID VARCHAR(20),
    Warehouse_ID VARCHAR(10),
    Route_ID VARCHAR(10),
    Agent_ID VARCHAR(10),
    Order_Date DATE,
    Expected_Delivery_Date DATE,
    Actual_Delivery_Date DATE,
    Status VARCHAR(50),
    Order_Value DECIMAL(10,2)
);

-- 2. Routes Dataset Table
CREATE TABLE IF NOT EXISTS routes (
    Route_ID VARCHAR(10),
    Start_Location VARCHAR(100),
    End_Location VARCHAR(100),
    Distance_KM INT,
    Average_Travel_Time_Min INT,
    Traffic_Delay_Min INT
);

-- 3. Warehouses Dataset Table
CREATE TABLE IF NOT EXISTS warehouses (
    Warehouse_ID VARCHAR(10),
    Warehouse_Name VARCHAR(150),
    City VARCHAR(100),
    Processing_Capacity INT,
    Average_Processing_Time_Min INT
);

-- 4. Delivery Agents Dataset Table
CREATE TABLE IF NOT EXISTS delivery_agents (
    Agent_ID VARCHAR(10),
    Agent_Name VARCHAR(100),
    Route_ID VARCHAR(10),
    Avg_Speed_KMPH DECIMAL(5,2),
    On_Time_Delivery_Percentage DECIMAL(5,2),
    Experience_Years DECIMAL(4,1)
);

-- 5. Shipment Tracking Dataset Table
CREATE TABLE IF NOT EXISTS shipment_tracking (
    Tracking_ID VARCHAR(15),
    Order_ID VARCHAR(20),
    Checkpoint VARCHAR(100),
    Checkpoint_Time DATETIME,
    Delay_Reason VARCHAR(100),
    Delay_Minutes INT
);