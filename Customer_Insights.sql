Use mavenfuzzyfactory;

-- Create Customer Segment Table 
CREATE TABLE customer_segments
SELECT 
	user_id,
	CASE 
        WHEN DATEDIFF(MAX(created_at), MIN(created_at)) <= 30 AND COUNT(DISTINCT order_id) >= 3 AND SUM(price_usd) >= 150 THEN 'High-Value Active'
        WHEN DATEDIFF(MAX(created_at), MIN(created_at)) <= 90 AND COUNT(DISTINCT order_id) >= 2 THEN 'Active Repeat'
        WHEN DATEDIFF(MAX(created_at), MIN(created_at)) <= 90 AND COUNT(DISTINCT order_id) = 1 THEN 'New Customer'
        WHEN DATEDIFF(MAX(created_at), MIN(created_at)) BETWEEN 91 AND 180 THEN 'At Risk'
        WHEN DATEDIFF(MAX(created_at), MIN(created_at)) > 180 THEN 'Churned'
        ELSE 'Other'
    END AS customer_segment
FROM orders
GROUP BY user_id;

SELECT 
	user_id,
	customer_segment
FROM customer_segments;

SELECT 
	customer_segment, 
    COUNT(user_id)
FROM customer_segments
GROUP BY 1;

-- 1.RFM segmentation Analysis
-- RFM segmentation for detailed customer analysis
SELECT 
    o.user_id,
	DATEDIFF(MAX(created_at), MIN(created_at)) AS recency_days,
    COUNT(DISTINCT order_id) AS frequency,
    SUM(price_usd) AS monetary_value,
	customer_segment
FROM orders o
Join customer_segments cs
	ON o.user_id = cs.user_id
GROUP BY user_id,5;


-- 2. Product Preference Analysis
-- Product preferences by customer segment
SELECT 
	customer_segment,
    oi.product_id,
    COUNT(DISTINCT oi.order_id) AS orders,
    SUM(oi.price_usd) AS revenue
    
FROM customer_segments cs
JOIN orders o 
	ON cs.user_id = o.user_id
JOIN order_items oi 
	ON o.order_id = oi.order_id
GROUP BY 1, 2
ORDER BY 1, 4 DESC;


-- 3. Purchasing Pattern Analysis
-- Time between purchases by customer segment

/*WITH filtered_segments AS (
    SELECT 
        user_id,
        customer_segment
    FROM customer_segments
    -- Only include segments we care about to improve performance
    HAVING customer_segment IN ('High-Value Active', 'Active Repeat')
),*/
-- this code running slower

WITH customer_segments AS (
    SELECT 
        user_id,
        CASE 
            WHEN DATEDIFF(MAX(created_at), MIN(created_at)) <= 30 AND COUNT(DISTINCT order_id) >= 3 AND SUM(price_usd) >= 150 THEN 'High-Value Active'
            WHEN DATEDIFF(MAX(created_at), MIN(created_at)) <= 90 AND COUNT(DISTINCT order_id) >= 2 THEN 'Active Repeat'
            WHEN DATEDIFF(MAX(created_at), MIN(created_at)) <= 90 AND COUNT(DISTINCT order_id) = 1 THEN 'New Customer'
            WHEN DATEDIFF(MAX(created_at), MIN(created_at)) BETWEEN 91 AND 180 THEN 'At Risk'
            WHEN DATEDIFF(MAX(created_at), MIN(created_at)) > 180 THEN 'Churned'
            ELSE 'Other' 
        END AS customer_segment
    FROM orders
    GROUP BY user_id
    -- Only include segments we care about to improve performance
    HAVING customer_segment IN ('High-Value Active', 'Active Repeat')
),

order_pairs AS (
    SELECT 
        cs.customer_segment,
        o1.user_id,
        o1.order_id AS first_order_id,
        o2.order_id AS next_order_id,
        DATEDIFF(o2.created_at, o1.created_at) AS days_between_orders
    FROM customer_segments cs
    JOIN orders o1 ON cs.user_id = o1.user_id
    JOIN orders o2 ON o1.user_id = o2.user_id
    WHERE o1.created_at < o2.created_at
    -- Find consecutive orders for each user
    AND NOT EXISTS (
        SELECT 1
        FROM orders o_between
        WHERE o_between.user_id = o1.user_id
        AND o_between.created_at > o1.created_at
        AND o_between.created_at < o2.created_at
    )
)

SELECT 
    customer_segment,
    AVG(days_between_orders) AS avg_days_between_orders,
    MIN(days_between_orders) AS min_days_between_orders,
    MAX(days_between_orders) AS max_days_between_orders
FROM order_pairs
GROUP BY customer_segment;


-- 4.Acquisition Channel Impact on Segments
-- Acquisition channels by customer segment
SELECT 
    CASE 
        WHEN ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' THEN 'gsearch_nonbrand'
        WHEN ws.utm_source = 'bsearch' AND ws.utm_campaign = 'nonbrand' THEN 'bsearch_nonbrand'
        WHEN ws.utm_campaign = 'brand' THEN 'brand_search'
        WHEN ws.utm_source IS NULL AND ws.http_referer IS NOT NULL THEN 'organic_search'
        WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL THEN 'direct_type_in'
        ELSE 'other'
    END AS channel,
    cs.customer_segment,
    COUNT(DISTINCT cs.user_id) AS customers,
    SUM(o.price_usd)/COUNT(DISTINCT cs.user_id) AS avg_customer_value
FROM customer_segments cs
JOIN orders o ON cs.user_id = o.user_id
JOIN website_sessions ws ON o.website_session_id = ws.website_session_id
GROUP BY 1, 2
ORDER BY 1, 4 DESC;


-- 5. Segment-Specific Growth Opportunities

-- Product gaps for high-value customers
SELECT 
    high_value.user_id,
    GROUP_CONCAT(DISTINCT oi.product_id ORDER BY oi.product_id) AS purchased_products
FROM (
    -- High-value customer identification
    SELECT user_id
    FROM orders
    GROUP BY user_id
    HAVING 
        DATEDIFF(MAX(created_at), MIN(created_at)) <= 30 
        AND COUNT(DISTINCT order_id) >= 3 
        AND SUM(price_usd) >= 150
) AS high_value
JOIN orders o ON high_value.user_id = o.user_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY 1;
