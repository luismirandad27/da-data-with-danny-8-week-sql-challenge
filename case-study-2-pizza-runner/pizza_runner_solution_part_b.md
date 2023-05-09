# SQL Challenge #2: Pizza Runner

<img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png"
     alt="Markdown Monster icon" style="height:400px;width:400px;border-radius:5px;"/>

## Solution - Part B - Runner and Customer Experience

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
SELECT
    to_char(registration_date::date, 'ww')::int week_number,
    COUNT(1) AS total_runners_signed_up
FROM pizza_runner.runners
GROUP BY 
	to_char(registration_date::date, 'ww')::int
ORDER BY
	to_char(registration_date::date, 'ww')::int;
```
&nbsp;
### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
WITH tmp AS (
    SELECT
        a.runner_id,
        DATE_PART('minutes',CAST(a.pickup_time AS timestamp) - CAST(b.order_time AS timestamp)) + DATE_PART('seconds',CAST(a.pickup_time AS timestamp) - CAST(b.order_time AS timestamp))/60 as pickup_time_length
    FROM pizza_runner.runner_orders a
    JOIN pizza_runner.customer_orders b on a.order_id = b.order_id
    WHERE a.pickup_time != 'null'
  )
SELECT
	tmp.runner_id,
	ROUND(AVG(tmp.pickup_time_length)::numeric,2) as average_pickup_time_length
FROM tmp
GROUP BY
	tmp.runner_id
ORDER BY
	tmp.runner_id;
```
&nbsp;
### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
WITH tmp AS (
  SELECT
  	b.order_id,
    DATE_PART('minutes',CAST(a.pickup_time AS timestamp) - CAST(b.order_time AS timestamp)) + DATE_PART('seconds',CAST(a.pickup_time AS timestamp) - CAST(b.order_time AS timestamp))/60 as prep_time,
  	COUNT(1) AS number_of_pizzas
  FROM pizza_runner.runner_orders a
  JOIN pizza_runner.customer_orders b on a.order_id = b.order_id
  WHERE 
      a.pickup_time != 'null'
  GROUP BY
      b.order_id,
  	  DATE_PART('minutes',CAST(a.pickup_time AS timestamp) - CAST(b.order_time AS timestamp)) + DATE_PART('seconds',CAST(a.pickup_time AS timestamp) - CAST(b.order_time AS timestamp))/60
)
SELECT
	tmp.number_of_pizzas,
	ROUND(AVG(tmp.prep_time)::numeric) as preparation_time_in_minutes
FROM tmp
GROUP BY
	tmp.number_of_pizzas;
```
&nbsp;
### 4. What was the average distance travelled for each customer?
```sql
WITH tmp AS (
  SELECT
  	DISTINCT
  	b.customer_id,
  	CAST(
      CASE WHEN a.distance LIKE '%km%' THEN REPLACE(a.distance,'km','')
           ELSE a.distance
      END
    AS float) AS distance
  FROM pizza_runner.runner_orders a
  JOIN pizza_runner.customer_orders b on a.order_id = b.order_id
  WHERE
  	pickup_time != 'null'
)
SELECT
	tmp.customer_id,
    AVG(tmp.distance) AS average_distance_travelled
FROM tmp
GROUP BY
	tmp.customer_id
ORDER BY
	tmp.customer_id;
```
&nbsp;
### 5. What was the difference between the longest and shortest delivery times for all orders?
```sql
WITH tmp AS (
	SELECT
	  order_id,  	  
      CAST(
        CASE WHEN duration LIKE '%minutes' THEN REPLACE(duration,'minutes','')
             WHEN duration LIKE '%mins' THEN REPLACE(duration,'mins','')
             WHEN duration LIKE '%minute' THEN REPLACE(duration,'minute','')
             ELSE duration
        END
      AS numeric) as duration
  	FROM pizza_runner.runner_orders
  	WHERE 
  		pickup_time != 'null'
)
SELECT
	MAX(tmp.duration)-MIN(tmp.duration) AS longest_shortest_deltime_diff
FROM tmp;
```
&nbsp;
### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
WITH tmp AS (
  SELECT
    runner_id,
  	CAST(
      CASE WHEN distance LIKE '%km%' THEN REPLACE(distance,'km','')
           ELSE distance
      END
    AS numeric) AS distance_km,
    CAST(
      CASE WHEN duration LIKE '%minutes' THEN REPLACE(duration,'minutes','')
      WHEN duration LIKE '%mins' THEN REPLACE(duration,'mins','')
      WHEN duration LIKE '%minute' THEN REPLACE(duration,'minute','')
      ELSE duration
      END
      AS numeric)/60 as duration_hours
  FROM pizza_runner.runner_orders
  WHERE 
  	pickup_time != 'null'
)
SELECT
	tmp.runner_id,
	ROUND(AVG(tmp.distance_km/tmp.duration_hours)::numeric,2) AS average_speed
FROM tmp
GROUP BY
	tmp.runner_id;
```
&nbsp;
### 7. What is the successful delivery percentage for each runner?
```sql
WITH tmp AS (
  SELECT
      runner_id,
      SUM(CASE WHEN pickup_time = 'null' THEN 0 ELSE 1 END) AS total_order_delivered,
  	  COUNT(1) total_order_assigned
  FROM pizza_runner.runner_orders
  GROUP BY
  	  runner_id
)
SELECT
	tmp.runner_id,
    (CAST(tmp.total_order_delivered AS float)/CAST(tmp.total_order_assigned AS float))*100 as delivery_percentage
FROM tmp
ORDER BY 
	tmp.runner_id;
```