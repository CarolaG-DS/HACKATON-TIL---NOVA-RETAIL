SELECT *
FROM {{ ref('fct_sales') }}
WHERE discount_percentage < 0
   OR discount_percentage > 1