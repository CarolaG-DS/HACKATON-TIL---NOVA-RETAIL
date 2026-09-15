{{ config(materialized='table', schema='GOLD') }}

WITH sales AS (
    SELECT * FROM {{ ref('stg_sales_transactions') }}
),
targets AS (
    SELECT DISTINCT 
        product_category, 
        region 
    FROM {{ ref('stg_finance_targets') }}
)

SELECT
    s.order_id,
    s.transaction_date,
    MD5(LOWER(s.customer_email)) AS customer_id,
    s.product_id,
    s.product_category,
    COALESCE(t.region, 'Unknown') AS region,
    s.unit_price,
    s.quantity,
    s.is_return,
    s.discount_percentage,
    
    -- Calcolo metriche finanziarie
    (s.unit_price * s.quantity) AS gross_revenue,
    (s.unit_price * s.quantity * s.discount_percentage) AS discount_amount,
    CASE 
        WHEN s.is_return THEN 0
        ELSE (s.unit_price * s.quantity * (1 - s.discount_percentage))
    END AS net_revenue

FROM sales s
LEFT JOIN targets t 
    ON s.product_category = t.product_category