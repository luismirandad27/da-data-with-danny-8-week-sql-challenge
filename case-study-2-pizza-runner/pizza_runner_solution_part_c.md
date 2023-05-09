# SQL Challenge #2: Pizza Runner

<img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png"
     alt="Markdown Monster icon" style="height:400px;width:400px;border-radius:5px;"/>

## Solution - Part C - Ingredient Optimisation

### 1. What are the standard ingredients for each pizza?
```sql
WITH tmp AS (
  SELECT
      a.pizza_name,
      unnest(string_to_array(b.toppings, ', '))::numeric topping_id
  FROM pizza_runner.pizza_names a
  JOIN pizza_runner.pizza_recipes b on a.pizza_id = b.pizza_id
)
SELECT
	a.pizza_name,
    string_agg(b.topping_name, ', ') as ingredients_list
FROM tmp a
JOIN pizza_runner.pizza_toppings b on a.topping_id = b.topping_id
GROUP BY
	a.pizza_name;
```
&nbsp;
### 2. What was the most commonly added extra?
```sql
WITH tmp AS (
  SELECT
      order_id,
      unnest(string_to_array(CASE WHEN extras IN('','null') THEN NULL
                                  ELSE extras
                              END,
                             ', ')
            )::numeric AS extra_id
  FROM pizza_runner.customer_orders
)
SELECT
	b.topping_name as extra_topping,
    COUNT(1) as total_extra_added
FROM tmp
JOIN pizza_runner.pizza_toppings b on tmp.extra_id = b.topping_id
GROUP BY
	b.topping_name
ORDER BY 2 DESC;
```
&nbsp;
### 3. What was the most common exclusion?
```sql
WITH tmp AS (
  SELECT
      order_id,
      unnest(string_to_array(CASE WHEN exclusions IN('','null') THEN NULL
                                  ELSE exclusions
                              END,
                             ', ')
            )::numeric AS exclusion_id
  FROM pizza_runner.customer_orders
)
SELECT
	b.topping_name as excluded_topping,
    COUNT(1) as total_exclusion_added
FROM tmp
JOIN pizza_runner.pizza_toppings b on tmp.exclusion_id = b.topping_id
GROUP BY
	b.topping_name
ORDER BY 2 DESC;
```
&nbsp;
### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
```sql
CREATE OR REPLACE VIEW pizza_runner.v_orders_detailed AS
WITH tmp_exclusions AS(
  SELECT
	order_id,
    pizza_id,
    pos,
    string_agg(b.topping_name,', ') as exclusions_list
  FROM (
        SELECT
          order_id,
          pizza_id,
          row_number() over (order by order_id, pizza_id, exclusions,extras) as pos,
          unnest(string_to_array(CASE WHEN exclusions IN('','null') THEN NULL
                                 ELSE exclusions
                                 END,
                                 ', ')
                )::numeric AS exclusion_id
        FROM pizza_runner.customer_orders a
  ) tmp
  JOIN pizza_runner.pizza_toppings b on tmp.exclusion_id = b.topping_id
  GROUP BY 
      order_id, pizza_id, pos
),tmp_extras AS(
  SELECT
	order_id,
    pizza_id,
    pos,
    string_agg(b.topping_name,', ') as extras_list
  FROM (
        SELECT
          order_id,
          pizza_id,
          row_number() over (order by order_id, pizza_id, exclusions,extras) as pos,
          unnest(string_to_array(CASE WHEN extras IN('','null') THEN NULL
                                 ELSE extras
                                 END,
                                 ', ')
                )::numeric AS extra_id
        FROM pizza_runner.customer_orders a
  ) tmp
  JOIN pizza_runner.pizza_toppings b on tmp.extra_id = b.topping_id
  GROUP BY 
      order_id, pizza_id, pos
)
SELECT
	a.pos,
	a.order_id,
    a.customer_id,
    a.pizza_id,
    p.pizza_name,
    b.exclusions_list,
    c.extras_list,
    CONCAT(p.pizza_name,' - ',
          CASE WHEN b.exclusions_list IS NULL THEN 'No Exclusions - ' 
               ELSE CONCAT('Exclude: ',b.exclusions_list, ' - ' ) 
          END,
          CASE WHEN c.extras_list IS NULL THEN ' No Extras' 
               ELSE CONCAT('Extra ',c.extras_list) 
          END) as order_description
FROM (SELECT order_id, pizza_id, customer_id, row_number() over (order by order_id, pizza_id, exclusions,extras) as pos FROM pizza_runner.customer_orders) a
LEFT JOIN tmp_exclusions  b on a.pos = b.pos
LEFT JOIN tmp_extras  c on a.pos = c.pos
LEFT JOIN pizza_runner.pizza_names p on a.pizza_id = p.pizza_id
ORDER BY
	a.pos,
	a.order_id,
    a.customer_id,
    p.pizza_name;
```
Then you can check your data by a simple SELECT
```sql
SELECT * FROM pizza_runner.v_orders_detailed;
```
&nbsp;
### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
```sql
CREATE OR REPLACE VIEW pizza_runner.v_orders_detailed_summary AS
WITH tmp AS (
  SELECT
  	recipe_list.pizza_id,
  	b.topping_name
  FROM 
  (
    SELECT
        pizza_id,
        unnest(string_to_array(toppings, ', '))::numeric topping_id
    FROM pizza_runner.pizza_recipes
  ) recipe_list
  JOIN pizza_runner.pizza_toppings b on recipe_list.topping_id = b.topping_id
)
SELECT
	final_tmp.pos,
    final_tmp.order_id,
    final_tmp.pizza_name,
    string_agg(final_tmp.topping_name,', ' ORDER BY final_tmp.topping_name) as final_recipe
FROM (
  SELECT
  	  a.pos,
      a.order_id,
      a.pizza_name,
      a.extras_list,
      a.exclusions_list,
      CASE WHEN a.extras_list LIKE CONCAT('%',b.topping_name,'%')  THEN CONCAT('2x',b.topping_name)
           WHEN a.exclusions_list LIKE CONCAT('%',b.topping_name,'%') THEN NULL
           ELSE b.topping_name
      END AS topping_name
  FROM pizza_runner.v_orders_detailed a
  JOIN tmp b on a.pizza_id = b.pizza_id
) AS final_tmp
WHERE final_tmp.topping_name IS NOT NULL
GROUP BY final_tmp.pos,final_tmp.order_id,final_tmp.pizza_name
ORDER BY final_tmp.pos,final_tmp.order_id;
```
&nbsp;
Check your data by this SELECT.
```sql
SELECT
	order_id,
    CONCAT(pizza_name,': ',final_recipe) AS final_recipe
FROM pizza_runner.v_orders_detailed_summary;
```
&nbsp;
### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
```sql
WITH tmp AS (
  SELECT
  	recipe_list.pizza_id,
  	b.topping_name
  FROM 
  (
    SELECT
        pizza_id,
        unnest(string_to_array(toppings, ', '))::numeric topping_id
    FROM pizza_runner.pizza_recipes
  ) recipe_list
  JOIN pizza_runner.pizza_toppings b on recipe_list.topping_id = b.topping_id
)
SELECT
	final_tmp.topping_name as ingredient_name,
    COUNT(1) as count_toppings
FROM (
  SELECT
  	  a.pos,
      a.order_id,
      a.pizza_name,
      a.extras_list,
      a.exclusions_list,
      CASE WHEN a.extras_list LIKE CONCAT('%',b.topping_name,'%')  THEN CONCAT('2x',b.topping_name)
           WHEN a.exclusions_list LIKE CONCAT('%',b.topping_name,'%') THEN NULL
           ELSE b.topping_name
      END AS topping_name
  FROM pizza_runner.v_orders_detailed a
  JOIN tmp b on a.pizza_id = b.pizza_id
) AS final_tmp
GROUP BY final_tmp.topping_name
ORDER BY COUNT(1) DESC;
```
&nbsp;