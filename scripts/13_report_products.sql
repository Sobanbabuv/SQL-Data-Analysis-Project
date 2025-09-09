/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================

DROP VIEW IF EXISTS gold.report_products;

GO

CREATE VIEW gold.report_products AS

WITH base_query AS(

/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/

SELECT
	s.order_number,
	s.order_date,
	s.customer_key,
	s.sales_amount,
	s.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_products AS p
ON p.product_key = s.product_key
WHERE order_date IS NOT NULL
)

, product_aggregations AS (
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/

SELECT
	product_key,
	category,
	subcategory,
	product_name,
	cost,
	SUM(quantity) AS total_quantity,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
	MAX(order_date) AS last_sale_date,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS average_selling_price
FROM base_query
GROUP BY
	product_key,
	category,
	subcategory,
	product_name,
	cost
)


/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/

SELECT
	product_name,
	category,
	subcategory,
	cost,
	CASE WHEN total_sales > 50000 THEN 'High-Performers'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performers'
	END AS revenue_product_segment,
	lifespan,
	DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	average_selling_price,
	-- AVERAGE ORDER REVENUE
	CASE WHEN total_orders = 0 THEN 0
		ELSE (total_sales / total_orders) 
	END AS average_order_revenue,
	-- AVERAGE MONTHLY REVENUE
	CASE WHEN lifespan = 0 THEN total_sales
		ELSE (total_sales / lifespan)
	END AS average_monthly_revenue
FROM product_aggregations;
