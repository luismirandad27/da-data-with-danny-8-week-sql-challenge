# SQL Challenge #3: Foodie Fi

<img src="https://8weeksqlchallenge.com/images/case-study-designs/3.png"
     alt="Markdown Monster icon" style="height:400px;width:400px;border-radius:5px;"/>

## Solution - Part D - Outside The Box Questions

The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!

### 1. How would you calculate the rate of growth for Foodie-Fi?

This is the basic formula:
```
Growth rate = [(Present Value - Past Value) / Past Value] X 100
```

The present value and past value could be the revenue (average or total) of users.

### 2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

`Churn rate`: 
Know how many unsubscription has been done in a month.

`Average Customer Satisfaction`: 
By using a satisfaction's survey, we can collect the score every customer could make. Then let's calculate the average by the number of users.

`Customer LifeTime Value (CLV)`:

This one looks interesting and how can we calculate this?

```
CLV = ARPU * CL
```
where:
```
ARPU (Average Revenue per User) = total revenue / total users
```
and
```
CL (Customer Lifespan) = Total number of months of subscriptions / total users
```

A higher CLV means a higher loyalty and a less churn rate.

`Upgrade rate`:

### 3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?

- **Journey 1**: users that access the app by different marketing channel (email ads, google ads, youtube ads, etc.)
- **Journey 2**: users adquiring a new account (supposing that there is a shopping cart)
- **Journey 3**: Users unsusbscribing

### 4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

1. What was the primary reason for canceling your Foodie-Fi subscription?
2. How satisfied were you with the Foodie-Fi service during your subscription period?
3. Did you encounter any issues or problems while using Foodie-Fi? If yes, please describe.
4. Did you feel that the pricing of Foodie-Fi was fair and reasonable for the service provided?
5. Would you consider re-subscribing to Foodie-Fi in the future? If no, please explain why.
6. Is there anything that Foodie-Fi could have done differently to improve your experience with the service?

### 5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

1. **Personalization** by giving each user what they would like to see. For example, by using some fancy algorithm like the "Collaborative Filtering Algorithm" to get the best recommendations by user. It's important that every user can rate the cooking shows.

2. **Offering users discounts** to extend the current subscriptions. We can validate this by getting the number of upgrades/extensions that comes from a discount.