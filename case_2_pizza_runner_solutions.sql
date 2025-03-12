SET
    search_path = pizza_runner;

-- A. Pizza metrics
-- How many pizzas were ordered?
SELECT
    COUNT(*) as nr_pizzas
FROM
    order_content;

-- How many unique customer orders were made?
SELECT
    COUNT(*) as nr_orders
FROM
    orders;

-- How many successful orders were delivered by each runner?
SELECT
    COUNT(*) as nr_order_delivered
FROM
    order_delivery
WHERE
    cancellation_reason_id IS NULL;

-- How many of each type of pizza was delivered?
SELECT
    p.name as pizza,
    COUNT(*) as nr_pizzas
FROM
    order_content as oc
    JOIN pizza as p ON oc.pizza_id = p.id
    JOIN order_delivery as od ON od.order_id = oc.order_id
WHERE
    od.cancellation_reason_id IS NULL
GROUP BY
    p.name;

-- How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
    o.customer_id,
    COUNT(
        CASE
            WHEN oc.pizza_id = 1 THEN 1
        END
    ) as nr_meat,
    COUNT(
        CASE
            WHEN oc.pizza_id = 2 THEN 1
        END
    ) as nr_veg
FROM
    orders as o
    JOIN order_content as oc ON o.id = oc.order_id
    JOIN pizza as p ON p.id = oc.pizza_id
GROUP BY
    o.customer_id;

-- What was the maximum number of pizzas delivered in a single order?
SELECT
    oc.order_id,
    COUNT(oc.pizza_id) as nr_pizzas
FROM
    order_content as oc
    JOIN order_delivery as od ON oc.order_id = od.order_id
WHERE
    od.cancellation_reason_id IS NULL
GROUP BY
    oc.order_id
ORDER BY
    nr_pizzas DESC
LIMIT
    1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
    customer_id,
    SUM(
        CASE
            WHEN nr_changes > 0 THEN 1
            ELSE 0
        END
    ) as order_with_changes,
    -- Make sure to use SUM, not COUNT because count also counts 0
    SUM(
        CASE
            WHEN nr_changes = 0 THEN 1
            ELSE 0
        END
    ) as order_without_changes
FROM
    (
        SELECT
            oc.id as pizza,
            COUNT(sw.wish_id) as nr_changes,
            -- Count cell when there is a wish (i.e. either an exclusion or stg extra)
            o.customer_id
        FROM
            order_content as oc
            LEFT JOIN special_wishes as sw ON sw.order_content_id = oc.id
            JOIN orders as o ON o.id = oc.order_id
            JOIN order_delivery as od ON od.order_id = o.id
        WHERE
            od.cancellation_reason_id IS NULL -- Exclude cancelled deliveries
        GROUP BY
            o.customer_id,
            oc.id
        ORDER BY
            oc.id
    ) as subquery
GROUP BY
    customer_id;

-- Alteranative solution with EXIST instead of COUNT: faster, because it stops as soon as the condition is met for the first time
SELECT
    o.customer_id,
    -- Get TRUE if there is a wish associated with a pizza (i.e. the pizza shows up in the special wish table in form of the order_content_id)
    SUM(
        CASE
            WHEN EXISTS (
                -- Return True if the subquery has a result
                SELECT
                    1 -- Result: Return 1 when condition is met
                FROM
                    special_wishes sw
                WHERE
                    sw.order_content_id = oc.id -- Condition: order_content_id aka pizza shows up in special wish table
            ) THEN 1
            ELSE 0
        END
    ) AS orders_with_changes,
    SUM(
        CASE
            WHEN NOT EXISTS (
                -- Inverse to previous 
                SELECT
                    1
                FROM
                    special_wishes sw
                WHERE
                    sw.order_content_id = oc.id
            ) THEN 1
            ELSE 0
        END
    ) AS orders_without_changes
FROM
    orders AS o
    JOIN order_content AS oc ON o.id = oc.order_id
    LEFT JOIN order_delivery AS od ON od.order_id = o.id
WHERE
    od.cancellation_reason_id IS NULL
GROUP BY
    o.customer_id;

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
        CASE
            WHEN sum(
                CASE
                    WHEN excluded_topping_id IS NOT NULL THEN 1
                    ELSE 0
                END
            ) > 0
            AND sum(
                CASE
                    WHEN extra_topping_id IS NOT NULL THEN 1
                    ELSE 0
                END
            ) > 0 THEN 1
            ELSE 0
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
select
    extract(
        isodow
        from
            order_time
    ) as weekday,
    count(id)
from
    orders
group by
    weekday
order by
    weekday;