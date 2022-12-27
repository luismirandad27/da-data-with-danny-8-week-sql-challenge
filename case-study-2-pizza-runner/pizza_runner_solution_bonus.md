# SQL Challenge #2: Pizza Runner

<img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png"
     alt="Markdown Monster icon" style="height:400px;width:400px;border-radius:5px;"/>

## Question's Solutions - Part E - Bonus Question

### If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
&nbsp;
#### First we need to add the new *Supreme* pizza info to the menu.
```sql
INSERT INTO pizza_runner.pizza_names
VALUES('3','Supreme');

INSERT INTO pizza_runner.pizza_toppings
VALUES('13','Meatballs');

-- Adding all the topics for the recipe of a Supreme pizza
INSERT INTO pizza_runner.pizza_recipes
VALUES('3','1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13');
```
&nbsp; 
#### Finally we can add the order.
```sql
INSERT INTO pizza_runner.customer_orders
VALUES
('11','101','3', '','','2022-12-26 18:34:49');

INSERT INTO pizza_runner.runner_orders
VALUES
('11','1','2022-12-26 19:04:00','10km','20 minutes',NULL);
```
