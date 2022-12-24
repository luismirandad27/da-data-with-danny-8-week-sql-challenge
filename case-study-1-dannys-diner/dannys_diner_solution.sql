/* -------------------------
   Case Study Bonus Question
   -------------------------*/

/*
1. Join All The Things

The following questions are related creating basic data tables that Danny and his team can 
use to quickly derive insights without needing to join the underlying tables using SQL.
*/
SELECT
	a.customer_id,
    to_char(a.order_date,'yyyy-mm-dd') as order_date,
    b.product_name,
    b.price,
    case when c.join_date IS NULL then 'N'
    	 when c.join_date <= a.order_date then 'Y'
    	 else 'N'
    end as member
FROM dannys_diner.sales a
JOIN dannys_diner.menu b on a.product_id = b.product_id
LEFT JOIN dannys_diner.members c on a.customer_id = c.customer_id
ORDER BY
	a.customer_id,
    a.order_date,
    case when c.join_date >= a.order_date then 'Y'
    	 else 'N'
    end,
    b.product_name,
    b.product_name;

/*
2. Rank All The Things

Danny also requires further information about the ranking of customer products, but he purposely does not 
need the ranking for non-member purchases so he expects null ranking values for the records when customers 
are not yet part of the loyalty program.
*/

WITH tmp as (
SELECT
	a.customer_id,
    a.order_date,
    b.product_name,
    b.price,
    case when c.join_date IS NULL then 'N'
    	 when c.join_date <= a.order_date then 'Y'
    	 else 'N'
    end as member
FROM dannys_diner.sales a
JOIN dannys_diner.menu b on a.product_id = b.product_id
LEFT JOIN dannys_diner.members c on a.customer_id = c.customer_id
)
SELECT 
	f.customer_id,
    to_char(f.order_date,'yyyy-mm-dd') as order_date,
    f.product_name,
    f.price,
    f.member,
    case when f.member ='N' then null
    	 else rank() over (partition by f.customer_id,f.member order by f.customer_id, f.order_date,f.product_name) 
    end ranking 
FROM tmp f;

