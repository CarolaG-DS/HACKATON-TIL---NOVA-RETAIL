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
        region,
        SUM(target_amount) AS total_target_revenue
    FROM {{ ref('stg_finance_targets') }}
    WHERE target_month IS NOT NULL
    GROUP BY 1, 2, 3
)

SELECT
    COALESCE(s.sales_month, t.target_month) AS performance_month,
    COALESCE(s.product_category, t.product_category) AS product_category,
    t.region,
    
    -- Le vendite reali vengono spalmate/associate alla categoria e al mese del target
    CAST(COALESCE(s.total_actual_revenue, 0.00) AS NUMBER(10,2)) AS actual_revenue,
    CAST(COALESCE(t.total_target_revenue, 0.00) AS NUMBER(10,2)) AS target_revenue,
    
    CAST(
        (COALESCE(s.total_actual_revenue, 0.00) - COALESCE(t.total_target_revenue, 0.00))
        AS NUMBER(10,2)
    ) AS variance_to_target,
    
    COALESCE(s.total_orders, 0) AS total_orders

FROM finance_targets t
LEFT JOIN actual_sales s
    ON t.target_month = s.sales_month
   AND LOWER(TRIM(t.product_category)) = LOWER(TRIM(s.product_category))