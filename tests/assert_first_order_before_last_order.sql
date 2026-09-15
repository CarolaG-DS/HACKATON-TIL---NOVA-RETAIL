SELECT customer_id, first_order_date, most_recent_order_date
FROM {{ ref('dim_customers') }}
WHERE first_order_date > most_recent_order_date