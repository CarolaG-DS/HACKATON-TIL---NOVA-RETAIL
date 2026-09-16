{{ config(
    materialized='table',
    schema='SILVER'
) }}

WITH raw_finance AS (

    SELECT *
    FROM {{ source('bronze', 'RAW_FINANCE_TARGETS') }}

),

unpivoted_targets AS (

    SELECT
        "Region" AS region,
        "Category" AS category,
        month_str,
        target_amount

    FROM raw_finance

    UNPIVOT (
        target_amount FOR month_str IN (
            "Jan-23",
            "Feb-23",
            "Mar-23",
            "Apr-23",
            "May-23",
            "Jun-23",
            "Jul-23",
            "Aug-23",
            "Sep-23",
            "Oct-23",
            "Nov-23",
            "Dec-23"
        )
    )

)

SELECT
    TRIM(region) AS region,
    TRIM(category) AS product_category,
    TO_DATE(month_str, 'MON-YY') AS target_month,
    CAST(target_amount AS NUMBER(12,2)) AS target_amount

FROM unpivoted_targets