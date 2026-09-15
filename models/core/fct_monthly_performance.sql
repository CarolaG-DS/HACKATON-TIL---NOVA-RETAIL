{{ config(materialized='table', schema='GOLD') }}

WITH actual_sales AS (
    SELECT
        DATE_TRUNC('month', transaction_date) AS performance_month,
        product_category,
        region,
        CAST(SUM(net_revenue) AS NUMBER(10,2)) AS actual_revenue,
        COUNT(DISTINCT order_id) AS total_orders
    FROM {{ ref('fct_sales') }}
    WHERE transaction_date IS NOT NULL
    GROUP BY 1, 2, 3
),

finance_targets AS (
    SELECT
        target_month AS performance_month,
        product_category,
        region,
        CAST(SUM(target_amount) AS NUMBER(10,2)) AS target_revenue
    FROM {{ ref('stg_finance_targets') }}
    WHERE target_month IS NOT NULL
    GROUP BY 1, 2, 3
)

SELECT
    COALESCE(s.performance_month, t.performance_month) AS performance_month,
    COALESCE(s.product_category, t.product_category) AS product_category,
    COALESCE(s.region, t.region) AS region,

    -- Metriche Monetarie in EUR (2 decimali)
    CAST(COALESCE(s.actual_revenue, 0.00) AS NUMBER(10,2)) AS actual_revenue,
    CAST(COALESCE(t.target_revenue, 0.00) AS NUMBER(10,2)) AS target_revenue,

    -- Scostamento in EUR (2 decimali)
    CAST(
        (COALESCE(s.actual_revenue, 0.00) - COALESCE(t.target_revenue, 0.00))
        AS NUMBER(10,2)
    ) AS variance_to_target,

    -- Percentuale di raggiungimento Target
    CAST(
        CASE 
            WHEN COALESCE(t.target_revenue, 0.00) = 0 THEN NULL
            ELSE (COALESCE(s.actual_revenue, 0.00) / t.target_revenue)
        END AS NUMBER(5,4)
    ) AS target_achievement_pct,

    COALESCE(s.total_orders, 0) AS total_orders

FROM actual_sales s
FULL OUTER JOIN finance_targets t
    ON s.performance_month = t.performance_month
   AND LOWER(TRIM(s.product_category)) = LOWER(TRIM(t.product_category))
   AND UPPER(TRIM(s.region)) = UPPER(TRIM(t.region))

WHERE COALESCE(s.performance_month, t.performance_month) IS NOT NULL