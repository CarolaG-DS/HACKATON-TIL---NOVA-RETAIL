{{ config(materialized='view', schema='SILVER') }}

WITH raw_fx AS (
    SELECT * FROM {{ source('bronze', 'RAW_EXCHANGE_RATES') }}
)

SELECT
    UPPER(TRIM("CURRENCY_CODE")) AS currency_code,
    CAST("EXCHANGE_RATE_TO_EUR" AS NUMBER(10,4)) AS exchange_rate_to_eur,
    CAST("EFFECTIVE_DATE" AS DATE) AS effective_date
FROM raw_fx