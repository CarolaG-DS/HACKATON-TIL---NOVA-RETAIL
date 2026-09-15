SELECT
    month,
    product_category,
    revenue_eur,
    orders,
    aov_eur
FROM {{ ref('fct_monthly_performance') }}
WHERE ABS(
    aov_eur - (revenue_eur / NULLIF(orders, 0))
) > 0.01