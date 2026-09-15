{{ config(
    materialized='table',
    schema='GOLD'
) }}

WITH sales AS (

    SELECT
        order_id,
        transaction_date,
        product_category,
        revenue_eur,
        net_revenue
    FROM {{ ref('fct_sales') }}

),

monthly AS (

    SELECT
        DATE_TRUNC('MONTH', transaction_date) AS month,
        product_category,

        COUNT(DISTINCT order_id) AS orders,

        ROUND(SUM(revenue_eur), 2) AS revenue_eur,

        ROUND(SUM(revenue_eur) * 0.30, 2) AS profit_eur,

        ROUND(
            SUM(revenue_eur) / NULLIF(COUNT(DISTINCT order_id), 0),
            2
        ) AS aov_eur

    FROM sales

    WHERE transaction_date IS NOT NULL
      AND revenue_eur IS NOT NULL

    GROUP BY
        DATE_TRUNC('MONTH', transaction_date),
        product_category

)

SELECT *
FROM monthly
ORDER BY month, product_category