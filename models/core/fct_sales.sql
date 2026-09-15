{{ config(materialized='table', schema='GOLD') }}

WITH sales AS (

    SELECT *
    FROM {{ ref('stg_sales_transactions') }}

),

exchange_rates AS (

    SELECT
        currency_code,
        exchange_rate_to_eur
    FROM {{ source('bronze', 'RAW_EXCHANGE_RATES') }}

),

sales_calculated AS (

    SELECT
        s.order_id,
        s.transaction_date,

        -- Customer
        MD5(LOWER(TRIM(s.customer_email))) AS customer_id,
        LOWER(TRIM(s.customer_email)) AS customer_email,

        -- Product
        s.product_id,
        s.product_category,

        -- Transaction
        s.currency_code,
        s.unit_price,
        s.quantity,
        s.is_return,
        s.discount_percentage,

        -- Revenue
        s.unit_price * s.quantity AS gross_revenue,

        (s.unit_price * s.quantity * s.discount_percentage)
            AS discount_amount,

        CASE
            WHEN s.is_return THEN
                -1 * (
                    s.unit_price
                    * s.quantity
                    * (1 - s.discount_percentage)
                )
            ELSE
                s.unit_price
                * s.quantity
                * (1 - s.discount_percentage)
        END AS net_revenue

    FROM sales s

)

SELECT
    sc.*,
    er.exchange_rate_to_eur,

    sc.net_revenue * er.exchange_rate_to_eur AS revenue_eur

FROM sales_calculated sc

LEFT JOIN exchange_rates er
    ON sc.currency_code = er.currency_code