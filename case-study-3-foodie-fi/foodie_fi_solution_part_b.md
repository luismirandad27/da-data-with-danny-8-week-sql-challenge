# SQL Challenge #3: Foodie Fi

<img src="https://8weeksqlchallenge.com/images/case-study-designs/3.png"
     alt="Markdown Monster icon" style="height:400px;width:400px;border-radius:5px;"/>

## Solution - Part B - Data Analysis Questions

### 1. How many customers has Foodie-Fi ever had?
```sql
SELECT count(distinct customer_id) total_customers 
FROM foodie_fi.subscriptions;
```
### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
```sql
SELECT CAST(TO_CHAR(start_date, 'yyyy') AS INT)*100 +
	   CAST(TO_CHAR(start_date,'MM') AS INT) AS month_code,
	   TO_CHAR(start_date, 'yyyy') AS year,
       TO_CHAR(start_date, 'MON') AS month,
       COUNT(1) num_of_subscriptions
FROM foodie_fi.subscriptions 
WHERE plan_id = '0'
GROUP BY
	CAST(TO_CHAR(start_date, 'yyyy') AS INT)*100 +
	   CAST(TO_CHAR(start_date,'MM') AS INT),
       	   TO_CHAR(start_date, 'yyyy'),
       TO_CHAR(start_date, 'MON')
ORDER BY
    CAST(TO_CHAR(start_date, 'yyyy') AS INT)*100 +
	   CAST(TO_CHAR(start_date,'MM') AS INT)
;
```
### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
```sql
SELECT
	plan.plan_name,
    COUNT(1) as number_of_events
FROM foodie_fi.subscriptions subs
JOIN foodie_fi.plans plan
ON subs.plan_id = plan.plan_id
WHERE CAST(TO_CHAR(start_date,'yyyy') AS INT) > 2020
GROUP BY plan.plan_name;
```         

### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```sql
WITH tmp_customers AS
(
	SELECT
  		COUNT(DISTINCT customer_id)::numeric AS total_customers,
  		SUM(CASE WHEN plan_id = '4' THEN 1 ELSE 0 END)::numeric AS total_customers_churn
	FROM foodie_fi.subscriptions
)
SELECT
	total_customers_churn,
    ROUND((total_customers_churn/total_customers)*100,2)::numeric || '%' as percentage
FROM tmp_customers;
```

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

```sql
WITH tmp_aggregations AS
         (SELECT COUNT(DISTINCT customer_id)                                           AS total_customers,
                 SUM(CASE WHEN plan_id_init = 0 AND plan_id_end = 4 THEN 1 ELSE 0 END) as total_cust_trial_to_churn
          FROM foodie_fi.view_customer_subs_flow
        )
SELECT
    total_cust_trial_to_churn,
    ROUND((total_cust_trial_to_churn::numeric/total_customers::numeric)*100,0) || '%' AS percentage
    FROM tmp_aggregations;
```

### 6. What is the number and percentage of customer plans after their initial free trial?

```sql
SELECT
    plan_name_end,
    COUNT(1) AS total_customers,
    ROUND(COUNT(1) / (SUM(COUNT(1)) OVER ())*100,2) || '%' AS percentage
FROM foodie_fi.view_customer_subs_flow
WHERE plan_id_init = '0'
GROUP BY
    plan_name_end
;
```

### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
```sql
WITH tmp_last_plan AS (
    SELECT
        customer_id,
        MAX(plan_id_init) max_plan_id_init
    FROM foodie_fi.view_customer_subs_flow
    WHERE plan_id_end IS NULL AND start_date_init <= DATE '2020-12-31'
    GROUP BY
        customer_id
),
tmp_flow AS
    (SELECT max_plan_id_init,
            COUNT(1) total_customers_by_plan
     FROM tmp_last_plan
     GROUP BY max_plan_id_init)
SELECT
    plan_name,
    CASE WHEN flow.total_customers_by_plan IS NULL THEN 0 ELSE flow.total_customers_by_plan END total_customers,
    (CASE WHEN flow.total_customers_by_plan IS NULL THEN 0.00
        ELSE ROUND(flow.total_customers_by_plan/SUM(total_customers_by_plan) OVER()*100,2)
        END) || '%' AS percentage
FROM foodie_fi.plans plans
LEFT JOIN tmp_flow as flow on plans.plan_id = flow.max_plan_id_init;
```

### 8. How many customers have upgraded to an annual plan in 2020?
```sql
SELECT COUNT(1) AS num_of_customers
FROM foodie_fi.view_customer_subs_flow
WHERE plan_id_init = 3 AND TO_CHAR(start_date_init,'YYYY') = '2020';
```

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```sql
WITH tmp_duration_plan AS
         (SELECT DISTINCT A.customer_id,
                          C.start_date - B.start_date AS num_of_days
          FROM foodie_fi.subscriptions as A
                   LEFT JOIN foodie_fi.subscriptions as B ON A.customer_id = B.customer_id AND B.plan_id = '0'
                   LEFT JOIN foodie_fi.subscriptions as C ON A.customer_id = C.customer_id AND C.plan_id = '3'
          WHERE C.plan_id IS NOT NULL)
SELECT
    ROUND(AVG(num_of_days),0) AS avg_of_days
FROM tmp_duration_plan;
```

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
```sql
WITH tmp_duration_plan AS
         (SELECT DISTINCT A.customer_id,
                          C.start_date - B.start_date AS num_of_days
          FROM foodie_fi.subscriptions as A
                   LEFT JOIN foodie_fi.subscriptions as B ON A.customer_id = B.customer_id AND B.plan_id = '0'
                   LEFT JOIN foodie_fi.subscriptions as C ON A.customer_id = C.customer_id AND C.plan_id = '3'
          WHERE C.plan_id IS NOT NULL)
SELECT
    CASE WHEN num_of_days BETWEEN 0 AND 30 THEN '0-30 days'
         WHEN num_of_days BETWEEN 31 AND 60 THEN '31-60 days'
         WHEN num_of_days BETWEEN 61 AND 90 THEN '61-90 days'
         ELSE 'more than 90 days'
    END AS "30_day_periods",
    ROUND(AVG(num_of_days),2) AS avg_num_days
FROM tmp_duration_plan
GROUP BY
    CASE WHEN num_of_days BETWEEN 0 AND 30 THEN '0-30 days'
         WHEN num_of_days BETWEEN 31 AND 60 THEN '31-60 days'
         WHEN num_of_days BETWEEN 61 AND 90 THEN '61-90 days'
         ELSE 'more than 90 days'
    END;
```

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```sql
SELECT COUNT(1) AS customers_downgraded
FROM view_customer_subs_flow
WHERE plan_id_init = 2 AND plan_id_end = 1;
```
