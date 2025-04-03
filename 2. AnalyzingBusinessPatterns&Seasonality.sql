
USE mavenfuzzyfactory;

-- ASSIGNMENT 1: Find seasonal trends for 2013 based on  2012's monthly and weekly volume patterns with session volume and orders volume
SELECT 
	YEAR(website_sessions.created_at) AS Year,
	MONTH(website_sessions.created_at) AS Month,
    -- WEEK(website_sessions.created_at) AS Week,
    COUNT(website_sessions.website_session_id) AS sessions,
    COUNT(Orders.order_id) AS orders
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id = website_sessions.website_session_id
WHERE YEAR(website_sessions.created_at) = '2012'
GROUP BY 1,2;

-- ASSIGNMENT 2: Adding live chat based on average website session volume by hour of day and by day week from 2012-09-15, 2012-11-15
    
SELECT 
	Hour,
	ROUND(AVG(CASE WHEN wkday = 0 THEN sessions ELSE NULL END),1) AS mon,
    ROUND(AVG(CASE WHEN wkday = 1 THEN sessions ELSE NULL END),1) AS tue,
    ROUND(AVG(CASE WHEN wkday = 2 THEN sessions ELSE NULL END),1) AS wed,
    ROUND(AVG(CASE WHEN wkday = 3 THEN sessions ELSE NULL END),1) AS thu,
    ROUND(AVG(CASE WHEN wkday = 4 THEN sessions ELSE NULL END),1) AS fri,
    ROUND(AVG(CASE WHEN wkday = 5 THEN sessions ELSE NULL END),1) AS sat,
    ROUND(AVG(CASE WHEN wkday = 6 THEN sessions ELSE NULL END),1) AS sun
FROM (
	SELECT
		DATE(Created_at) AS created_date,
		WEEKDAY(created_at) AS wkday,
		HOUR(created_at) As Hour, 
        COUNT(DISTINCT website_session_id) AS sessions
	FROM website_sessions
	WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
	GROUP BY 1,2,3
) AS daily_hourly_sessions
GROUP BY 1;


