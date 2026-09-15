SELECT order_id, discount_percentage
FROM {{ ref('fct_sales') }}
WHERE discount_percentage < 0 OR discount_percentage > 1.0