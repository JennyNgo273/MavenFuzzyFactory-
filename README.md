# Maven Fuzzy Factory CLV Analysis Strategy 2014 - 2015

## Project Overview
The goal of this project is to investigate the Customer Lifetime Value (CLV) metrics at Maven Fuzzy Factory to surface recommendations on customer segmentation and marketing strategy for improved long-term customer profitability.

Founded in 2012, Maven Fuzzy Factory is an e-commerce company that sells popular toys especially types of bears via its website and mobile app. In 2014-2015, Maven Fuzzy Factory expanded their product lineup with the introduction of their fourth product—The Hudson River Mini Bear—specifically designed for the birthday gift market, while simultaneously implementing a new cross-selling feature that offers customers the option to add a second complementary product during the checkout process on the /cart page.

Now that they've established a comprehensive customer database and are developing their customer-centric approach, the company would like to build more understanding of customer lifetime value distribution and how different segments contribute to overall business profitability.

The CLV analysis is designed to drive two primary objectives:
1) To identify high-value customer segments and their characteristics
2) To optimize marketing investment for acquiring and retaining profitable customers

## Dataset Structure
The dataset consists of six interconnected tables within a star schema, including information about customers, orders, order items, products, website sessions, and acquisition channels.

![Data Structure](https://github.com/JennyNgo273/MavenFuzzyFactory-/blob/main/dataset.png)

## Insights Summary
### In order to evaluate CLV distribution, we focused on the following key metrics:
- **Customer Segmentation**: The distribution of customers across different value segments based on recency, frequency, and monetary value.
- **Acquisition Channels**: How customer acquisition sources impact long-term value.
- **Purchase Patterns**: Recurring purchasing behaviors that correlate with higher lifetime value.

### Customer Segmentation
We created customer segments based on RFM (Recency, Frequency, Monetary value) analysis to identify different customer value tiers:

```sql
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

-- RFM segmentation for detailed customer analysis
SELECT 
    customer_segment,
    COUNT(user_id)
FROM customer_segments
GROUP BY 1;
```

Analysis results show five distinct customer segments with the following distribution: 
- New Customer (31,105 customers, 97.4%)
- Active Repeat (574 customers, 1.8%)
- At Risk (14 customers, 0.04%)
- High-Value Active (3 customers, 0.01%)

We also analyzed product preferences by segment:

```sql
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
```

Results show New Customers make up the largest segment at 97.4%, with the majority purchasing product 1 (The Original Mr. Fuzzy) with 23,341 orders generating $1,1668,816.59  in revenue.

### Acquisition Channels
We analyzed how different acquisition channels contribute to customer value across segments:

```sql
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
```

Key findings include:
- The "gsearch_nonbrand" channel delivers the highest volume of customers, with 18,525 New Customers at an average value of $59.73.
- "Brand_search" channels show strong performance across segments, with particularly high average customer value for Active Repeat customers at $70.14.
- Direct type-in customers in the High-Value Active segment show the highest average customer value at $143.97, significantly outperforming other channels.

### Purchase Patterns
We analyzed the time between purchases to understand repeat buying behavior:

```sql
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
```

Results show:
- High-Value Active customers purchase on average every 12.17 days, compared to Active Repeat customers who purchase every 33.79 days.
- The minimum time between purchases for High-Value Active customers is 7 days, while Active Repeat customers can purchase as frequently as 1 day apart.

We also calculated the basic CLV formula components:

```sql
SELECT 
    AVG(price_usd) AS avg_order_value,
    COUNT(order_id) / COUNT(DISTINCT user_id) AS avg_purchase_frequency,
    AVG(days_as_customer) / 365 AS avg_customer_lifespan_years,
    AVG(price_usd) * (COUNT(order_id) / COUNT(DISTINCT user_id)) * (AVG(days_as_customer) / 365) AS estimated_clv
FROM (
    SELECT 
        user_id,
        order_id,
        price_usd,
        DATEDIFF('2015-03-19', MIN(created_at) OVER (PARTITION BY user_id)) AS days_as_customer
    FROM orders
) AS customer_metrics;
```

Overall customer metrics show an average order value of $59.99, purchase frequency of 1.02 orders per customer, and an average customer lifespan of 0.93 years, resulting in an estimated CLV of $56.99.

### Segment-Specific Growth Opportunities
We identified product gaps and purchase patterns for high-value customers:

```sql
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
```

The analysis reveals product purchasing patterns among high-value customers, showing specific combinations (like "1,3" and "1,2,4") that could inform cross-selling and bundle strategies.

## Recommendations
- **Customer Segment Targeting**: Implement differentiated retention strategies for each segment, with particular focus on converting New Customers to Active Repeat by encouraging repeat purchases within 30 days.
- **Acquisition Channel Optimization**: Increase investment in direct type-in and brand search campaigns due to their superior CLV metrics, while optimizing non-brand campaigns to target demographics that match High-Value Active profiles.
- **Product Strategy**: Leverage product preference insights to design segment-specific bundles, particularly promoting products 1 and 2 to New Customers based on their strong performance in this segment.
- **Retention Program Development**: Create targeted interventions for At Risk customers, focusing especially on those who previously purchased products 1 and 2 where the segment shows higher historical revenue.
