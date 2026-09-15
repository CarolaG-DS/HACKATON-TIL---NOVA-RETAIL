SELECT
    month,
    product_category,
    revenue_eur,
    profit_eur
FROM {{ ref('fct_monthly_performance') }}
WHERE ABS(profit_eur - (revenue_eur * 0.30)) > 0.01