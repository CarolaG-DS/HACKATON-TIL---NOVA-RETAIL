{{ config(materialized='table', schema='GOLD') }}

WITH sales AS (
    SELECT * FROM {{ ref('stg_sales_transactions') }}
)

SELECT
    order_id,
    transaction_date,
    MD5(LOWER(customer_email)) AS customer_id,
    product_id,
    product_category,
    unit_price,
    quantity,
    is_return,
    discount_percentage,
    
    -- Calcolo metriche finanziarie
    (unit_price * quantity) AS gross_revenue,
    (unit_price * quantity * discount_percentage) AS discount_amount,
    CASE 
        WHEN is_return THEN 0
        ELSE (unit_price * quantity * (1 - discount_percentage))
    END AS net_revenue

FROM sales