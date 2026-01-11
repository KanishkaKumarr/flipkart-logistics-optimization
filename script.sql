/*
   PROJECT: Logistics Optimization for Delivery Routes
   DATASET: Flipkart Logistics
   TOOL: SQLite
   */


/* =========================
   TASK 1: DATA CLEANING
   ========================= */

/* Task 1.1: Validate duplicate Order_ID records */
-- Check for duplicate Order_IDs
SELECT Order_ID, COUNT(*) AS cnt
FROM orders
GROUP BY Order_ID
HAVING cnt > 1;

/* Task 1.2: Check for NULL delivery status values */
SELECT *
FROM orders
WHERE Status IS NULL;

/* Task 1.3: Validate delivery date logic */
-- Actual delivery date should not be earlier than order date
SELECT *
FROM orders
WHERE Actual_Delivery_Date < Order_Date;

/* Task 1.4: Review delivery status consistency */
SELECT DISTINCT Status
FROM orders;


/* =========================
   TASK 2: DELIVERY ANALYSIS
   ========================= */

/* Task 2.1: Order status distribution */
SELECT Status, COUNT(*) AS Order_Count
FROM orders
GROUP BY Status;

/* Task 2.2: Average delivery delay (in days) */
SELECT
    AVG(julianday(Actual_Delivery_Date) - julianday(Expected_Delivery_Date))
        AS Avg_Delivery_Delay_Days
FROM orders;

/* Task 2.3: Rank orders by delay within each warehouse */
SELECT
    Order_ID,
    Warehouse_ID,
    (julianday(Actual_Delivery_Date) - julianday(Expected_Delivery_Date)) AS Delay_Days,
    RANK() OVER (
        PARTITION BY Warehouse_ID
        ORDER BY (julianday(Actual_Delivery_Date) - julianday(Expected_Delivery_Date)) DESC
    ) AS Delay_Rank
FROM orders;


/* =========================
   TASK 3: ROUTE ANALYSIS
   ========================= */

/* Task 3.1: Route-wise order volume */
SELECT Route_ID, COUNT(*) AS Total_Orders
FROM orders
GROUP BY Route_ID;

/* Task 3.2: Routes with highest average delivery delay */
SELECT
    Route_ID,
    AVG(julianday(Actual_Delivery_Date) - julianday(Expected_Delivery_Date))
        AS Avg_Delay_Days
FROM orders
GROUP BY Route_ID
ORDER BY Avg_Delay_Days DESC;

/* Task 3.3: Routes with high delay percentage */
SELECT
    Route_ID,
    (SUM(CASE WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)) AS Delay_Percentage
FROM orders
GROUP BY Route_ID;


/* Task 3.4: Route optimization recommendations */
-- (Business recommendation task – no SQL query required)


/* =========================
   TASK 4: WAREHOUSE ANALYSIS
   ========================= */

/* Task 4.1: Top 3 slowest warehouses by average delay */
SELECT
    Warehouse_ID,
    AVG(julianday(Actual_Delivery_Date) - julianday(Expected_Delivery_Date))
        AS Avg_Delay_Days
FROM orders
GROUP BY Warehouse_ID
ORDER BY Avg_Delay_Days DESC
LIMIT 3;

/* Task 4.2: Total vs delayed shipments per warehouse */
SELECT
    Warehouse_ID,
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END)
        AS Delayed_Orders
FROM orders
GROUP BY Warehouse_ID;

/* Task 4.3: Bottleneck warehouses (above average delay) */
WITH AvgDelay AS (
    SELECT AVG(julianday(Actual_Delivery_Date) - julianday(Expected_Delivery_Date)) AS Overall_Avg
    FROM orders
)
SELECT
    o.Warehouse_ID,
    AVG(julianday(o.Actual_Delivery_Date) - julianday(o.Expected_Delivery_Date)) AS Warehouse_Avg_Delay
FROM orders o, AvgDelay a
GROUP BY o.Warehouse_ID
HAVING Warehouse_Avg_Delay > a.Overall_Avg;

/* Task 4.4: Rank warehouses by on-time delivery percentage */
SELECT
    Warehouse_ID,
    (SUM(CASE WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)) AS On_Time_Percentage
FROM orders
GROUP BY Warehouse_ID
ORDER BY On_Time_Percentage DESC;


/* =========================
   TASK 5: DELIVERY AGENT PERFORMANCE
   ========================= */

/* Task 5.1: Total deliveries per agent */
SELECT Agent_ID, COUNT(*) AS Total_Deliveries
FROM orders
GROUP BY Agent_ID;

/* Task 5.2: Delay percentage per agent */
SELECT
    Agent_ID,
    (SUM(CASE WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)) AS Delay_Percentage
FROM orders
GROUP BY Agent_ID;

/* Task 5.3: Average deliveries per agent */
SELECT AVG(Total_Deliveries) AS Avg_Deliveries_Per_Agent
FROM (
    SELECT Agent_ID, COUNT(*) AS Total_Deliveries
    FROM orders
    GROUP BY Agent_ID
);

/* Task 5.4: Agent performance insights */
-- (Insight / recommendation task – no SQL query required)


/* =========================
   TASK 6: SHIPMENT TRACKING ANALYTICS
   ========================= */

/* Task 6.1: Last checkpoint per order */
SELECT
    Order_ID,
    MAX(Checkpoint_Time) AS Last_Checkpoint_Time
FROM shipment_tracking
GROUP BY Order_ID;

/* Task 6.2: Most common delay reasons (excluding None) */
SELECT
    Delay_Reason,
    COUNT(*) AS Occurrences
FROM shipment_tracking
WHERE Delay_Reason IS NOT NULL AND Delay_Reason <> 'None'
GROUP BY Delay_Reason
ORDER BY Occurrences DESC;

/* Task 6.3: Orders with more than 2 delayed checkpoints */
SELECT
    Order_ID,
    COUNT(*) AS Delayed_Checkpoints
FROM shipment_tracking
WHERE Delay_Reason IS NOT NULL AND Delay_Reason <> 'None'
GROUP BY Order_ID
HAVING COUNT(*) > 2;


/* =========================
   TASK 7: KPI REPORTING
   ========================= */

/* Task 7.1: Average delivery delay per warehouse */
SELECT
    o.Warehouse_ID,
    ROUND(AVG(s.Delay_Minutes), 2) AS Avg_Delivery_Delay_Minutes
FROM orders o
JOIN shipment_tracking s
    ON o.Order_ID = s.Order_ID
GROUP BY o.Warehouse_ID;

/* Task 7.2: On-time delivery percentage */
SELECT
    (SUM(CASE WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)) AS On_Time_Delivery_Percentage
FROM orders;

/* Task 7.3: Average traffic delay per route */
SELECT
    r.Route_ID,
    ROUND(AVG(s.Delay_Minutes), 2) AS Avg_Traffic_Delay_Minutes
FROM shipment_tracking s
JOIN orders o ON s.Order_ID = o.Order_ID
JOIN routes r ON o.Route_ID = r.Route_ID
WHERE s.Delay_Reason = 'Traffic'
GROUP BY r.Route_ID
ORDER BY Avg_Traffic_Delay_Minutes DESC;
