-- Query 1: Total revenue per category per month
SELECT
    d.year,
    d.month_name,
    p.category,
    SUM(f.total_revenue) AS monthly_revenue
FROM
    fact_sales AS f
JOIN
    dim_product AS p ON f.product_key = p.product_key
JOIN
    dim_date AS d ON f.date_key = d.date_key
GROUP BY
    d.year,
    d.month_number,
    d.month_name,
    p.category
ORDER BY
    d.year,
    d.month_number,
    p.category;

-- Query 2: Top 5 brands by sales in the last 3 months
SELECT
    p.brand,
    SUM(f.total_revenue) AS recent_revenue
FROM
    fact_sales AS f
JOIN
    dim_product AS p ON f.product_key = p.product_key
WHERE
    f.date_key >= DATEADD('month', -3, (SELECT MAX(date_key) FROM fact_sales))
GROUP BY
    p.brand
ORDER BY
    recent_revenue DESC
LIMIT 5;

-- Query 3: YOY revenue growth by product category
WITH yearly_category_revenue AS (
    SELECT
        p.category,
        d.year,
        SUM(f.total_revenue) AS yearly_revenue
    FROM
        fact_sales AS f
    JOIN
        dim_product AS p ON f.product_key = p.product_key
    JOIN
        dim_date AS d ON f.date_key = d.date_key
    GROUP BY
        p.category,
        d.year
)
SELECT
    category,
    year,
    yearly_revenue,
    LAG(yearly_revenue, 1, 0) OVER (PARTITION BY category ORDER BY year) AS previous_year_revenue,
    (yearly_revenue - previous_year_revenue) / NULLIF(previous_year_revenue, 0) AS yoy_growth_rate
FROM
    yearly_category_revenue
ORDER BY
    category,
    year;

-- Query 4: Percentage of revenue contributed by top 10 products
WITH product_revenue_ranked AS (
    SELECT
        SUM(f.total_revenue) AS revenue,
        RANK() OVER (ORDER BY SUM(f.total_revenue) DESC) as product_rank
    FROM
        fact_sales AS f
    JOIN
        dim_product AS p ON f.product_key = p.product_key
    GROUP BY
        p.product_name
)

SELECT
    SUM(CASE WHEN product_rank <= 10 THEN revenue ELSE 0 END) /.
    SUM(revenue) * 100 AS percentage_contribution_from_top_10
FROM
    product_revenue_ranked;