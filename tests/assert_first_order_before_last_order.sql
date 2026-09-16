SELECT *
FROM {{ ref('dim_customers') }}
WHERE first_order_date > most_recent_order_date