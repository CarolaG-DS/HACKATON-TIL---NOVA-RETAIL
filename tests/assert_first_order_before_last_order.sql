SELECT *
FROM {{ ref('dim_customer') }}
WHERE first_order_date > most_recent_order_date