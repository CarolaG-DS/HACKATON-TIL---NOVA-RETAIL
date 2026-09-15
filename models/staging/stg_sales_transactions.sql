{{ config(materialized='table', schema='SILVER') }}

WITH raw_sales AS (
    SELECT * FROM {{ source('bronze', 'RAW_SALES_TRANSACTIONS') }}
),

cleaned_sales AS (
    SELECT
        CAST("order_id" AS VARCHAR) AS order_id,
        
        -- Parsing flessibile delle date
        CASE 
            WHEN LOWER(TRIM("transaction_date")) = 'today' THEN CURRENT_DATE()
            ELSE COALESCE(
                TRY_TO_DATE("transaction_date", 'YYYY-MM-DD'),
                TRY_TO_DATE("transaction_date", 'YYYY/MM/DD'),
                TRY_TO_DATE("transaction_date", 'DD/MM/YYYY'),
                TRY_TO_DATE("transaction_date", 'MM/DD/YYYY')
            )
        END AS transaction_date,

        -- Dettagli Cliente
        TRIM(SPLIT_PART("customer_info", '|', 1)) AS customer_name,
        TRIM(SPLIT_PART("customer_info", '|', 2)) AS customer_email,
        TRIM(SPLIT_PART("customer_info", '|', 3)) AS customer_phone,

        CAST("product_id" AS VARCHAR) AS product_id,
        TRIM("product_category") AS product_category,

        -- Colonna Valuta Esplicita
        CASE 
            WHEN "price" LIKE '%$%' THEN 'USD'
            WHEN "price" LIKE '%£%' THEN 'GBP'
            WHEN "price" LIKE '%€%' THEN 'EUR'
            ELSE 'EUR'
        END AS currency_code,

        -- Pulizia Prezzo
        CAST(
            REGEXP_REPLACE(REPLACE("price", ',', ''), '[$,€,£, ]', '') AS NUMBER(10,2)
        ) AS unit_price,

        -- Quantità e identificazione resi
        ABS(CAST("qty" AS INT)) AS quantity,
        CASE WHEN CAST("qty" AS INT) < 0 THEN TRUE ELSE FALSE END AS is_return,

        -- Normalizzazione sconto (Corretto: LIKE '% %' o '%')
        CAST(
            CASE 
                WHEN "discount_pct" ILIKE '%N/A%' OR "discount_pct" IS NULL THEN 0.00
                WHEN "discount_pct" LIKE '%\%' THEN CAST(REPLACE("discount_pct", '%', '') AS NUMBER(5,2)) / 100.0
                ELSE CAST("discount_pct" AS NUMBER(5,2))
            END AS NUMBER(5,2)
        ) AS discount_percentage

    FROM raw_sales
)

SELECT * 
FROM cleaned_sales
WHERE transaction_date IS NOT NULL