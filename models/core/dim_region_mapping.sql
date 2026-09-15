{{ config(materialized='table', schema='GOLD') }}

SELECT column1 AS country, column2 AS region
FROM VALUES
    ('US', 'NA'),
    ('AU', 'APAC'),
    ('JP', 'APAC'),
    ('DE', 'EMEA'),
    ('ES', 'EMEA'),
    ('FR', 'EMEA'),
    ('IT', 'EMEA'),
    ('UK', 'EMEA'),
    ('BR', 'LATAM'),
    ('MX', 'LATAM')