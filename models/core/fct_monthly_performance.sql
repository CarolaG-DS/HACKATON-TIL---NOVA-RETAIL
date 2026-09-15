{{ config(materialized='table', schema='GOLD') }}

WITH actual_sales AS (
    SELECT
        DATE_TRUNC('month', transaction_date) AS sales_month,
        product_category,
        SUM(net_revenue) AS total_actual_revenue,
        COUNT(DISTINCT order_id) AS total_orders
    FROM {{ ref('fct_sales') }}
    WHERE transaction_date IS NOT NULL
    GROUP BY 1, 2
),

finance_targets AS (
    SELECT
        target_month,
        product_category,
        SUM(target_amount) AS total_target_revenue
    FROM {{ ref('stg_finance_targets') }}
    WHERE target_month IS NOT NULL
    GROUP BY 1, 2
)

SELECT
    COALESCE(s.sales_month, t.target_month) AS performance_month,
    COALESCE(s.product_category, t.product_category) AS product_category,
    COALESCE(s.total_actual_revenue, 0.00) AS total_actual_revenue,
    COALESCE(t.total_target_revenue, 0.00) AS total_target_revenue,
    (COALESCE(s.total_actual_revenue, 0.00) - COALESCE(t.total_target_revenue, 0.00)) AS variance_to_target,
    COALESCE(s.total_orders, 0) AS total_orders
FROM actual_sales s
FULL OUTER JOIN finance_targets t
    ON s.sales_month = t.target_month
   AND LOWER(s.product_category) = LOWER(t.product_category)
WHERE COALESCE(s.sales_month, t.target_month) IS NOT NULL