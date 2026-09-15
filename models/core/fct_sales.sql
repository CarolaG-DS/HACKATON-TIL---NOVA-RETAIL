{{ config(
    materialized='table',
    schema='GOLD'
) }}

WITH sales AS (

    SELECT
        order_id,
        transaction_date,
        customer_email,
        product_id,
        product_category,
        currency_code,
        unit_price,
        quantity,
        is_return,
        discount_percentage
    FROM {{ ref('stg_sales_transactions') }}

),

exchange_rates AS (

    SELECT
        currency_code,
        exchange_rate_to_eur,
        effective_date
    FROM {{ source('bronze', 'RAW_EXCHANGE_RATES') }}

),

sales_calculated AS (

    SELECT
        s.order_id,

        -- Foreign keys / dimensions
        MD5(LOWER(TRIM(s.customer_email))) AS customer_id,
        s.product_id,

        -- Transaction attributes
        s.transaction_date,
        s.product_category,
        s.currency_code,

        -- Measures
        s.unit_price,
        s.quantity,
        s.discount_percentage,
        s.is_return,

        -- Gross revenue before discount
        s.unit_price * s.quantity AS gross_revenue,

        -- Discount amount
        (s.unit_price * s.quantity)
            * s.discount_percentage AS discount_amount,

        -- Net revenue in original currency
        CASE
            WHEN s.is_return THEN
                -1 * (
                    (s.unit_price * s.quantity)
                    * (1 - s.discount_percentage)
                )
            ELSE
                (s.unit_price * s.quantity)
                * (1 - s.discount_percentage)
        END AS net_revenue

    FROM sales s

),

final AS (

    SELECT
        sc.*,

        er.exchange_rate_to_eur,

        -- Net revenue converted to EUR
        sc.net_revenue * er.exchange_rate_to_eur AS revenue_eur

    FROM sales_calculated sc

    LEFT JOIN exchange_rates er
        ON sc.currency_code = er.currency_code

)

SELECT *
FROM final