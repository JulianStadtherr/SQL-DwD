SET search_path = pizza_runner;

-- A. Pizza metrics

-- How many pizzas were ordered?
SELECT COUNT(*) as nr_pizzas
FROM order_content;

-- How many unique customer orders were made?
SELECT COUNT(*) as nr_orders
FROM orders;

-- How many successful orders were delivered by each runner?
SELECT COUNT(*) as nr_order_delivered
FROM order_delivery
WHERE cancellation_reason_id IS NULL;

-- How many of each type of pizza was delivered?
SELECT p.name as pizza, COUNT(*) as nr_pizzas
FROM order_content as oc
JOIN pizza as p
ON oc.pizza_id = p.id
JOIN order_delivery as od
ON od.order_id = oc.order_id
WHERE od.cancellation_reason_id IS NULL
GROUP BY p.name;

-- How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
	o.customer_id, 
	COUNT(CASE WHEN oc.pizza_id = 1 THEN 1 END) as nr_meat,
	COUNT(CASE WHEN oc.pizza_id = 2 THEN 1 END) as nr_veg 
FROM orders as o
JOIN order_content as oc
	ON o.id = oc.order_id
JOIN pizza as p
	ON p.id = oc.pizza_id
GROUP BY  o.customer_id;

-- What was the maximum number of pizzas delivered in a single order?
SELECT 
	oc.order_id, 
	COUNT(oc.pizza_id) as nr_pizzas
FROM order_content as oc
JOIN order_delivery as od
	ON oc.order_id = od.order_id
WHERE od.cancellation_reason_id IS NULL
GROUP BY oc.order_id
ORDER BY nr_pizzas DESC
LIMIT 1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
	customer_id, 
	SUM(CASE WHEN nr_changes > 0 THEN 1 ELSE 0 END) as order_with_changes, -- Make sure to use SUM, not COUNT because count also counts 0
	SUM(CASE WHEN nr_changes = 0 THEN 1 ELSE 0 END) as order_without_changes
FROM (
	SELECT 
		oc.id as pizza, 
		COUNT(sw.wish_id) as nr_changes, -- Count cell when there is a wish (i.e. either an exclusion or stg extra)
		o.customer_id
	FROM order_content as oc
	LEFT JOIN special_wishes as sw
		ON sw.order_content_id = oc.id
	JOIN orders as o
		ON o.id = oc.order_id
	JOIN order_delivery as od
		ON od.order_id = o.id
	WHERE od.cancellation_reason_id IS NULL -- Exclude cancelled deliveries
	GROUP BY o.customer_id, oc.id
	ORDER BY oc.id
	) as subquery
GROUP BY customer_id;

-- Alteranative solution with EXIST instead of COUNT: faster, because it stops as soon as the condition is met for the first time
SELECT 
    o.customer_id,
    -- Get TRUE if there is a wish associated with a pizza (i.e. the pizza shows up in the special wish table in form of the order_content_id)
    SUM(CASE WHEN EXISTS ( -- Return True if the subquery has a result
        SELECT 1 -- Result: Return 1 when condition is met
        FROM special_wishes sw
        WHERE sw.order_content_id = oc.id -- Condition: order_content_id aka pizza shows up in special wish table
    ) THEN 1 ELSE 0 END) AS orders_with_changes,
    SUM(CASE WHEN NOT EXISTS ( -- Inverse to previous 
        SELECT 1
        FROM special_wishes sw
        WHERE sw.order_content_id = oc.id
    ) THEN 1 ELSE 0 END) AS orders_without_changes
FROM orders AS o
JOIN order_content AS oc ON o.id = oc.order_id
LEFT JOIN order_delivery AS od ON od.order_id = o.id 
WHERE od.cancellation_reason_id IS NULL 
GROUP BY o.customer_id;

-- How many pizzas were delivered that had both exclusions and extras?
WITH pizzas_with_changes AS (
	SELECT
		sw.order_content_id,
		sw.excluded_topping_id,
		sw.extra_topping_id
	FROM
		special_wishes AS sw
		JOIN order_content AS oc ON sw.order_content_id = oc.id
		JOIN order_delivery AS od ON od.order_id = oc.order_id
	WHERE
		od.cancellation_reason_id IS NULL
),
	pizzas_exex AS (
		SELECT
			order_content_id,
			CASE WHEN sum(
				CASE WHEN excluded_topping_id IS NOT NULL THEN
					1
				ELSE
					0
				END) > 0
				AND sum(
					CASE WHEN extra_topping_id IS NOT NULL THEN
						1
					ELSE
						0
					END) > 0 THEN
				1
			ELSE
				0
			END AS has_both_changes
		FROM
			pizzas_with_changes
		GROUP BY
			order_content_id
	)

SELECT
	sum(has_both_changes)
FROM
	pizzas_exex;
	
-- What was the total volume of pizzas ordered for each hour of the day?	
SELECT
	date_part('hour', order_time) AS hour,
	count(oc.pizza_id) AS nr_pizzas
FROM
	orders AS o
	JOIN order_content AS oc ON oc.order_id = o.id
GROUP BY
	hour
ORDER BY
	hour;

-- What was the volume of orders for each day of the week?
SELECT
	extract(isodow FROM order_time) AS weekday,
	count(id)
FROM
	orders
GROUP BY
	weekday
ORDER BY
	weekday;

-- B. Runner and Customer Experience

-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
	(registration_date - '2021-01-01') / 7 + 1 AS week,
	count(id) AS nr_runners_registered
FROM
	runners
GROUP BY
	week
ORDER BY
	week;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT
	runner_id,
	avg(od.pickup_time - o.order_time) AS avg_time_diff
FROM
	orders AS o
	JOIN order_delivery AS od ON o.id = od.order_id
GROUP BY
	runner_id;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

-- a. Show avg time per pizza
WITH nr_pizzas_p_order AS (
	SELECT
		order_id,
		count(pizza_id) AS nr_pizzas
	FROM
		order_content
	GROUP BY
		order_id
	ORDER BY
		order_id
)
SELECT
	ppo.order_id,
	ppo.nr_pizzas,
	ROUND(EXTRACT(epoch FROM od.pickup_time - o.order_time) / 60, 2) AS prep_time_min,
	ROUND(EXTRACT(epoch FROM od.pickup_time - o.order_time) / 60, 2) / ppo.nr_pizzas AS avg_time_p_pizza
FROM
	nr_pizzas_p_order AS ppo
	JOIN order_delivery AS od ON ppo.order_id = od.order_id
	JOIN orders AS o ON o.id = ppo.order_id
WHERE
	od.pickup_time IS NOT NULL
ORDER BY
	nr_pizzas;

-- b. Show correlation between time and nr of pizzas
WITH nr_pizzas_p_order AS (
	SELECT
		order_id,
		count(pizza_id) AS nr_pizzas
	FROM
		order_content
	GROUP BY
		order_id
	ORDER BY
		order_id
),
prep_time_by_order AS (
	SELECT
		ppo.order_id,
		ppo.nr_pizzas,
		ROUND(EXTRACT(epoch FROM od.pickup_time - o.order_time) / 60, 2) AS prep_time_min
	FROM
		nr_pizzas_p_order AS ppo
		JOIN order_delivery AS od ON ppo.order_id = od.order_id
		JOIN orders AS o ON o.id = ppo.order_id
	WHERE
		od.pickup_time IS NOT NULL
	ORDER BY
		nr_pizzas
)
SELECT
	corr(nr_pizzas, prep_time_min) AS correlation --Show correlation
FROM
	prep_time_by_order;

-- What was the average distance travelled for each customer?
SELECT
	o.customer_id,
	avg(od.distance_km) AS avg_distance_km
FROM
	orders AS o
	JOIN order_delivery AS od ON o.id = od.order_id
GROUP BY
	o.customer_id
ORDER BY
	o.customer_id;

-- What was the difference between the longest and shortest delivery times for all orders?
SELECT
	max(duration_min) - min(duration_min) AS diff_min
FROM
	order_delivery;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
	*,
	round(distance_km::numeric / duration_min::numeric * 60, 3) AS km_h
FROM
	order_delivery;

-- What is the successful delivery percentage for each runner?
SELECT
	runner_id,
	count(pickup_time) * 1.0 / count(order_id) * 100 AS pct_delivered -- multiply by 1.0 to cast as float. if int/int the rest is discarded ie the result is a forced int
FROM
	order_delivery
GROUP BY
	runner_id
ORDER BY
	runner_id;

