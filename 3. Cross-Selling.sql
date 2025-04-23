-- CROSS SELLING 

-- AISSGNMENT 1: '2013-08-25' vs '2013-10-25', CTR from the /cart page, AVG Products per oder, AOV, Overall revenue per /cart page view

USE mavenfuzzyfactory;

SELECT * FROM website_pageviews;

CREATE TEMPORARY TABLE pageview_sessions
SELECT 
	website_pageview_id, 
    website_session_id,
    pageview_url, 
    CASE 
		WHEN created_at < '2013-09-25' THEN 'A. Pre_Cross_Sell'
        WHEN created_at >= '2013-09-25' THEN 'B. Post_Cross_Sell'
		ELSE 'uh oh ... check logic'
	END AS time_period
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25' AND pageview_url = '/cart';

SELECT * FROM pageview_sessions;

CREATE TEMPORARY TABLE session_w_next_pageview_id
SELECT 
	pageview_sessions.time_period, 
    pageview_sessions.website_session_id, 
    MIN(website_pageviews.website_pageview_id) AS next_pageview_id
FROM pageview_sessions
	LEFT JOIN website_pageviews
		ON pageview_sessions.website_session_id = website_pageviews.website_session_id
        AND website_pageviews.website_pageview_id > pageview_sessions.website_pageview_id
GROUP BY 1,2;
-- HAVING next_pageview_id IS NOT NULL
SELECT * FROM session_w_next_pageview_id;

SELECT * FROM orders;
CREATE TEMPORARY TABLE pre_post_sessions_orders
SELECT 
	time_period,
    pageview_sessions.website_session_id,
    order_id,
    items_purchased,
    price_usd
FROM pageview_sessions
	INNER JOIN orders -- cut out all the sessions that doesn't have order
		ON pageview_sessions.website_session_id = orders.website_session_id;
	
SELECT * FROM pre_post_sessions_orders;
DROP TABLE pre_post_sessions_orders;



SELECT 
	pageview_sessions.time_period,
    pageview_sessions.website_session_id,
    CASE WHEN session_w_next_pageview_id.next_pageview_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
    CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    pre_post_sessions_orders.items_purchased, 
    pre_post_sessions_orders.price_usd
FROM pageview_sessions
	LEFT JOIN session_w_next_pageview_id
		ON pageview_sessions.website_session_id = session_w_next_pageview_id.website_session_id
	LEFT JOIN pre_post_sessions_orders 
		ON pageview_sessions.website_session_id = pre_post_sessions_orders.website_session_id
ORDER BY pageview_sessions.website_session_id;


SELECT 
	time_period,
    COUNT(DISTINCT website_session_id) AS sessions,
    SUM(clicked_to_another_page) AS clickthroughs,
    SUM(placed_order) AS order_placed,
    SUM(items_purchased) AS products_purchased,
    SUM(price_usd) AS revenue,
    
    -- Answer the question ctr(click through rate), aov, revenue per cart 
    
    SUM(clicked_to_another_page)/ COUNT(DISTINCT website_session_id) AS cart_ctr, 
    SUM(items_purchased)/SUM(placed_order) AS products_per_order,
    SUM(price_usd) / SUM(placed_order) AS AOV, 
    SUM(price_usd) / COUNT(DISTINCT website_session_id) AS rev_per_cart_session
        
FROM (

SELECT 
	pageview_sessions.time_period,
    pageview_sessions.website_session_id,
    CASE WHEN session_w_next_pageview_id.next_pageview_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
    CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    pre_post_sessions_orders.items_purchased, 
    pre_post_sessions_orders.price_usd
FROM pageview_sessions
	LEFT JOIN session_w_next_pageview_id
		ON pageview_sessions.website_session_id = session_w_next_pageview_id.website_session_id
	LEFT JOIN pre_post_sessions_orders 
		ON pageview_sessions.website_session_id = pre_post_sessions_orders.website_session_id
ORDER BY pageview_sessions.website_session_id

) AS soemthing
GROUP BY 1;




-- ASSIGNMENT 2: 
SELECT * FROM website_pageviews;
SELECT * FROM orders;

SELECT 
	CASE 
		WHEN website_sessions.created_at < '2013-12-12' THEN 'A. Pre_Birthday_Bear'
        WHEN website_sessions.created_at >= '2013-12-12' THEN 'B. Post_Birthday_Bear'
		ELSE 'uh oh ... check logic'
	END AS time_period, 
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions, 
    COUNT(DISTINCT order_id) AS orders,
    --
    COUNT(DISTINCT order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate, 
    SUM(price_usd) / COUNT(DISTINCT order_id) AS AOV, 
    SUM(items_purchased)/ COUNT(DISTINCT order_id) AS products_per_order, 
	SUM(price_usd) /  COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
    
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'

GROUP BY 1;


