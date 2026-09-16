SELECT
    month,
    region,
    product_category,
    COUNT(*) AS row_count

FROM {{ ref('fct_finance_targets') }}

GROUP BY
    month,
    region,
    product_category

HAVING COUNT(*) > 1