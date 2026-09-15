{{ config(materialized='table', schema='GOLD') }}

WITH sales AS (
    SELECT * FROM {{ ref('stg_sales_transactions') }}
),
fx AS (
    -- Lettura diretta dalla vista nello schema SILVER
    SELECT * FROM SILVER.STG_EXCHANGE_RATES
),
sales_converted AS (
    SELECT
        s.order_id,
        s.transaction_date,
        MD5(LOWER(TRIM(s.customer_email))) AS customer_id,
        s.customer_name,
        s.customer_email,
        s.customer_phone,
        s.product_id,
        s.product_category,
        s.quantity,
        s.is_return,
        CAST(s.discount_percentage AS NUMBER(5,2)) AS discount_percentage,
        
        CAST(
            s.unit_price / COALESCE(fx.exchange_rate_to_eur, 1.0000) 
            AS NUMBER(10,2)
        ) AS unit_price
    FROM sales s
    LEFT JOIN fx 
        ON UPPER(TRIM(s.currency_code)) = UPPER(TRIM(fx.currency_code))
    WHERE s.transaction_date IS NOT NULL
)

SELECT
    order_id,
    transaction_date,
    customer_id,
    customer_name,
    customer_email,
    customer_phone,
    product_id,
    product_category,
    unit_price,
    quantity,
    is_return,
    discount_percentage,

    CAST((unit_price * quantity) AS NUMBER(10,2)) AS gross_revenue,
    CAST((unit_price * quantity * discount_percentage) AS NUMBER(10,2)) AS discount_amount,
    CAST((unit_price * quantity * (1.00 - discount_percentage)) AS NUMBER(10,2)) AS net_revenue

FROM sales_converted