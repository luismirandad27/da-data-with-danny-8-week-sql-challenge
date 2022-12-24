/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
	a.customer_id, 
    sum(b.price) as total_amount
FROM dannys_diner.sales a
JOIN dannys_diner.menu b on a.product_id = b.product_id
GROUP BY
	a.customer_id
ORDER BY 
	a.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT
	a.customer_id,
    count(distinct a.order_date) as number_of_days
FROM dannys_diner.sales a
GROUP BY
	a.customer_id;


-- 3. What was the first item from the menu purchased by each customer?

SELECT
	tmp.customer_id,
    to_char(tmp.order_date,'yyyy-mm-dd') as order_date,
    tmp.product_name as first_item
FROM (
  SELECT
      a.customer_id,
      a.order_date,
      b.product_name,
      row_number() over (partition by a.customer_id order by a.order_date, a.product_id) as ranking
  FROM dannys_diner.sales a
  JOIN dannys_diner.menu b on a.product_id = b.product_id
) tmp
WHERE
	tmp.ranking = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	tmp2.product_name,
    tmp2.times_purchased
FROM (
  SELECT
      tmp.product_name,
      tmp.times_purchased,
      row_number() over (order by tmp.times_purchased desc) ranking
  FROM (
    SELECT
        b.product_name,
        count(1) as times_purchased
    FROM dannys_diner.sales a
    JOIN dannys_diner.menu b on a.product_id = b.product_id
    GROUP BY b.product_name
  ) tmp
) tmp2
WHERE
	tmp2.ranking = 1;

-- 5. Which item was the most popular for each customer?
SELECT 
	tmp2.customer_id,
	tmp2.product_name as product_most_popular
FROM (
  SELECT
  	  tmp.customer_id,
      tmp.product_name,
      tmp.times_purchased,
      row_number() over (partition by tmp.customer_id order by tmp.times_purchased desc) ranking
  FROM (
    SELECT
    	a.customer_id,
        b.product_name,
        count(1) as times_purchased
    FROM dannys_diner.sales a
    JOIN dannys_diner.menu b on a.product_id = b.product_id
    GROUP BY a.customer_id,b.product_name
  ) tmp
) tmp2
WHERE
	tmp2.ranking = 1;


-- 6. Which item was purchased first by the customer after they became a member?

SELECT
	tmp.customer_id,
    tmp.product_name as first_purchased_item_after_membership
FROM (
  SELECT 
      a.customer_id,
      c.product_name,
  	  a.order_date,
      row_number() over (partition by a.customer_id order by a.order_date,a.product_id) ranking
  FROM dannys_diner.sales a
  JOIN dannys_diner.members b on a.customer_id = b.customer_id
  JOIN dannys_diner.menu c on a.product_id = c.product_id
  WHERE a.order_date >= b.join_date
) tmp
WHERE
	tmp.ranking = 1;

-- 7. Which item was purchased just before the customer became a member?

SELECT
	tmp.customer_id,
    tmp.product_name as last_purchased_item_befor_membership
FROM (
  SELECT 
      a.customer_id,
      c.product_name,
  	  a.order_date,
  	  a.product_id,
      row_number() over (partition by a.customer_id order by a.order_date desc,a.product_id) ranking
  FROM dannys_diner.sales a
  JOIN dannys_diner.members b on a.customer_id = b.customer_id
  JOIN dannys_diner.menu c on a.product_id = c.product_id
  WHERE a.order_date < b.join_date
) tmp
WHERE
	tmp.ranking = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
      a.customer_id,
      count(1) as total_items,
      sum(c.price) as total_amount_spent
FROM dannys_diner.sales a
JOIN dannys_diner.members b on a.customer_id = b.customer_id
JOIN dannys_diner.menu c on a.product_id = c.product_id
WHERE a.order_date < b.join_date
GROUP BY 
	a.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT
	a.customer_id,
	sum(case when c.join_date <= a.order_date then
                  case when b.product_name = 'sushi' then b.price*10*2
                  else b.price*10
                  end
                  
             else 0
    end) as total_points
FROM dannys_diner.sales a
JOIN dannys_diner.menu b on a.product_id = b.product_id
JOIN dannys_diner.members c on a.customer_id = c.customer_id
GROUP BY
	a.customer_id
ORDER BY
	a.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT
	a.customer_id,
    sum(case when c.join_date <= a.order_date then
        	  	  case when a.order_date - c.join_date between 0 and 6 then b.price*10*2
        			   else 
        					case when b.product_name = 'sushi' then b.price*10*2
                       			 else b.price*10
       						end
                  end
             else 0
    end) as total_points
FROM dannys_diner.sales a
JOIN dannys_diner.menu b on a.product_id = b.product_id
JOIN dannys_diner.members c on a.customer_id = c.customer_id
WHERE 
    a.order_date <= '2021-01-31'
GROUP BY 
	a.customer_id;