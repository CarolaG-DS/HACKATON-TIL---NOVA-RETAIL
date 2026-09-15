-- Verifica che il net revenue (sia locale che EUR) sia sempre >= 0
SELECT
    order_id,
    net_revenue_local,
    net_revenue_eur
FROM {{ ref('fct_sales') }}
WHERE net_revenue_local < 0 
   OR net_revenue_eur < 0