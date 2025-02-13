CREATE TABLE "orders"(
    "id" BIGINT NOT NULL,
    "customer_id" BIGINT NOT NULL,
    "time" DATE NOT NULL
);
ALTER TABLE
    "orders" ADD PRIMARY KEY("id");
CREATE TABLE "customers"("id" BIGINT NOT NULL);
ALTER TABLE
    "customers" ADD PRIMARY KEY("id");
CREATE TABLE "order_content"(
    "id" BIGINT NOT NULL,
    "order_id" BIGINT NOT NULL,
    "pizza_id" BIGINT NOT NULL
);
ALTER TABLE
    "order_content" ADD PRIMARY KEY("id");
CREATE TABLE "special_wishes"(
    "wish_id" BIGINT NOT NULL,
    "order_content_id" BIGINT NOT NULL,
    "excluded_topping_id" BIGINT NOT NULL,
    "extra_topping_id" BIGINT NOT NULL
);
ALTER TABLE
    "special_wishes" ADD PRIMARY KEY("wish_id");
CREATE TABLE "toppings"(
    "id" BIGINT NOT NULL,
    "name" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "toppings" ADD PRIMARY KEY("id");
CREATE TABLE "pizza"(
    "id" BIGINT NOT NULL,
    "name" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "pizza" ADD PRIMARY KEY("id");
CREATE TABLE "recipe"(
    "id" BIGINT NOT NULL,
    "pizza_id" BIGINT NOT NULL,
    "topping_id" BIGINT NOT NULL
);
ALTER TABLE
    "recipe" ADD PRIMARY KEY("id");
CREATE TABLE "runners"(
    "id" BIGINT NOT NULL,
    "registration_date" DATE NOT NULL
);
ALTER TABLE
    "runners" ADD PRIMARY KEY("id");
CREATE TABLE "order_delivery"(
    "id" BIGINT NOT NULL,
    "order_id" BIGINT NOT NULL,
    "runner_id" BIGINT NOT NULL,
    "pickup_time" DATE NOT NULL,
    "distance" FLOAT(53) NOT NULL,
    "duration_min" BIGINT NOT NULL,
    "cancellation" DATE NOT NULL
);
ALTER TABLE
    "order_delivery" ADD PRIMARY KEY("id");
ALTER TABLE
    "order_delivery" ADD CONSTRAINT "order_delivery_order_id_foreign" FOREIGN KEY("order_id") REFERENCES "orders"("id");
ALTER TABLE
    "recipe" ADD CONSTRAINT "recipe_topping_id_foreign" FOREIGN KEY("topping_id") REFERENCES "toppings"("id");
ALTER TABLE
    "special_wishes" ADD CONSTRAINT "special_wishes_order_content_id_foreign" FOREIGN KEY("order_content_id") REFERENCES "order_content"("id");
ALTER TABLE
    "special_wishes" ADD CONSTRAINT "special_wishes_excluded_topping_id_foreign" FOREIGN KEY("excluded_topping_id") REFERENCES "toppings"("id");
ALTER TABLE
    "recipe" ADD CONSTRAINT "recipe_pizza_id_foreign" FOREIGN KEY("pizza_id") REFERENCES "pizza"("id");
ALTER TABLE
    "special_wishes" ADD CONSTRAINT "special_wishes_extra_topping_id_foreign" FOREIGN KEY("extra_topping_id") REFERENCES "toppings"("id");
ALTER TABLE
    "order_content" ADD CONSTRAINT "order_content_order_id_foreign" FOREIGN KEY("order_id") REFERENCES "orders"("id");
ALTER TABLE
    "order_delivery" ADD CONSTRAINT "order_delivery_runner_id_foreign" FOREIGN KEY("runner_id") REFERENCES "runners"("id");
ALTER TABLE
    "orders" ADD CONSTRAINT "orders_customer_id_foreign" FOREIGN KEY("customer_id") REFERENCES "customers"("id");
ALTER TABLE
    "order_content" ADD CONSTRAINT "order_content_pizza_id_foreign" FOREIGN KEY("pizza_id") REFERENCES "pizza"("id");