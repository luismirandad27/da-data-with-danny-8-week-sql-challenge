# SQL Challenge #2: Pizza Runner

<img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png"
     alt="Markdown Monster icon" style="height:400px;width:400px;border-radius:5px;"/>

## Question's Solutions - Part A - Pizza Metrics

### 1. How many pizzas were ordered?
```sql
SELECT COUNT(1) as total_pizzas_ordered
FROM pizza_runner.customer_orders;
```
&nbsp;
### 2. How many unique customer orders were made?
```sql
SELECT COUNT(DISTINCT order_id) as total_unique_customers_orders
FROM pizza_runner.customer_orders;
```
&nbsp;
### 3. How many successful orders were delivered by each runner?
```sql
WITH tmp AS
(
  SELECT
  	order_id,
  	runner_id,
  	CASE WHEN pickup_time = 'null' THEN NULL
  		 ELSE pickup_time
  	END as pickup_time
  FROM pizza_runner.runner_orders	
)
SELECT
	tmp.runner_id,
	COUNT(1) as total_successful_orders
FROM tmp
WHERE
	tmp.pickup_time IS NOT NULL
GROUP BY
	tmp.runner_id;
```
&nbsp;
### 4. How many of each type of pizza was delivered?
```sql
WITH tmp AS
(
  SELECT
  	a.order_id,
  	c.pizza_name,
  	CASE WHEN a.pickup_time = 'null' THEN NULL
  		 ELSE a.pickup_time
  	END as pickup_time
  FROM pizza_runner.runner_orders 	a
  JOIN pizza_runner.customer_orders b on a.order_id = b.order_id
  JOIN pizza_runner.pizza_names		c on b.pizza_id = c.pizza_id
)
SELECT
	tmp.pizza_name,
	COUNT(1) as total_orders_delivered
FROM tmp
WHERE
	tmp.pickup_time IS NOT NULL
GROUP BY
	tmp.pizza_name;
```
&nbsp;
### 5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
WITH tmp AS
(
  SELECT
  	a.order_id,
  	b.customer_id,
  	c.pizza_name
  FROM pizza_runner.runner_orders 	a
  JOIN pizza_runner.customer_orders b on a.order_id = b.order_id
  JOIN pizza_runner.pizza_names		c on b.pizza_id = c.pizza_id
)
SELECT
	tmp.customer_id,
	SUM(CASE WHEN tmp.pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) total_vegetarian,
    SUM(CASE WHEN tmp.pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) total_meatlovers
FROM tmp
GROUP BY
	tmp.customer_id;
```
&nbsp;
### 6. What was the maximum number of pizzas delivered in a single order?
```sql
WITH tmp AS
(
  SELECT
  	a.order_id,
  	c.pizza_name,
  	CASE WHEN a.pickup_time = 'null' THEN NULL
  		 ELSE a.pickup_time
  	END as pickup_time
  FROM pizza_runner.runner_orders 	a
  JOIN pizza_runner.customer_orders b on a.order_id = b.order_id
  JOIN pizza_runner.pizza_names		c on b.pizza_id = c.pizza_id
)
SELECT
	MAX(tmp2.total_pizzas_delivered)
FROM (
  SELECT
      tmp.order_id,
      COUNT(1) total_pizzas_delivered
  FROM tmp
  WHERE
      tmp.pickup_time IS NOT NULL
  GROUP BY
      tmp.order_id
  ) tmp2;
```
&nbsp;
### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
WITH tmp AS
(
  SELECT
  	a.order_id,
  	b.customer_id,
  	CASE WHEN a.pickup_time = 'null' THEN NULL
  		 ELSE a.pickup_time
  	END as pickup_time,
  	CASE WHEN b.exclusions IN ('null','') THEN 0
  		 ELSE 1
  	END as flag_has_exclusions,
  	CASE WHEN b.extras IN ('null','') THEN 0
  		 ELSE 1
  	END as flag_has_extras
  FROM pizza_runner.runner_orders 	a
  JOIN pizza_runner.customer_orders b on a.order_id = b.order_id
)
SELECT
	tmp.customer_id,
    SUM(CASE WHEN tmp.flag_has_exclusions + tmp.flag_has_extras >= 1 THEN 1 ELSE 0 END) as total_pizzas_with_1_more_changes,
    SUM(CASE WHEN tmp.flag_has_exclusions + tmp.flag_has_extras = 0 THEN 1 ELSE 0 END) as total_pizzas_with_no_changes
FROM tmp
WHERE
	tmp.pickup_time IS NOT NULL
GROUP BY
	tmp.customer_id;
```
&nbsp;
### 8. How many pizzas were delivered that had both exclusions and extras?
```sql
WITH tmp AS
(
  SELECT
  	a.order_id,
  	c.pizza_name,
  	CASE WHEN a.pickup_time = 'null' THEN NULL
  		 ELSE a.pickup_time
  	END as pickup_time,
  	CASE WHEN b.exclusions IN ('null','') THEN 0
  		 ELSE 1
  	END as flag_has_exclusions,
  	CASE WHEN b.extras IN ('null','') THEN 0
  		 ELSE 1
  	END as flag_has_extras
  FROM pizza_runner.runner_orders 	a
  JOIN pizza_runner.customer_orders b on a.order_id = b.order_id
  JOIN pizza_runner.pizza_names		c on b.pizza_id = c.pizza_id
)
SELECT
    SUM(CASE WHEN tmp.flag_has_exclusions = 1 AND tmp.flag_has_extras = 1 THEN 1 ELSE 0 END) as total_pizzas_with_exclusions_extras
FROM tmp
WHERE
	tmp.pickup_time IS NOT NULL;
```
&nbsp;
### 9. What was the total volume of pizzas ordered for each hour of the day?
```sql
SELECT
	DATE_PART('HOUR', order_time) as hour,
    COUNT(1) as volume_of_orders
FROM pizza_runner.customer_orders
GROUP BY
	DATE_PART('HOUR', order_time)
ORDER BY
	DATE_PART('HOUR', order_time) ASC;
```
&nbsp;
### 10. What was the volume of orders for each day of the week?
```sql
SELECT
	TO_CHAR(order_time,'day') as day_of_the_week,
    COUNT(1) as volume_of_orders
FROM pizza_runner.customer_orders
GROUP BY
	TO_CHAR(order_time,'day');
```