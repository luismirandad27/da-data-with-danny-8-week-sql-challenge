# SQL Challenge #3: Foodie Fi

<img src="https://8weeksqlchallenge.com/images/case-study-designs/3.png"
     alt="Markdown Monster icon" style="height:400px;width:400px;border-radius:5px;"/>

## Solution - Part C - Challenge Payment Question

The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan.
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately.
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period.
- once a customer churns they will no longer make payments.

For this scenario, I tried to use `PostgreSQL PL/pgSQL`, a procedural language that extends SQL, just to practice a little bit :)

```sql
do
$$
    declare

        cur_customer_id integer;
        --cursor to get the list of customers
        cur_customers cursor for
            select distinct customer_id AS cur_customer_id
            from foodie_fi.subscriptions;
        rec_subs_flow   record;
        --cursor to get the list of subscriptions movements by customer_id
        cur_subs_flow cursor (p_customer_id integer) for
            select *
            from foodie_fi.view_customer_subs_flow
            where customer_id = p_customer_id;
        payment_order   integer;
        start_date      date;
        end_date        date;
        price           float;
        str_query       varchar(1000);

    begin

        --create table payments
        execute 'drop table if exists foodie_fi.payments';
        execute 'create table foodie_fi.payments' ||
                '( customer_id integer, plan_id integer, plan_name varchar(50), payment_date date, amount float, payment_order integer)';

        open cur_customers;

        loop
            --fetch row
            fetch cur_customers into cur_customer_id;

            --exit when not found
            exit when not found;

            --for each customer, initialize the payment_order
            payment_order := 1;

            open cur_subs_flow(cur_customer_id);

            loop

                --fetch row
                fetch cur_subs_flow into rec_subs_flow;

                --exit when not found
                exit when not found;

                --if the plan id init is trial or churn, we don't have to add any payment row
                if rec_subs_flow.plan_id_init not in (0, 4) then

                    --if the subscription upgrade occured in the same month, decrease the price.
                    if extract(MONTH FROM start_date) - 1 = extract(MONTH FROM rec_subs_flow.start_date_init) THEN
                        price := rec_subs_flow.price - price;
                    else
                        price := rec_subs_flow.price;
                    end if;

                    start_date := rec_subs_flow.start_date_init;

                    -- if the start_date of the last movement is null or the start_date happened in 2021 or later
                    -- assign the end_date to the last date of 2020
                    if rec_subs_flow.start_date_end IS NULL or extract(YEAR FROM rec_subs_flow.start_date_end) >
                                                               2020 then
                        end_date := '2020-12-31';
                    else
                        end_date := rec_subs_flow.start_date_end;
                    end if;

                    while start_date < end_date
                        loop

                            -- insert the new row in the payments table
                            str_query := 'insert into foodie_fi.payments ' ||
                                         'values (' ||
                                         rec_subs_flow.customer_id || ',' ||
                                         rec_subs_flow.plan_id_init || ',''' ||
                                         rec_subs_flow.plan_name_init || ''',''' ||
                                         start_date || ''',' ||
                                         price || ',' ||
                                         payment_order
                                || ')';

                            execute str_query;

                            -- if the current plan is annual, move to 1 year, otherwise move to the next month
                            if rec_subs_flow.plan_id_init = 3 then
                                start_date := start_date + INTERVAL '1 year';
                            else
                                start_date := start_date + INTERVAL '1 month';
                            end if;

                            payment_order := payment_order + 1;

                        end loop;

                end if;

            end loop;

            close cur_subs_flow;

        end loop;

        close cur_customers;

    end
$$;
```

Let's make a `SELECT` on the `payments` table:

```sql
SELECT * FROM foodie_fi.payments WHERE customer_id = 16;
```

|customer_id|plan_id|plan_name|payment_date|amount|payment_order|
|:----|:----|:----|:----|:----|:----|
|16|1|basic monthly|2020-06-07|9.9|1|
|16|1|basic monthly|2020-07-07|9.9|2|
|16|1|basic monthly|2020-08-07|9.9|3|
|16|1|basic monthly|2020-09-07|9.9|4|
|16|1|basic monthly|2020-10-07|9.9|5|
|16|3|pro annual|2020-10-21|189.1|6|