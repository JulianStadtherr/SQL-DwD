CREATE TABLE customers (id BIGINT NOT NULL PRIMARY KEY);

-- Customers must be created first because orders reference them.
CREATE TABLE orders (
    id BIGINT NOT NULL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id),
    order_time TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);

CREATE TABLE pizza (
    id BIGINT NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE toppings (
    id BIGINT NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- The recipe table uses a composite primary key so that each (pizza,topping) pair is unique.
CREATE TABLE recipe (
    pizza_id BIGINT NOT NULL REFERENCES pizza(id),
    topping_id BIGINT NOT NULL REFERENCES toppings(id),
    PRIMARY KEY (pizza_id, topping_id)
);

-- Each row in order_content represents one pizza on an order.
CREATE TABLE order_content (
    id BIGINT NOT NULL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    pizza_id BIGINT NOT NULL REFERENCES pizza(id)
);

-- Special wishes allow NULL for exclusions or extras.
CREATE TABLE special_wishes (
    wish_id BIGINT NOT NULL PRIMARY KEY,
    order_content_id BIGINT NOT NULL REFERENCES order_content(id),
    excluded_topping_id BIGINT NULL REFERENCES toppings(id),
    extra_topping_id BIGINT NULL REFERENCES toppings(id)
);

CREATE TABLE runners (
    id BIGINT NOT NULL PRIMARY KEY,
    registration_date DATE NOT NULL
);

CREATE TABLE cancellation_reason (
    id BIGINT PRIMARY KEY,
    reason TEXT NOT NULL
);

CREATE TABLE order_delivery (
    id BIGINT NOT NULL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    runner_id BIGINT NOT NULL REFERENCES runners(id),
    pickup_time TIMESTAMP(0) WITHOUT TIME ZONE,
    distance_km FLOAT,
    duration_min BIGINT,
    cancellation_reason_id BIGINT NULL REFERENCES cancellation_reason(id)
);

--------------------------------------------------------------------------------
-- 2. Insert Data (migrated from the original schema)
--------------------------------------------------------------------------------
-- Customers come from the original customer_orders table.
INSERT INTO
    customers (id)
VALUES
    (101),
    (102),
    (103),
    (104),
    (105);

-- Orders: one row per distinct order from customer_orders.
INSERT INTO
    orders (id, customer_id, order_time)
VALUES
    (1, 101, '2020-01-01 18:05:02'),
    (2, 101, '2020-01-01 19:00:52'),
    (3, 102, '2020-01-02 23:51:23'),
    (4, 103, '2020-01-04 13:23:46'),
    (5, 104, '2020-01-08 21:00:29'),
    (6, 101, '2020-01-08 21:03:13'),
    (7, 105, '2020-01-08 21:20:29'),
    (8, 102, '2020-01-09 23:54:33'),
    (9, 103, '2020-01-10 11:22:59'),
    (10, 104, '2020-01-11 18:34:49');

-- Pizzas come from pizza_names.
INSERT INTO
    pizza (id, name)
VALUES
    (1, 'Meatlovers'),
    (2, 'Vegetarian');

-- Toppings come from pizza_toppings.
INSERT INTO
    toppings (id, name)
VALUES
    (1, 'Bacon'),
    (2, 'BBQ Sauce'),
    (3, 'Beef'),
    (4, 'Cheese'),
    (5, 'Chicken'),
    (6, 'Mushrooms'),
    (7, 'Onions'),
    (8, 'Pepperoni'),
    (9, 'Peppers'),
    (10, 'Salami'),
    (11, 'Tomatoes'),
    (12, 'Tomato Sauce');

-- Recipe: split the comma‐separated lists from pizza_recipes into individual rows.
INSERT INTO
    recipe (pizza_id, topping_id)
VALUES
    (1, 1),
    (1, 2),
    (1, 3),
    (1, 4),
    (1, 5),
    (1, 6),
    (1, 8),
    (1, 10),
    (2, 4),
    (2, 6),
    (2, 7),
    (2, 9),
    (2, 11),
    (2, 12);

-- Order_Content: one row per row in the original customer_orders.
-- (A surrogate id is assigned sequentially here for clarity.)
INSERT INTO
    order_content (id, order_id, pizza_id)
VALUES
    (1, 1, 1),
    -- from original row 1
    (2, 2, 1),
    -- row 2
    (3, 3, 1),
    -- row 3
    (4, 3, 2),
    -- row 4
    (5, 4, 1),
    -- row 5
    (6, 4, 1),
    -- row 6 (duplicate order row)
    (7, 4, 2),
    -- row 7
    (8, 5, 1),
    -- row 8
    (9, 6, 2),
    -- row 9
    (10, 7, 2),
    -- row 10
    (11, 8, 1),
    -- row 11
    (12, 9, 1),
    -- row 12
    (13, 10, 1),
    -- row 13
    (14, 10, 1);

-- row 14
-- Special_Wishes: derived from the "exclusions" and "extras" columns in customer_orders.
-- Note: The text 'null' and empty strings are interpreted as no wish.
-- For rows with multiple values (comma-separated), a separate row is inserted for each topping.
-- Below are the transformed inserts:
--
-- From customer_orders row 5 (order_content id = 5): exclusions = '4'
INSERT INTO
    special_wishes (
        wish_id,
        order_content_id,
        excluded_topping_id,
        extra_topping_id
    )
VALUES
    (1, 5, 4, NULL);

-- Row 6 (order_content id = 6): exclusions = '4'
INSERT INTO
    special_wishes (
        wish_id,
        order_content_id,
        excluded_topping_id,
        extra_topping_id
    )
VALUES
    (2, 6, 4, NULL);

-- Row 7 (order_content id = 7): exclusions = '4'
INSERT INTO
    special_wishes (
        wish_id,
        order_content_id,
        excluded_topping_id,
        extra_topping_id
    )
VALUES
    (3, 7, 4, NULL);

-- Row 8 (order_content id = 8): extras = '1' (the string 'null' for exclusions is treated as NULL)
INSERT INTO
    special_wishes (
        wish_id,
        order_content_id,
        excluded_topping_id,
        extra_topping_id
    )
VALUES
    (4, 8, NULL, 1);

-- Row 10 (order_content id = 10): extras = '1'
INSERT INTO
    special_wishes (
        wish_id,
        order_content_id,
        excluded_topping_id,
        extra_topping_id
    )
VALUES
    (5, 10, NULL, 1);

-- Row 12 (order_content id = 12): exclusions = '4'; extras = '1, 5'
INSERT INTO
    special_wishes (
        wish_id,
        order_content_id,
        excluded_topping_id,
        extra_topping_id
    )
VALUES
    (6, 12, 4, NULL);

INSERT INTO
    special_wishes (
        wish_id,
        order_content_id,
        excluded_topping_id,
        extra_topping_id
    )
VALUES
    (7, 12, NULL, 1);

INSERT INTO
    special_wishes (
        wish_id,
        order_content_id,
        excluded_topping_id,
        extra_topping_id
    )
VALUES
    (8, 12, NULL, 5);

-- Row 14 (order_content id = 14): exclusions = '2, 6'; extras = '1, 4'
INSERT INTO
    special_wishes (
        wish_id,
        order_content_id,
        excluded_topping_id,
        extra_topping_id
    )
VALUES
    (9, 14, 2, NULL);

INSERT INTO
    special_wishes (
        wish_id,
        order_content_id,
        excluded_topping_id,
        extra_topping_id
    )
VALUES
    (10, 14, 6, NULL);

INSERT INTO
    special_wishes (
        wish_id,
        order_content_id,
        excluded_topping_id,
        extra_topping_id
    )
VALUES
    (11, 14, NULL, 1);

INSERT INTO
    special_wishes (
        wish_id,
        order_content_id,
        excluded_topping_id,
        extra_topping_id
    )
VALUES
    (12, 14, NULL, 4);

-- Runners: from the original runners table.
INSERT INTO
    runners (id, registration_date)
VALUES
    (1, '2021-01-01'),
    (2, '2021-01-03'),
    (3, '2021-01-08'),
    (4, '2021-01-15');

-- Cancellation reasons: two reasons from 'cancellation' in 'runner_orders'
INSERT INTO
    cancellation_reason(id, reason)
VALUES
    (1, 'Restaurant'),
    (2, 'Customer');

-- Order_Delivery: migrated from runner_orders.
-- Note: For textual fields like "distance" and "duration", the non-numeric parts have been stripped.
-- For rows where the original values were 'null' or empty (indicating a cancellation), NULLs are inserted.
INSERT INTO
    order_delivery (
        id,
        order_id,
        runner_id,
        pickup_time,
        distance_km,
        duration_min,
        cancellation_reason_id
    )
VALUES
    (1, 1, 1, '2020-01-01 18:15:34', 20, 32, NULL),
    (2, 2, 1, '2020-01-01 19:10:54', 20, 27, NULL),
    (3, 3, 1, '2020-01-03 00:12:37', 13.4, 20, NULL),
    (4, 4, 2, '2020-01-04 13:53:03', 23.4, 40, NULL),
    (5, 5, 3, '2020-01-08 21:10:57', 10, 15, NULL),
    (6, 6, 3, NULL, NULL, NULL, 1),
    (7, 7, 2, '2020-01-08 21:30:45', 25, 25, NULL),
    (8, 8, 2, '2020-01-10 00:15:02', 23.4, 15, NULL),
    (9, 9, 2, NULL, NULL, NULL, 2),
    (
        10,
        10,
        1,
        '2020-01-11 18:50:20',
        10,
        10,
        NULL
    );
