
/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL Functions Used:
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
===============================================================================
*/

/* segment products into cost ranges and count how many products fall into each segment.*/

WITH cte_cost_segmentation AS
(
SELECT
	product_key,
	product_name,
	cost,
	CASE WHEN cost < 100 THEN 'Below 100'
		WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		ELSE 'Above 1000'
	END AS cost_range
FROM gold.dim_products
)

SELECT
	cost_range,
	COUNT(product_name) AS Total_number_of_product
FROM cte_cost_segmentation
GROUP BY cost_range
ORDER BY Total_number_of_product DESC;


/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/

WITH cte_customer_segmentation AS
(
SELECT
	c.customer_key,
	SUM(s.sales_amount) AS total_spending,
	MIN(s.order_date) AS first_order_date,
	MAX(s.order_date) AS last_order_date,
	DATEDIFF(MONTH, MIN(s.order_date), MAX(s.order_date)) AS lifespan
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON c.customer_key = s.customer_key
GROUP BY c.customer_key
)

SELECT
	customer_segment,
	COUNT(customer_key) AS customer_count 
FROM
(
SELECT
	CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
		WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'REGULAR'
		ELSE 'NEW'
	END AS customer_segment,
	customer_key
FROM cte_customer_segmentation
)t
GROUP BY customer_segment
ORDER BY customer_count DESC;
