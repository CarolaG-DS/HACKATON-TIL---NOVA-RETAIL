WITH expected AS (

    SELECT
        DATE_TRUNC('MONTH', transaction_date) AS month,
        product_category,
        ROUND(SUM(revenue_eur), 2) AS expected_revenue_eur
    FROM {{ ref('fct_sales') }}
    WHERE transaction_date IS NOT NULL
      AND revenue_eur IS NOT NULL
    GROUP BY
        DATE_TRUNC('MONTH', transaction_date),
        product_category

),

actual AS (

    SELECT
        month,
        product_category,
        ROUND(SUM(revenue_eur), 2) AS actual_revenue_eur
    FROM {{ ref('fct_monthly_performance') }}
    GROUP BY
        month,
        product_category

)

SELECT
    e.month,
    e.product_category,
    e.expected_revenue_eur,
    a.actual_revenue_eur
FROM expected e
LEFT JOIN actual a
    ON e.month = a.month
   AND e.product_category = a.product_category
WHERE a.month IS NULL
   OR ABS(e.expected_revenue_eur - a.actual_revenue_eur) > 0.01