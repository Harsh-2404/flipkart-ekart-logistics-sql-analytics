USE flipkart_logistics;

-- Check Duplicates in Orders Table
SELECT Order_ID, COUNT(*) AS `Duplicate`
FROM orders
GROUP BY Order_ID
HAVING COUNT(*) > 1;

-- Check NULL Values in Routes Table
SELECT * 
FROM routes 
WHERE Traffic_Delay_Min IS NULL;

-- Date Logic Check (Actual Delivery should not be earlier than Order Date)
SELECT * 
FROM orders 
WHERE Actual_Delivery_Date < Order_Date;