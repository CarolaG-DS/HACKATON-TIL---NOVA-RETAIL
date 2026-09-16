{{ config(
    materialized='table',
    schema='GOLD'
) }}

SELECT
    target_month AS month,
    region,
    product_category,
    target_amount

FROM {{ ref('stg_finance_targets') }}