https: / / 8weeksqlchallenge.com /case
    - study -1 / -- 1. What is the total amount each customer spent at the restaurant?
    SELECT
        sales.customer_id,
        SUM(menu.price)
    FROM
        dannys_diner.menu
        JOIN dannys_diner.sales ON menu.product_id = sales.product_id
    GROUP BY
        sales.customer_id;

| customer_id | sum | | ----------- | --- |
| B | 74 | | C | 36 | | A | 76 | -- 2. How many days has each customer visited the restaurant?
'''
SELECT
	customer_id,
    COUNT(order_date) -- ! Add ' DISTINCT ' 
FROM dannys_diner.sales
GROUP BY customer_id;

| customer_id | count |
| ----------- | ----- |
| B           | 6     |
| C           | 3     |
| A           | 6     |
'''
SELECT
    customer_id,
    COUNT(DISTINCT(order_date)) AS times_visited
FROM
    dannys_diner.sales
GROUP BY
    customer_id
ORDER BY
    times_visited DESC;

customer_id times_visited B 6 A 4 C 2 -- 3. What was the first item from the menu purchased by each customer?
SELECT
    *
FROM
    (
        SELECT
            s.customer_id,
            m.product_name,
            s.order_date,
            ROW_NUMBER() --function to give rank to each row by partition (see view)
            OVER(
                PARTITION BY customer_id
                ORDER BY
                    s.order_date ASC
            ) --View
            AS order_rank -- window function used to find 1st order for each customer, see https://www.youtube.com/watch?v=rIcB4zMYMas
        FROM
            dannys_diner.sales as s
            JOIN dannys_diner.menu as m ON s.product_id = m.product_id
    ) AS ord_rnk
WHERE
    order_rank = 1;

customer_id product_name order_date order_rank A curry 2021 -01 -01 1 B curry 2021 -01 -01 1 C ramen 2021 -01 -01 1 -- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    m.product_name,
    COUNT(s.product_id) as orders_total
FROM
    dannys_diner.menu as m
    JOIN dannys_diner.sales as s ON m.product_id = s.product_id
GROUP BY
    m.product_name
ORDER BY
    orders_total DESC;

product_name orders_total ramen 8 curry 4 sushi 3 -- 5. Which item was the MOST POPULAR for each customer?
SELECT
    *
FROM
    (
        SELECT
            s.customer_id,
            m.product_name,
            COUNT(s.product_id) as orders_total,
            ROW_NUMBER() OVER(
                PARTITION BY s.customer_id
                ORDER BY
                    COUNT(s.product_id) DESC
            )
        FROM
            dannys_diner.sales as s
            JOIN dannys_diner.menu as m ON s.product_id = m.product_id
        GROUP BY
            s.customer_id,
            m.product_name --! all columns that are in select but not aggregate columns must be written in GROUP BY
    ) as ord
WHERE
    row_number = 1;

customer_id product_name orders_total row_number A ramen 3 1 B ramen 2 1 C ramen 3 1 -- 6. Which item was purchased FIRST
boo by the customer
after
    they became a member ?
SELECT
    *
FROM
    (
        SELECT
            s.customer_id,
            mb.join_date,
            s.order_date,
            m.product_name,
            ROW_NUMBER() OVER(
                PARTITION BY s.customer_id
                ORDER BY
                    s.order_date
            ) as order_rank
        FROM
            dannys_diner.members as mb
            JOIN dannys_diner.sales as s ON mb.customer_id = s.customer_id
            JOIN dannys_diner.menu as m ON s.product_id = m.product_id
        WHERE
            s.order_date >= mb.join_date
    ) as ord
WHERE
    order_rank = 1;

customer_id join_date order_date product_name order_rank A 2021 -01 -07 2021 -01 -07 curry 1 B 2021 -01 -09 2021 -01 -11 sushi 1 -- 7. Which item was purchased JUST BEFORE the customer became a member?
SELECT
    *
FROM
    (
        SELECT
            s.customer_id,
            mb.join_date,
            s.order_date,
            m.product_name,
            ROW_NUMBER() OVER(
                PARTITION BY s.customer_id
                ORDER BY
                    s.order_date DESC
            ) as order_rank
        FROM
            dannys_diner.members as mb
            JOIN dannys_diner.sales as s ON mb.customer_id = s.customer_id
            JOIN dannys_diner.menu as m ON s.product_id = m.product_id
        WHERE
            s.order_date < mb.join_date
    ) as ord
WHERE
    order_rank = 1;

customer_id join_date order_date product_name order_rank A 2021 -01 -07 2021 -01 -01 sushi 1 B 2021 -01 -09 2021 -01 -04 sushi 1 -- 8. What is the total items and amount spent for each member before they became a member?
SELECT
    s.customer_id,
    COUNT(m.product_id) as total_items,
    SUM(m.price) as rev
FROM
    dannys_diner.members as mb
    JOIN dannys_diner.sales as s ON mb.customer_id = s.customer_id
    JOIN dannys_diner.menu as m ON s.product_id = m.product_id
WHERE
    s.order_date < mb.join_date
GROUP BY
    s.customer_id;

customer_id total_items rev B 3 40 A 2 25 -- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
'''
SELECT 
    s.customer_id,
    SUM(
      CASE
          WHEN product_id = 1 THEN m.price*20
          WHEN product_id =! 1 THEN m.price*10 --! Use ELSE for all other cases
          END 
      AS points) --! Close sum() before AS
FROM dannys_diner.sales
JOIN dannys_diner.menu as m ON s.product_id = m.product_id
GROUP BY s.customer_id
;
'''
SELECT
    s.customer_id,
    SUM(
        CASE
            WHEN s.product_id = 1 THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS points
FROM
    dannys_diner.sales as s
    JOIN dannys_diner.menu as m ON s.product_id = m.product_id
GROUP BY
    s.customer_id
ORDER BY
    points DESC;

customer_id points B 940 A 860 C 360 -- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
'''
SELECT 
    s.customer_id,
    SUM(
      CASE
      WHEN s.order_date BETWEEN mb.join_date AND DATEADD(d, 7, mb.join_date) --! DATEADD does not exist with postgres, instead use INTERVAL
      THEN m.price*20
      ELSE m.price*10
      END) --! Missing case for sushi gaining double points outside of week after membership
    AS points
FROM dannys_diner.sales as s
JOIN dannys_diner.menu as m ON s.product_id = m.product_id
JOIN dannys_diner.members as mb ON s.customer_id = mb.customer_id
WHERE s.order_date < 2021-02-01 --! Date must be in ''
GROUP BY s.customer_id
ORDER BY points DESC
;
'''
SELECT
    s.customer_id,
    SUM(
        CASE
            WHEN s.order_date BETWEEN mb.join_date
            AND mb.join_date + INTERVAL '6 days' THEN m.price * 20
            WHEN s.product_id = 1 THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS points
FROM
    dannys_diner.sales as s
    JOIN dannys_diner.menu as m ON s.product_id = m.product_id
    JOIN dannys_diner.members as mb ON s.customer_id = mb.customer_id
WHERE
    s.order_date < '2021-02-01'
GROUP BY
    s.customer_id
ORDER BY
    points DESC;

customer_id points A 1370 B 820 -- 11 (bonus). Recreate the table
SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
        WHEN s.order_date < mb.join_date
        OR mb.join_date IS NULL THEN 'N'
        ELSE 'Y'
    END AS members
FROM
    dannys_diner.sales as s
    JOIN dannys_diner.menu as m ON s.product_id = m.product_id FULL
    JOIN dannys_diner.members as mb ON s.customer_id = mb.customer_id
ORDER BY
    customer_id --! Do not use GROUP BY here or it could sum up rows (ex. with identical date if grouped by date). Only use GROUP BY when an agg function is used
;

customer_id order_date product_name price members A 2021 -01 -07 curry 15 Y A 2021 -01 -11 ramen 12 Y A 2021 -01 -11 ramen 12 Y A 2021 -01 -10 ramen 12 Y A 2021 -01 -01 sushi 10 N A 2021 -01 -01 curry 15 N B 2021 -01 -04 sushi 10 N B 2021 -01 -11 sushi 10 Y B 2021 -01 -01 curry 15 N B 2021 -01 -02 curry 15 N B 2021 -01 -16 ramen 12 Y B 2021 -02 -01 ramen 12 Y C 2021 -01 -01 ramen 12 N C 2021 -01 -01 ramen 12 N C 2021 -01 -07 ramen 12 N -- 12 (bonus). Add a rank column
SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
        WHEN s.order_date < mb.join_date
        OR mb.join_date IS NULL THEN 'N'
        ELSE 'Y'
    END AS members,
    CASE
        WHEN s.order_date >= mb.join_date --! Cannot use 'members' column, it is not yet created. Include case so that everything excluded is NULL
        THEN ROW_NUMBER() OVER(
            PARTITION BY s.customer_id,
            s.order_date >= mb.join_date
            ORDER BY
                s.order_date
        ) --! Must include s.order_date >= mb.join_date to start at 1 where condition is met
    END AS rank
FROM
    dannys_diner.sales as s
    JOIN dannys_diner.menu as m ON s.product_id = m.product_id FULL
    JOIN dannys_diner.members as mb ON s.customer_id = mb.customer_id
ORDER BY
    customer_id;

customer_id order_date product_name price members rank A 2021 -01 -01 sushi 10 N null A 2021 -01 -01 curry 15 N null A 2021 -01 -07 curry 15 Y 1 A 2021 -01 -10 ramen 12 Y 2 A 2021 -01 -11 ramen 12 Y 3 A 2021 -01 -11 ramen 12 Y 4 B 2021 -01 -01 curry 15 N null B 2021 -01 -02 curry 15 N null B 2021 -01 -04 sushi 10 N null B 2021 -01 -11 sushi 10 Y 1 B 2021 -01 -16 ramen 12 Y 2 B 2021 -02 -01 ramen 12 Y 3 C 2021 -01 -01 ramen 12 N null C 2021 -01 -01 ramen 12 N null C 2021 -01 -07 ramen 12 N null