# SQL Challenge #3: Foodie Fi

<img src="https://8weeksqlchallenge.com/images/case-study-designs/3.png"
     alt="Markdown Monster icon" style="height:400px;width:400px;border-radius:5px;"/>

## Solution - Part A - Customer Journey

First I created a `VIEW` which consist in a customer journey across the subscriptions:

```sql
CREATE OR REPLACE VIEW foodie_fi.view_customer_subs_flow AS
WITH tmp_subscriptions AS
(
  SELECT
  	a.customer_id,
  	a.start_date,
  	b.plan_id,
  	b.plan_name,
  	b.price,
  	ROW_NUMBER() OVER (PARTITION BY a.customer_id ORDER BY b.plan_id ASC) ranking
  FROM foodie_fi.subscriptions a
  JOIN foodie_fi.plans b on a.plan_id = b.plan_id
)
SELECT
	tmp_cur.customer_id,
	tmp_cur.plan_id as plan_id_init,
    tmp_cur.plan_name as plan_name_init,
    tmp_cur.start_date as start_date_init,
    tmp_next.plan_id as plan_id_end,
	CASE WHEN tmp_next.plan_name IS NULL THEN 'current'
    	 ELSE tmp_next.plan_name END
    as plan_name_end,
	tmp_next.start_date as start_date_end,
    tmp_next.start_date - tmp_cur.start_date as "# days",
    tmp_cur.price as price
FROM tmp_subscriptions as tmp_cur
LEFT JOIN
	 tmp_subscriptions as tmp_next
    	ON tmp_cur.customer_id = tmp_next.customer_id
           AND
           tmp_cur.ranking = (tmp_next.ranking - 1);
```

Now let's make the following query:
```sql
SELECT *
FROM foodie_fi.view_customer_subs_flow
WHERE customer_id IN (1,2,11, 13, 15,16,18,19)
ORDER BY customer_id, plan_id_init;
```

|customer_id|plan_id_init|plan_name_init|start_date_init|plan_id_end|plan_name_end|start_date_end|# days|price|
|:----|:----|:----|:----|:----|:----|:----|:----|:----|
|1|0|trial|2020-08-01|1|basic monthly|2020-08-08|7|0.00|
|1|1|basic monthly|2020-08-08| |current| | |9.90|
|2|0|trial|2020-09-20|3|pro annual|2020-09-27|7|0.00|
|2|3|pro annual|2020-09-27| |current| | |199.00|
|11|0|trial|2020-11-19|4|churn|2020-11-26|7|0.00|
|11|4|churn|2020-11-26| |current| | | |
|13|0|trial|2020-12-15|1|basic monthly|2020-12-22|7|0.00|
|13|1|basic monthly|2020-12-22|2|pro monthly|2021-03-29|97|9.90|
|13|2|pro monthly|2021-03-29| |current| | |19.90|
|15|0|trial|2020-03-17|2|pro monthly|2020-03-24|7|0.00|
|15|2|pro monthly|2020-03-24|4|churn|2020-04-29|36|19.90|
|15|4|churn|2020-04-29| |current| | | |
|16|0|trial|2020-05-31|1|basic monthly|2020-06-07|7|0.00|
|16|1|basic monthly|2020-06-07|3|pro annual|2020-10-21|136|9.90|
|16|3|pro annual|2020-10-21| |current| | |199.00|
|18|0|trial|2020-07-06|2|pro monthly|2020-07-13|7|0.00|
|18|2|pro monthly|2020-07-13| |current| | |19.90|
|19|0|trial|2020-06-22|2|pro monthly|2020-06-29|7|0.00|
|19|2|pro monthly|2020-06-29|3|pro annual|2020-08-29|61|19.90|
|19|3|pro annual|2020-08-29| |current| | |199.00|

This is a brief description of each of these customers:
- **Customer 1**: currently with a basic monthly plan since 2020-08-08
- **Customer 2**: the only client who decided to upgrade to the pro annual plan after the trial plan ended.
- **Customer 11**: the only client who decided to unsubscribe after the trial plan ended.
- **Customer 13**: currently with a pro basic monthly plan after more than 3 months with the basic monthly plan.
- **Customer 15**: unsubscribed after more than 43 days with the app.
- **Customer 16**: subscribed to a pro annual plan after 136 days with a monthly plan.
- **Customer 18**: currently with a pro monthly plan after the trial.
- **Customer 19**: subscribed to a pro annual plan after 2 months with a monthly plan.