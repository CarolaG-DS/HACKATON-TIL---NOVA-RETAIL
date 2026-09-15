{{ config(materialized='table', schema='GOLD') }}

WITH sales AS (
    SELECT 
        product_id,
        product_category
    FROM {{ ref('stg_sales_transactions') }}
    GROUP BY 1, 2
),

reviews AS (
    SELECT
        product_id,
        AVG(review_rating) AS avg_rating,
        COUNT(review_id) AS total_reviews
    FROM {{ ref('stg_web_reviews') }}
    GROUP BY 1
)

SELECT
    s.product_id,
    s.product_category,
    COALESCE(ROUND(r.avg_rating, 2), 0.00) AS avg_rating,
    COALESCE(r.total_reviews, 0) AS total_reviews
FROM sales s
LEFT JOIN reviews r 
    ON s.product_id = r.product_id