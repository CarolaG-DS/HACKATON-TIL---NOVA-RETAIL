{{ config(materialized='table', schema='GOLD') }}

WITH sales AS (

    SELECT *
    FROM {{ ref('stg_sales_transactions') }}

),

latest_reviews AS (

    SELECT
        LOWER(TRIM(reviewer_email)) AS customer_email,
        reviewer_country_code AS country,
        reviewer_city AS city,
        ROW_NUMBER() OVER (
            PARTITION BY LOWER(TRIM(reviewer_email))
            ORDER BY review_created_at DESC
        ) AS rn
    FROM {{ ref('stg_web_reviews') }}
    WHERE reviewer_email IS NOT NULL
      AND TRIM(reviewer_email) != ''

),

customer_profile AS (

    SELECT
        MD5(LOWER(TRIM(s.customer_email))) AS customer_id,
        s.customer_name,
        LOWER(TRIM(s.customer_email)) AS customer_email,
        s.customer_phone,
        r.country,
        r.city,
        MIN(s.transaction_date) AS first_order_date,
        MAX(s.transaction_date) AS most_recent_order_date,
        COUNT(DISTINCT s.order_id) AS total_orders

    FROM sales s

    LEFT JOIN latest_reviews r
        ON LOWER(TRIM(s.customer_email)) = r.customer_email
       AND r.rn = 1

    WHERE s.customer_email IS NOT NULL
      AND TRIM(s.customer_email) != ''

    GROUP BY
        MD5(LOWER(TRIM(s.customer_email))),
        s.customer_name,
        LOWER(TRIM(s.customer_email)),
        s.customer_phone,
        r.country,
        r.city

)

SELECT *
FROM customer_profile