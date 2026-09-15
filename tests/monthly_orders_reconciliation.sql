WITH expected AS (

    SELECT
        DATE_TRUNC('MONTH', transaction_date) AS month,
        product_category,
        COUNT(DISTINCT order_id) AS expected_orders
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
        SUM(orders) AS actual_orders
    FROM {{ ref('fct_monthly_performance') }}
    GROUP BY
        month,
        product_category

)

SELECT
    e.month,
    e.product_category,
    e.expected_orders,
    a.actual_orders
FROM expected e
LEFT JOIN actual a
    ON e.month = a.month
   AND e.product_category = a.product_category
WHERE a.month IS NULL
   OR e.expected_orders <> a.actual_orders