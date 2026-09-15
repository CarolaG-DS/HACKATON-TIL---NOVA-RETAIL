{{ config(materialized='view') }}

SELECT
    currency_code,
    exchange_rate_to_eur::NUMBER(10,4) AS exchange_rate_to_eur,
    effective_date::DATE AS effective_date
FROM {{ ref('raw_exchange_rates') }}