{{ config(materialized='table', schema='GOLD') }}

WITH targets AS (
    SELECT * FROM {{ ref('stg_finance_targets') }}
),
sales AS (
    SELECT * FROM {{ ref('fct_sales') }}
)

SELECT
    t.target_month AS performance_month,
    t.product_category,
    t.region,
    SUM(COALESCE(s.net_revenue_eur, 0)) AS total_actual_revenue,
    SUM(t.target_amount) AS total_target_revenue,
    SUM(COALESCE(s.net_revenue_eur, 0)) - SUM(t.target_amount) AS variance_to_target,
    COUNT(DISTINCT s.order_id) AS total_orders

FROM targets t
LEFT JOIN sales s
    ON DATE_TRUNC('month', s.transaction_date) = t.target_month
   AND s.product_category = t.product_category
   AND s.region = t.region

GROUP BY 1, 2, 3