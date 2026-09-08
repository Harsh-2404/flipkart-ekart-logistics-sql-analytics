-- -------------------------- TASK:- 2 --------------------------------------

# 1. CALCULATE DELIVERY DELAY (IN DAYS)
SELECT Order_ID, DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS Delay_Days
FROM orders
LIMIT 10;


# 2. TOP 10 DELAYED ROUTES
SELECT Route_ID, AVG(DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date)) AS avg_delay_days
FROM orders
GROUP BY Route_ID
ORDER BY avg_delay_days DESC
LIMIT 10;


# 3. RANK ORDERS BY DELAY (WINDOW FUNCTION)

SELECT Order_ID, Warehouse_ID, DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS Delay_Days,
RANK() OVER(PARTITION BY Warehouse_ID ORDER BY DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) DESC) AS rank_in_warehouse
FROM orders;





-- -------------------------- TASK:- 3 --------------------------------------

# 1. FOR EACH ROUTE CALCULATE METRICS

SELECT o.Route_ID, AVG(DATEDIFF(o.Actual_Delivery_Date, o.Order_Date)) AS avg_delivery_time_days,
AVG(r.Traffic_Delay_Min) AS avg_traffic_delay,
(r.Distance_KM / r.Average_Travel_Time_Min) AS efficiency_ratio
FROM orders o
JOIN routes r
ON o.Route_ID = r.Route_ID
GROUP BY o.Route_ID, r.Distance_KM, r.Average_Travel_Time_Min  # non-aggregated columns like (r.Distance_KM & r.Average_Travel_Time_Min) should always be in GROUP BY Clause
ORDER BY o.Route_ID;



# 2. WORST 3 ROUTES

SELECT Route_ID, (Distance_KM / Average_Travel_Time_Min) AS efficiency_ratio
FROM routes
ORDER BY efficiency_ratio ASC
LIMIT 3;



# 3. ROUTES WITH >20% DELAYED SHIPMENTS

SELECT Route_ID,
SUM(CASE 
	WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END) AS delayed_orders,
COUNT(*) AS total_orders,
ROUND(SUM(CASE 
	WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END)* 100 / COUNT(*), 2) AS delay_percentage
FROM orders
GROUP BY Route_ID
HAVING delay_percentage > 20;



# 4. RECOMMENDATION
	# 1. Routes with low efficiency (such as RT_13, RT_14, RT_03, RT_17) should be improved by optimizing route planning and selecting shorter or faster paths.
	# 2. Routes with high traffic delays (like RT_08, RT_15, RT_17, RT_09) should use alternate routes and avoid peak traffic hours to reduce congestion(overcrowding).
	# 3. Routes experiencing both high delay and high traffic (e.g., RT_15, RT_17) requires advanced traffic management strategies such as adjust delivery timings (like early morning or at night) and apply dynamic routing (change route during travel).
	# 4. Routes with high delivery time (such as RT_02, RT_16) should be improving by assigning experienced agents and improving warehouse processing efficiency.
	# 5. High-performing routes (like RT_10. RT_12, RT_19) should be used as benchmarks for optimizing other routes.




-- -------------------------- TASK:- 4 --------------------------------------

# 1. TOP 3 WAREHOUSES (HIGHEST PROCESSING TIME)

SELECT Warehouse_ID, Warehouse_Name, Average_Processing_Time_Min
FROM warehouses
ORDER BY Average_Processing_Time_Min DESC
LIMIT 3;



# 2. TOTAL VS DELAYED SHIPMENTS

SELECT Warehouse_ID, COUNT(*) AS total_shipments,
SUM(CASE WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END) AS delayed_shipments
FROM orders
GROUP BY Warehouse_ID;



# 3. BOTTLENECK WAREHOUSES (CTE USE)

WITH fly AS (
	SELECT AVG(Average_Processing_Time_Min) AS global_average
    FROM warehouses
)
SELECT w.Warehouse_ID, w.Warehouse_Name, w.Average_Processing_Time_Min
FROM warehouses AS w, fly AS f
WHERE w.Average_Processing_Time_Min > f.global_average;



# 4. RANK WAREHOUSES (ON-TIME DELIVERY %)

SELECT Warehouse_ID,
ROUND(
		SUM(CASE
				WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1
                ELSE 0
                END)*100 / COUNT(*), 2
	) AS on_time_delivery_percentage,
RANK() OVER(ORDER BY SUM(CASE WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1 ELSE 0 END)*100 / COUNT(*) DESC) AS performance_rank
FROM orders
GROUP BY Warehouse_ID;

-- -------------------------- OR ---------------------------------

WITH warehouse_rank AS (
			SELECT Warehouse_ID,
            ROUND(
					SUM(CASE WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1 ELSE 0 END)*100 / COUNT(*), 2
				)AS on_time_delivery_percentage
            FROM orders
            GROUP BY Warehouse_ID
)
SELECT Warehouse_ID, on_time_delivery_percentage, RANK() OVER(ORDER BY on_time_delivery_percentage DESC) AS performance_rank
FROM warehouse_rank;





-- ------------------------------ TASK:- 5 --------------------------------------
# 1. RANK AGENTS (PER ROUTE)

WITH fly AS (
	SELECT Agent_ID, Route_ID,
    ROUND(
			SUM(CASE
					WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1
                    ELSE 0
                    END)*100 / COUNT(*),2
		) AS on_time_delivery_percentage,
    DENSE_RANK() OVER(
						PARTITION BY Route_ID
                        ORDER BY (
						SUM(CASE
                        WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1
                        ELSE 0
                        END)*100 / COUNT(*)) DESC) AS performance_rank
    FROM orders
    GROUP BY Route_ID, Agent_ID
)
SELECT Agent_ID, Route_ID, on_time_delivery_percentage, performance_rank
FROM fly;

-- -------------------------- OR ---------------------------------

SELECT Agent_ID, Route_ID,
ROUND(
		SUM(CASE
			WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1
            ELSE 0
            END)*100 / COUNT(*),2	
		) AS on_time_delivery_percentage,
DENSE_RANK() OVER(
			PARTITION BY Route_ID
            ORDER BY (
            SUM(CASE
				WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1
                ELSE 0
                END)*100 / COUNT(*)) DESC) AS performance_rank
FROM orders
GROUP BY Route_ID, Agent_ID;




# 2. LOW PERFORMING AGENTS (<80%)

SELECT Agent_ID,
	   ROUND(
			SUM(CASE
					WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1
                    ELSE 0
                    END)*100 / COUNT(*),2
		) AS on_time_delivery_percentage
FROM orders
GROUP BY Agent_ID
HAVING on_time_delivery_percentage < 80;




# 3. SPEED COMPARISON (TOP 5 vs BOTTOM 5)     

SELECT 
	AVG(temp1.Avg_Speed_KMPH) AS Top_5_Avg_Speed,
	AVG(temp2.Avg_Speed_KMPH) AS Bottom_5_Avg_Speed
FROM
	(SELECT Avg_Speed_KMPH
    FROM delivery_agents
    ORDER BY Avg_Speed_KMPH DESC
    LIMIT 5) AS temp1,
    
    (SELECT Avg_Speed_KMPH
    FROM delivery_agents
    ORDER BY Avg_Speed_KMPH ASC
    LIMIT 5) AS temp2;




# 4. Suggest training or workload balancing strategies for low performers

	# 1. Targeted Training Program: Provide route specific training for agents with 0 – 40% delivery performance. Agents like AG_020, AG_034, AG_011 need immediate training and needs to focus on time management, route optimization, handling delays. 
	# 2. Mentorship by Top Performers: Pair low performers with high performers (like AG_017, AG_026, AG_030). This improves real-world learning faster than theory.
	# 3. Workload Balancing: Reduce workload on low performers initially and assign shorter routes and less complex deliveries to low performers and then gradually increase workload after improvement.
	# 4. Route Optimization: Some routes may be harder (like traffic, distance) so reassign difficult routes from low performers to experienced  agents.
	# 5. Speed Improvement Strategies: Since bottom agents have low avg speed (35 KMPH) so provide navigation tools (GPS optimization) and improve vehicle efficiency.





-- ------------------------------ TASK:- 6 --------------------------------------
# 1. For each order, list the last checkpoint and time

SELECT Order_ID, Checkpoint, Checkpoint_Time
FROM shipment_tracking
WHERE Checkpoint_Time IN (SELECT
						MAX(Checkpoint_Time)
						FROM shipment_tracking
						GROUP BY Order_ID);
                        
-- -------------------------- OR ---------------------------------
                        
SELECT order_id, checkpoint, checkpoint_time
FROM shipment_tracking st1
WHERE checkpoint_time = (
    SELECT MAX(st2.checkpoint_time)
    FROM shipment_tracking st2
    WHERE st1.order_id = st2.order_id
);



# 2. Find the most common delay reasons (excluding None).

SELECT Delay_Reason, COUNT(*) AS frequency
FROM shipment_tracking
WHERE Delay_Reason <> 'None'
GROUP BY Delay_Reason
ORDER BY frequency DESC;


# 3. Identify orders with >2 delayed checkpoints

SELECT Order_ID, COUNT(*) AS Delayed_Checkpoints_Count
FROM shipment_tracking
WHERE Delay_Minutes > 0
GROUP BY Order_ID
HAVING COUNT(*) > 2;





-- ------------------------------ TASK:- 7 --------------------------------------
# 1. Average Delivery Delay per Region (Start_Location).

SELECT r.Start_Location, SUM(DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date)) AS total_delivery_delay, COUNT(*) AS freq,
AVG(DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date)) AS Avg_delivery_delay
FROM orders o
JOIN routes r
ON o.Route_ID = r.Route_ID
WHERE o.Actual_Delivery_Date > o.Expected_Delivery_Date
GROUP BY r.Start_Location
ORDER BY Avg_delivery_delay DESC;



# 2. On-Time Delivery % = (Total On-Time Deliveries / Total Deliveries) * 100.

SELECT 
    ROUND(
        (SUM(CASE 
                WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1 
                ELSE 0 
            END) * 100.0) / COUNT(*), 
    2) AS on_time_delivery_percentage
FROM orders;



# 3. Average Traffic Delay per Route.

SELECT
	Route_ID,
    Start_Location,
    End_Location,
	AVG(Traffic_Delay_Min) AS Avg_Traffic_Delay
FROM routes
GROUP BY Route_ID, Start_Location, End_Location;