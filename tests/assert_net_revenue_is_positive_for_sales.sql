SELECT *
FROM {{ ref('fct_sales') }}
WHERE
    (is_return = FALSE AND net_revenue < 0)
    OR
    (is_return = TRUE AND net_revenue > 0)