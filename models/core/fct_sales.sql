{{ config(materialized='table', schema='GOLD') }}

WITH sales AS (
    SELECT * FROM {{ ref('stg_sales_transactions') }}
),
targets AS (
    SELECT DISTINCT product_category, region 
    FROM {{ ref('stg_finance_targets') }}
),
fx AS (
    SELECT * FROM {{ ref('stg_exchange_rates') }}
)

SELECT
    s.order_id,
    s.transaction_date,
    MD5(LOWER(s.customer_email)) AS customer_id,
    s.product_id,
    s.product_category,
    COALESCE(t.region, 'Unknown') AS region,
    
    -- Mapping Valuta Locale sulle Region effettive
    CASE 
        WHEN t.region = 'EMEA'  THEN 'EUR'
        WHEN t.region = 'NA'    THEN 'USD'
        WHEN t.region = 'APAC'  THEN 'USD'
        WHEN t.region = 'LATAM' THEN 'USD'
        ELSE 'EUR'
    END AS local_currency_code,
    
    s.unit_price,
    s.quantity,
    s.is_return,
    s.discount_percentage,
    
    -- Ricavo Netto Valuta Locale
    CASE 
        WHEN s.is_return THEN 0
        ELSE (s.unit_price * s.quantity * (1 - s.discount_percentage))
    END AS net_revenue_local,

    -- Ricavo Netto Uniformato in EUR (per vista globale "ALL")
    CASE 
        WHEN s.is_return THEN 0
        ELSE (s.unit_price * s.quantity * (1 - s.discount_percentage)) / COALESCE(fx.exchange_rate_to_eur, 1.0)
    END AS net_revenue_eur

FROM sales s
LEFT JOIN targets t 
    ON s.product_category = t.product_category
LEFT JOIN fx 
    ON fx.currency_code = CASE 
        WHEN t.region = 'EMEA'  THEN 'EUR'
        WHEN t.region = 'NA'    THEN 'USD'
        WHEN t.region = 'APAC'  THEN 'USD'
        WHEN t.region = 'LATAM' THEN 'USD'
        ELSE 'EUR'
    END