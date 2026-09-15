{{ config(materialized='table', schema='SILVER') }}

WITH raw_reviews AS (
    SELECT * FROM {{ source('bronze', 'RAW_WEB_REVIEWS') }}
)

SELECT
    -- Uso dei doppi apici per gestire i nomi in minuscolo su Snowflake
    CAST("review_id" AS VARCHAR) AS review_id,
    CAST("product_ref" AS VARCHAR) AS product_id,
    
    -- Conversione Timestamp da Epoch ms a TIMESTAMP_NTZ
    TO_TIMESTAMP_NTZ(CAST("timestamp" AS BIGINT) / 1000) AS review_created_at,
    
    -- Validazione Rating (solo valori 1-5, altrimenti NULL)
    CASE 
        WHEN CAST("rating" AS INT) BETWEEN 1 AND 5 THEN CAST("rating" AS INT)
        ELSE NULL 
    END AS review_rating,
    
    -- Pulizia testo
    TRIM("review_text") AS review_text,
    
    -- Oggetto annidato user (estratto su KNIME)
    CAST("name" AS VARCHAR) AS reviewer_name,
    CAST("email" AS VARCHAR) AS reviewer_email,
    UPPER(TRIM("country")) AS reviewer_country_code,
    TRIM("city") AS reviewer_city

FROM raw_reviews