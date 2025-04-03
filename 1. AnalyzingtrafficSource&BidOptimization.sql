USE mavenfuzzyfactory;

SELECT created_at FROM website_sessions where created_at > '2015-01-01';

SELECT * FROM website_pageviews WHERE website_session_id = 1059;

SELECT * FROM orders WHERE website_session_id = 1059;


SELECT 
	website_sessions.utm_content, -- 1
    count(DISTINCT website_sessions.website_session_id) AS sessions, -- 2
    COUNT(DISTINCT orders.order_id) AS total_orders,
    COUNT(DISTINCT orders.order_id)/count(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rt
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id =  website_sessions.website_session_id
	
WHERE website_sessions.website_session_id BETWEEN 1000 AND 2000 -- arbitrary
GROUP BY 1
ORDER BY 2 DESC; -- we have 2 columns in SELECT statement, then we can use 1/2 

-- ASSIGNMENT: Finding Top Traffic Sources
SELECT DISTINCT utm_source FROM website_sessions
LIMIT  1000;

SELECT 
	utm_source, 
    utm_campaign,
    http_referer, 
    count(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at between '2014-12-01' and '2015-12-01' 
GROUP BY 1,2,3
ORDER BY 4 DESC;

-- ASSIGNMENT: Traffic source conversion rate 

SELECT 
	utm_source, 
    utm_campaign,
    http_referer, 
    count(DISTINCT website_sessions.website_session_id) AS sessions,
    count(DISTINCT orders.order_id) AS total_orders, 
    count(DISTINCT orders.order_id)/count(DISTINCT website_sessions.website_session_id) AS CVR
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id =  website_sessions.website_session_id
WHERE website_sessions.created_at between '2014-12-01' and '2015-12-01' 
GROUP BY 1,2,3
-- HAVING CVR > 0.04
ORDER BY  6 DESC;


-- ASSIGNMENT: Traffic Source Trending

SELECT * FROM website_sessions WHERE website_session_id = 1059;

SELECT 
	--  AS Week,
    MIN(DATE(created_at)) AS week_start_date,
	COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < '2012-05-10'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);


--  ASSIGNMENT: Bid Optimization for Paid Traffic 
SELECT * FROM website_sessions WHERE website_session_id = 1059;
SELECT * FROM orders ;

SELECT 
	website_sessions.device_type,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS CVR
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-05-11'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1;

-- ASSIGNMENT: Trending w/Granular segments

SELECT 
	MIN(DATE(website_sessions.created_at)),
    COUNT(CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS dtop_sessions,
    COUNT(CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mob_sessions
FROM website_sessions
WHERE website_sessions.created_at BETWEEN '2012-04-15' AND '2012-06-09'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY WEEK(website_sessions.created_at);








