# 🚚 Ekart Logistics Optimization & Delivery Analytics – Flipkart

[![SQL](https://img.shields.io/badge/MySQL-8.0-blue?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Workbench](https://img.shields.io/badge/MySQL_Workbench-8.0-orange?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/products/workbench/)
[![Domain](https://img.shields.io/badge/Domain-Supply_Chain_&_Logistics-green?style=for-the-badge)]()

---

## 📌 Executive Summary
Ekart Logistics (the supply chain arm of Flipkart) handles millions of daily order shipments across metros, Tier-2, and Tier-3 cities in India. As order volumes scale—especially during festive sales—traffic disruptions, warehouse processing bottlenecks, and route inefficiencies directly impact customer satisfaction and operational costs.

This project delivers an end-to-end **Data-Driven SQL Analytics System** evaluating delivery delays, warehouse fulfillment throughput, route travel efficiency, and delivery agent performance. The pipeline cleanses transactional logs, applies advanced window functions, CTEs, and aggregations to answer critical supply chain questions and recommend operational optimizations.

---

## 🗄️ Database Architecture & Data Schema

The relational database schema is structured across 5 primary datasets capturing order lifecycles, route demographics, warehouse capacities, agent profiles, and live checkpoint tracking:

```sql
CREATE DATABASE IF NOT EXISTS flipkart_logistics;
USE flipkart_logistics;

-- 1. Orders Dataset
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

-- 2. Routes Dataset
CREATE TABLE IF NOT EXISTS routes (
    Route_ID VARCHAR(10),
    Start_Location VARCHAR(100),
    End_Location VARCHAR(100),
    Distance_KM INT,
    Average_Travel_Time_Min INT,
    Traffic_Delay_Min INT
);

-- 3. Warehouses Dataset
CREATE TABLE IF NOT EXISTS warehouses (
    Warehouse_ID VARCHAR(10),
    Warehouse_Name VARCHAR(150),
    City VARCHAR(100),
    Processing_Capacity INT,
    Average_Processing_Time_Min INT
);

-- 4. Delivery Agents Dataset
CREATE TABLE IF NOT EXISTS delivery_agents (
    Agent_ID VARCHAR(10),
    Agent_Name VARCHAR(100),
    Route_ID VARCHAR(10),
    Avg_Speed_KMPH DECIMAL(5,2),
    On_Time_Delivery_Percentage DECIMAL(5,2),
    Experience_Years DECIMAL(4,1)
);

-- 5. Shipment Tracking Dataset
CREATE TABLE IF NOT EXISTS shipment_tracking (
    Tracking_ID VARCHAR(15),
    Order_ID VARCHAR(20),
    Checkpoint VARCHAR(100),
    Checkpoint_Time DATETIME,
    Delay_Reason VARCHAR(100),
    Delay_Minutes INT
);
```

## 🛠️ Data Cleaning & Validation (Task 1)
Before executing analytics, data hygiene checks were conducted:

* **Duplicate Check:** Verified uniqueness of Order_ID across records; zero duplicate keys identified.

* **NULL Inspection:** Inspected Traffic_Delay_Min across routes; confirmed no missing/NULL values.

* **Format Consistency:** Enforced ISO date formats (YYYY-MM-DD).

* **Logical Consistency:** Validated shipment dates ensuring no Actual_Delivery_Date preceded Order_Date.

```sql
-- Check Duplicates in Orders Table
SELECT Order_ID, COUNT(*) 
FROM orders 
GROUP BY Order_ID 
HAVING COUNT(*) > 1;

-- Check NULL Values in Routes Table
SELECT * 
FROM routes 
WHERE Traffic_Delay_Min IS NULL;

-- Date Logic Check
SELECT * 
FROM orders 
WHERE Actual_Delivery_Date < Order_Date;
```

## 📐 Business Analysis, SQL Queries & Insights
### Task 2: Delivery Delay Analysis
1. Calculate Delivery Delay (in Days) per Order
```sql
SELECT Order_ID, DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS Delay_Days
FROM orders
LIMIT 10;
```
<img width="220" height="200" alt="image" src="https://github.com/user-attachments/assets/6c3da128-f590-4ee9-ae15-acdfbd229b4a" />


2. Top 10 Delayed Routes by Average Delay Days
```sql
SELECT Route_ID, AVG(DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date)) AS avg_delay_days
FROM orders
GROUP BY Route_ID
ORDER BY avg_delay_days DESC
LIMIT 10;
```
<img width="220" height="200" alt="image" src="https://github.com/user-attachments/assets/4d412f95-b9d7-41de-b8a7-9c20af646292" />

3. Order Delay Rankings Within Each Warehouse
```sql
SELECT 
    Order_ID, 
    Warehouse_ID, 
    DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS Delay_Days,
    RANK() OVER(PARTITION BY Warehouse_ID ORDER BY DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) DESC) AS rank_in_warehouse
FROM orders;
```
<img width="410" height="320" alt="image" src="https://github.com/user-attachments/assets/42d29753-c145-4259-b851-f9620ea630be" />


### Task 3: Route Optimization Insights
1. Distance-to-Time Efficiency Ratio & Route Delays
```sql
SELECT 
    o.Route_ID, 
    AVG(DATEDIFF(o.Actual_Delivery_Date, o.Order_Date)) AS avg_delivery_time_days,
    AVG(r.Traffic_Delay_Min) AS avg_traffic_delay,
    (r.Distance_KM / r.Average_Travel_Time_Min) AS efficiency_ratio
FROM orders o
JOIN routes r ON o.Route_ID = r.Route_ID
GROUP BY o.Route_ID, r.Distance_KM, r.Average_Travel_Time_Min
ORDER BY o.Route_ID;
```
<img width="440" height="350" alt="image" src="https://github.com/user-attachments/assets/6051ea29-8bd7-4478-aefc-4823b65787ca" />


2. Worst 3 Routes by Efficiency Ratio
```sql
SELECT Route_ID, (Distance_KM / Average_Travel_Time_Min) AS efficiency_ratio
FROM routes
ORDER BY efficiency_ratio ASC
LIMIT 3;
```
<img width="270" height="100" alt="image" src="https://github.com/user-attachments/assets/81633cb4-28d3-41ac-8aca-41a7fc87e4b9" />


3. Routes with >20% Delayed Shipments
```sql
SELECT 
    Route_ID,
    SUM(CASE WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END) AS delayed_orders,
    COUNT(*) AS total_orders,
    ROUND(SUM(CASE WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END)* 100 / COUNT(*), 2) AS delay_percentage
FROM orders
GROUP BY Route_ID
HAVING delay_percentage > 20;
```
<img width="370" height="300" alt="image" src="https://github.com/user-attachments/assets/626a7b38-4129-4ce1-a9e5-86cc1f775370" />


### Task 4: Warehouse Performance & Bottlenecks
1. Top 3 Warehouses with Highest Processing Time
```sql
SELECT Warehouse_ID, Warehouse_Name, Average_Processing_Time_Min
FROM warehouses
ORDER BY Average_Processing_Time_Min DESC
LIMIT 3;
```
<img width="700" height="90" alt="image" src="https://github.com/user-attachments/assets/184a9d35-b687-4898-ba1a-a0cf470a0feb" />


2. Calculate total vs. delayed shipments for each warehouse
```sql
SELECT
  Warehouse_ID, 
  COUNT(*) AS total_shipments,
  SUM(CASE WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END) AS delayed_shipments
FROM orders
GROUP BY Warehouse_ID;
```
<img width="400" height="250" alt="image" src="https://github.com/user-attachments/assets/7623ea8d-cc9a-4be3-9136-91afab700a42" />


3. Bottleneck Warehouses Identification (Using CTE)
```sql
WITH fly AS (SELECT AVG(Average_Processing_Time_Min) AS global_average
	FROM warehouses)
SELECT w.Warehouse_ID, w.Warehouse_Name, w.Average_Processing_Time_Min
FROM warehouses AS w, fly AS f
WHERE w.Average_Processing_Time_Min > f.global_average
```
<img width="510" height="140" alt="image" src="https://github.com/user-attachments/assets/03d3bd8d-f616-46bb-ba18-cfd6f212217d" />


### Task 5: Delivery Agent Performance
1. Agent Speed Comparison (Top 5 vs. Bottom 5)
```sql
SELECT 
    AVG(temp1.Avg_Speed_KMPH) AS Top_5_Avg_Speed,
    AVG(temp2.Avg_Speed_KMPH) AS Bottom_5_Avg_Speed
FROM
    (SELECT Avg_Speed_KMPH FROM delivery_agents ORDER BY Avg_Speed_KMPH DESC LIMIT 5) AS temp1,
    (SELECT Avg_Speed_KMPH FROM delivery_agents ORDER BY Avg_Speed_KMPH ASC LIMIT 5) AS temp2;
```
<img width="250" height="70" alt="image" src="https://github.com/user-attachments/assets/ccb35919-d6be-438c-a66e-4846f12cee76" />


2. Low Performing Agents Identification (<80% On-Time)
```sql
SELECT 
    Agent_ID,
    ROUND(SUM(CASE WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1 ELSE 0 END)*100.0 / COUNT(*), 2) AS on_time_delivery_percentage
FROM orders
GROUP BY Agent_ID
HAVING on_time_delivery_percentage < 80;
```
<img width="300" height="230" alt="image" src="https://github.com/user-attachments/assets/c7167b73-593d-4819-bed2-d76d1532eb42" />


### Task 6: Shipment Tracking Diagnostics
1. Primary Causes of Delay
```sql
SELECT Delay_Reason, COUNT(*) AS frequency
FROM shipment_tracking
WHERE Delay_Reason <> 'None'
GROUP BY Delay_Reason
ORDER BY frequency DESC;
```
<img width="180" height="100" alt="image" src="https://github.com/user-attachments/assets/fee49244-fa67-47ca-afd2-3f6afb0682e9" />


2. Orders with Multiple Delayed Checkpoints (>2 Delays)
```sql
SELECT Order_ID, COUNT(*) AS Delayed_Checkpoints_Count
FROM shipment_tracking
WHERE Delay_Minutes > 0
GROUP BY Order_ID
HAVING COUNT(*) > 2;
```
<img width="280" height="300" alt="image" src="https://github.com/user-attachments/assets/b212f7f0-ee87-499e-8ac1-4fd066150478" />


### Task 7: Advanced KPI Reporting
1. Overall Ekart Network On-Time Delivery %
```sql
SELECT 
    ROUND((SUM(CASE WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS on_time_delivery_percentage
FROM orders;
```
* Network On-Time Delivery Benchmark: 72.67%

2. Regional Average Delivery Delay (Origins)
```sql
SELECT 
    r.Start_Location, 
    AVG(DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date)) AS Avg_delivery_delay
FROM orders o
JOIN routes r ON o.Route_ID = r.Route_ID
WHERE o.Actual_Delivery_Date > o.Expected_Delivery_Date
GROUP BY r.Start_Location
ORDER BY Avg_delivery_delay DESC;
```
<img width="420" height="170" alt="image" src="https://github.com/user-attachments/assets/d98cb242-a14c-42ee-ac5f-e9ead3992137" />

## 💡 Strategic Recommendations for Flipkart / Ekart
#### Warehouse Processing Bottlenecks (WH_10 Chennai & WH_09 Hyderabad):
Implement automated inbound sorting lines to reduce fulfillment latency from 110+ minutes down to the network mean (~85 mins).

#### Route Re-Engineering for RT_13 & RT_05:
RT_13 experiences an alarming 54.55% delay rate. Introduce dynamic GPS-based traffic rerouting and shift dispatch times away from peak congestion hours.

#### Delivery Agent Coaching & Capability Support:
Address the 17.7 KMPH speed gap between top and bottom performers. Pair low-performing agents with senior mentors and optimize route dispatching based on traffic difficulty.

#### Mitigating Primary Delay Causes:
Traffic accounts for 387 recorded tracking delays. Integrate real-time routing API alerts directly into the Ekart Agent Mobile App.

## 📁 Repository Structure
```text
flipkart-ekart-logistics-sql-analytics/
├── datasets/                                 # Centralized CSV source files
│   ├── orders.csv
│   ├── routes.csv
│   ├── warehouses.csv
│   ├── delivery_agents.csv
│   └── shipment_tracking.csv
├── scripts/                                  # Modular SQL Executables
│   ├── 01_schema_definition.sql              # Database DDL & Schema Creation
│   ├── 02_data_cleaning.sql                  # Data Hygiene & Validation Scripts
│   └── 03_logistics_analytics.sql            # Core SQL Analytical Queries (Tasks 2 to 7)
├── docs/                                     # Documentation & Reports
│   └── Flipkart_Logistics_KPI_Report.pptx     # Executive Presentation Deck
└── README.md                                 # Master Portfolio Documentation
```

## 👤 Author & Contact
Harsh Srivastav

**Role:** Data Analyst / BI Developer

**Domain Focus:** Supply Chain, Logistics Analytics & SQL Database Engineering
