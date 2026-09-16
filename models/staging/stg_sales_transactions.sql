{{ config(
    materialized='table',
    schema='SILVER'
) }}

WITH raw_sales AS (

    SELECT *
    FROM {{ source('bronze', 'RAW_SALES_TRANSACTIONS') }}

)

SELECT

    CAST("order_id" AS VARCHAR) AS order_id,

    CASE 
        WHEN LOWER(TRIM("transaction_date")) = 'today'
            THEN NULL
        ELSE COALESCE(
            TRY_TO_DATE(TRIM("transaction_date"), 'YYYY-MM-DD'),
            TRY_TO_DATE(TRIM("transaction_date"), 'YYYY/MM/DD'),
            TRY_TO_DATE(TRIM("transaction_date"), 'DD/MM/YYYY'),
            TRY_TO_DATE(TRIM("transaction_date"), 'MM/DD/YYYY'),
            TRY_TO_DATE(TRIM("transaction_date"), 'DD-MON-YYYY')
        )
    END AS transaction_date,

    TRIM(SPLIT_PART("customer_info", '|', 1)) AS customer_name,
    TRIM(SPLIT_PART("customer_info", '|', 2)) AS customer_email,
    TRIM(SPLIT_PART("customer_info", '|', 3)) AS customer_phone,

    CAST("product_id" AS VARCHAR) AS product_id,

    TRIM("product_category") AS product_category,

    CASE 
        WHEN TRIM("price") LIKE '%$%' THEN 'USD'
        WHEN TRIM("price") LIKE '%€%' THEN 'EUR'
        WHEN TRIM("price") LIKE '%£%' THEN 'GBP'
        ELSE NULL
    END AS currency_code,

    TRY_TO_DECIMAL(
        REPLACE(
            REGEXP_REPLACE(TRIM("price"), '[$€£]', ''),
            ',',
            ''
        ),
        10,
        2
    ) AS unit_price,

    ABS(TRY_TO_NUMBER("qty")) AS quantity,

    CASE 
        WHEN TRY_TO_NUMBER("qty") < 0 THEN TRUE
        ELSE FALSE
    END AS is_return,

    CASE
        WHEN "discount_pct" IS NULL
            THEN 0.00

        WHEN UPPER(TRIM("discount_pct"::VARCHAR)) IN ('', 'N/A', 'NULL')
            THEN 0.00

        WHEN REGEXP_LIKE(
            TRIM("discount_pct"::VARCHAR),
            '^[0-9]+(\.[0-9]+)?%$'
        )
            THEN TRY_TO_DECIMAL(
                REPLACE(TRIM("discount_pct"::VARCHAR), '%', ''),
                5,
                2
            ) / 100.0

        ELSE
            COALESCE(
                TRY_TO_DECIMAL(
                    TRIM("discount_pct"::VARCHAR),
                    5,
                    4
                ),
                0.00
            )
    END AS discount_percentage

FROM raw_sales