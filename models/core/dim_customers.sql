{{ config(materialized='table', schema='GOLD') }}

WITH sales AS (
    SELECT * FROM {{ ref('stg_sales_transactions') }}
),
reviews AS (
    SELECT 
        LOWER(TRIM(customer_email)) AS customer_email,
        MAX(country) AS country
    FROM {{ ref('stg_web_reviews') }}
    WHERE customer_email IS NOT NULL AND TRIM(customer_email) != ''
    GROUP BY 1
)

SELECT
    MD5(LOWER(TRIM(s.customer_email))) AS customer_id,
    s.customer_name,
    LOWER(TRIM(s.customer_email)) AS customer_email,
    s.customer_phone,

    r.country,

    MIN(s.transaction_date) AS first_order_date,
    MAX(s.transaction_date) AS most_recent_order_date,
    COUNT(DISTINCT s.order_id) AS total_orders

FROM sales s
LEFT JOIN reviews r
    ON LOWER(TRIM(s.customer_email)) = r.customer_email

WHERE s.customer_email IS NOT NULL AND TRIM(s.customer_email) != ''
GROUP BY 1, 2, 3, 4, 5