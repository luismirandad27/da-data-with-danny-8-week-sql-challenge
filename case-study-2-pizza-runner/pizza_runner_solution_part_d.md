# SQL Challenge #2: Pizza Runner

<img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png"
     alt="Markdown Monster icon" style="height:400px;width:400px;border-radius:5px;"/>

## Solution - Part D - Pricing and Ratings

### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
```sql
WITH tmp AS (
  SELECT
	a.order_id,
  	CASE WHEN a.pizza_id = 1 THEN 12
  		 WHEN a.pizza_id = 2 THEN 10
  		 ELSE 0
  	END AS pizza_cost
  FROM pizza_runner.customer_orders a
  JOIN pizza_runner.runner_orders b on a.order_id = b.order_id
  WHERE b.pickup_time != 'null'
)
SELECT
	ROUND(SUM(pizza_cost),2) AS total_money_earned
FROM tmp;
```
&nbsp;
### 2.What if there was an additional $1 charge for any pizza extras?
- Add cheese is $1 extra
```sql
WITH tmp AS (
  SELECT
	a.order_id,
  	CASE WHEN a.pizza_id = 1 THEN 12
  		 WHEN a.pizza_id = 2 THEN 10
  		 ELSE 0
  	END AS pizza_cost,
	CASE WHEN a.extras LIKE '%4%' THEN 1
  		 ELSE 0
 	END as pizza_extra_cost
  FROM pizza_runner.customer_orders a
  JOIN pizza_runner.runner_orders b on a.order_id = b.order_id
  WHERE b.pickup_time != 'null'
)
SELECT
	ROUND(SUM(pizza_cost + pizza_extra_cost),2) AS total_money_earned
FROM tmp;
```
&nbsp;
### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

```sql
DROP TABLE IF EXISTS pizza_runner.customer_order_ratings;
CREATE TABLE pizza_runner.customer_order_ratings(
  "order_id" INTEGER,
  "rating"	INTEGER
);

INSERT INTO pizza_runner.customer_order_ratings
(order_id,rating)
VALUES
	(1,4),
    (2,4),
    (3,5),
    (4,1),
    (5,2),
    (6,3),
    (7,5),
    (8,3),
    (9,4),
    (10,4);

SELECT * FROM pizza_runner.customer_order_ratings;
```
&nbsp;
### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas
```sql
WITH tmp AS (
  SELECT
      a.customer_id,
      a.order_id,
      b.runner_id,
      c.rating,
      a.order_time,
      CASE WHEN b.pickup_time = 'null' THEN NULL 
           ELSE b.pickup_time 
      END AS pickup_time,
      CASE WHEN b.pickup_time = 'null' THEN NULL ELSE
      DATE_PART('minutes',CAST(b.pickup_time AS timestamp) - CAST(a.order_time AS timestamp)) + DATE_PART('seconds',CAST(b.pickup_time AS timestamp) - CAST(a.order_time AS timestamp))/60 END as time_between_order_pickup,
      CASE WHEN b.pickup_time = 'null' THEN NULL ELSE
      CAST(
          CASE WHEN duration LIKE '%minutes' THEN REPLACE(duration,'minutes','')
               WHEN duration LIKE '%mins' THEN REPLACE(duration,'mins','')
               WHEN duration LIKE '%minute' THEN REPLACE(duration,'minute','')
               ELSE duration
          END
        AS numeric)/60 END as duration_hours,
      CASE WHEN b.pickup_time = 'null' THEN NULL ELSE
        CAST(
          CASE WHEN b.distance LIKE '%km%' THEN REPLACE(b.distance,'km','')
               ELSE b.distance
          END
        AS numeric) END AS distance_km
  FROM pizza_runner.customer_orders a
  JOIN pizza_runner.runner_orders b on a.order_id = b.order_id
  JOIN pizza_runner.customer_order_ratings c on a.order_id = c.order_id
)
SELECT 
	customer_id,
    order_id,
    runner_id,
    rating,
    order_time,
    pickup_time,
    ROUND(time_between_order_pickup::numeric,2) AS time_between_order_pickup ,
    ROUND(duration_hours::numeric,2) as delivery_duration,
    ROUND(AVG(tmp.distance_km/tmp.duration_hours)::numeric,2) as average_speed,
    COUNT(1) as total_pizzas_in_ordered
FROM tmp
GROUP BY
	customer_id,
    order_id,
    runner_id,
    rating,
    order_time,
    pickup_time,
    ROUND(time_between_order_pickup::numeric,2),
    ROUND(duration_hours::numeric,2);
```
&nbsp;   
### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
```sql 
WITH tmp_cost AS (
  SELECT
	a.order_id,
  	SUM(CASE WHEN a.pizza_id = 1 THEN 12
  		 WHEN a.pizza_id = 2 THEN 10
  		 ELSE 0
  	END) AS pizza_cost_per_order
  FROM pizza_runner.customer_orders a
  JOIN pizza_runner.runner_orders b on a.order_id = b.order_id
  WHERE b.pickup_time != 'null'
  GROUP BY 
   	a.order_id
),
tmp_distance AS(
  SELECT
  	DISTINCT
	a.order_id,
  	CASE WHEN b.pickup_time = 'null' THEN NULL ELSE
        CAST(
          CASE WHEN b.distance LIKE '%km%' THEN REPLACE(b.distance,'km','')
               ELSE b.distance
          END
        AS numeric) END AS distance_km
  FROM pizza_runner.customer_orders a
  JOIN pizza_runner.runner_orders b on a.order_id = b.order_id
  WHERE b.pickup_time != 'null'
)
SELECT
    SUM(a.pizza_cost_per_order - 0.3* b.distance_km) AS money_left
FROM tmp_cost a
JOIN tmp_distance b on a.order_id = b.order_id;
```
&nbsp;