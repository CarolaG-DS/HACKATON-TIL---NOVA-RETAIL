{{ config(materialized='table', schema='GOLD') }}

WITH sales AS (
    SELECT * FROM {{ ref('stg_sales_transactions') }}
)

SELECT
    -- Generazione chiave surrogata o uso dell'email come identificativo unico
    MD5(LOWER(customer_email)) AS customer_id,
    customer_name,
    customer_email,
    customer_phone,
    MIN(transaction_date) AS first_order_date,
    MAX(transaction_date) AS most_recent_order_date,
    COUNT(DISTINCT order_id) AS total_orders
FROM sales
WHERE customer_email IS NOT NULL AND customer_email != ''
GROUP BY 1, 2, 3, 4