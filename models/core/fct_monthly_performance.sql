{{ config(
    materialized='table',
    schema='GOLD'
) }}

WITH sales AS (

    SELECT
        order_id,
        transaction_date,
        product_category,
        customer_email,
        revenue_eur
    FROM {{ ref('fct_sales') }}

),

customers AS (

    SELECT
        customer_email,
        country
    FROM {{ ref('dim_customers') }}

),

region_mapping AS (

    SELECT
        country,
        region
    FROM {{ ref('dim_region_mapping') }}

),

sales_with_region AS (

    SELECT
        s.order_id,
        s.transaction_date,
        s.product_category,
        s.revenue_eur,
        rm.region
    FROM sales s

    LEFT JOIN customers c
        ON LOWER(TRIM(s.customer_email))
         = LOWER(TRIM(c.customer_email))

    LEFT JOIN region_mapping rm
        ON UPPER(TRIM(c.country))
         = rm.country

),

monthly AS (

    SELECT
        DATE_TRUNC('MONTH', transaction_date) AS month,
        region,
        product_category,

        COUNT(DISTINCT order_id) AS orders,

        ROUND(SUM(revenue_eur), 2) AS revenue_eur,

        ROUND(SUM(revenue_eur) * 0.30, 2) AS profit_eur,

        ROUND(
            SUM(revenue_eur)
            / NULLIF(COUNT(DISTINCT order_id), 0),
            2
        ) AS aov_eur

    FROM sales_with_region

    WHERE transaction_date IS NOT NULL
      AND revenue_eur IS NOT NULL

    GROUP BY
        DATE_TRUNC('MONTH', transaction_date),
        region,
        product_category

)

SELECT *
FROM monthly
ORDER BY
    month,
    region,
    product_category