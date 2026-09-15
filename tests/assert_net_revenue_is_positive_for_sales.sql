SELECT order_id, net_revenue
FROM {{ ref('fct_sales') }}
WHERE is_return = FALSE
  AND net_revenue < 0