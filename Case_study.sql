-- 1. Which product has the highest price? Only return a single row
SELECT * FROM products 
WHERE price =( SELECT MAX(price) FROM products);
----------------------------------------------------------------------------------------

-- 2. Which customer has made the most orders?
SELECT 
	c.customer_id, c.first_name, c.last_name, 
    count(o.order_id) as total_order
FROM customers c
JOIN orders o 
ON c.customer_id = o.customer_id
GROUP BY o.customer_id LIMIT 3;
-- Using CTE
WITH cte AS (
SELECT c.customer_id, c.first_name, c.last_name, 
	   count(o.order_id) as total_order
FROM customers c
JOIN orders o 
ON c.customer_id = o.customer_id
GROUP BY o.customer_id),
cte1 AS(
SELECT *, dense_rank() OVER (ORDER BY total_order DESC) AS rk FROM cte)
SELECT customer_id, first_name, last_name, total_order FROM cte1 WHERE rk = 1;
----------------------------------------------------------------------------------------

-- 3. What’s the total revenue per product?
WITH cte AS(
SELECT p.product_name, p.price,
		o.quantity FROM products p
JOIN order_items o ON p.product_id = o.product_id),
cte1 AS 
(SELECT *, (price*quantity) AS total FROM cte)
SELECT product_name, SUM(total) AS total_revenue FROM cte1
GROUP BY product_name ORDER BY total_revenue DESC;
----------------------------------------------------------------------------------------


-- 4. Find the day with the highest revenue.
WITH cte AS(
SELECT o.order_date, p.price, ot.quantity 
FROM products p 
JOIN order_items ot ON p.product_id = ot.product_id 
JOIN orders o ON ot.order_id = o.order_id),
cte1 AS ( SELECT *, (price*quantity) AS total FROM cte)
SELECT order_date, SUM(total) AS higest_revenue FROM cte1
GROUP BY order_date ORDER BY higest_revenue DESC LIMIT 1;
----------------------------------------------------------------------------------------


-- 5. Find the first order (by date) for each customer
SELECT customer_id, MIN(order_date) AS 1st_order FROM orders 
GROUP BY customer_id;
----------------------------------------------------------------------------------------


-- 6. Find the top 3 customers who have ordered the most distinct products
SELECT c.customer_id, c.first_name, c.last_name,
		COUNT(DISTINCT ot.product_id) AS unique_ord_product
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items ot ON ot.order_id = o.order_id
GROUP BY c.customer_id, c.first_name, c.last_name 
LIMIT 3;

-- Using CTE 
WITH cte AS
(SELECT c.customer_id, c.first_name, c.last_name, ot.product_id
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items ot ON ot.order_id = o.order_id) 
SELECT customer_id, first_name, last_name, COUNT(DISTINCT product_id) AS unique_ord_product
FROM cte 
GROUP BY c.customer_id,c.first_name, c.last_name
LIMIT 3;

-- Using DRANK
WITH cte AS
(SELECT c.customer_id, c.first_name, c.last_name, ot.product_id
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items ot ON ot.order_id = o.order_id),
cte1 AS (SELECT customer_id, first_name, last_name, COUNT(DISTINCT product_id) AS unique_ord_product
			FROM cte GROUP BY c.customer_id,c.first_name, c.last_name),
cte2 AS (SELECT *, dense_rank() OVER (ORDER BY unique_ord_product DESC) AS rk FROM cte1)
			SELECT customer_id, first_name, last_name, unique_ord_product FROM cte2 WHERE rk = 1;
----------------------------------------------------------------------------------------

            
-- 7. Which product has been bought the least in terms of quantity?
WITH cte AS
(SELECT p.product_id, p.product_name, ot.quantity
FROM products p 
JOIN order_items ot ON p.product_id = ot.product_id),
cte1 AS
(SELECT product_id, product_name, SUM(quantity) AS t_qty FROM cte
GROUP BY product_id, product_name ORDER BY t_qty ASC),
cte2 AS
(SELECT *, DENSE_RANK() OVER(ORDER BY t_qty) AS rk FROM cte1)
SELECT product_id, product_name, t_qty FROM cte2 WHERE rk = 1;
----------------------------------------------------------------------------------------


-- 8. What is the median order total?
WITH cte1 AS (
  SELECT o.order_date, o.customer_id, i.quantity, p.price
  FROM order_items i
  JOIN products p ON i.product_id = p.product_id
  JOIN orders o ON o.order_id = i.order_id),
cte2 AS (
  SELECT *, (quantity * price) AS total_revenue
  FROM cte1),
cte3 AS (
  SELECT customer_id, SUM(total_revenue) AS total_revenue
  FROM cte2
  GROUP BY customer_id)
SELECT AVG(total_revenue) AS median_order_total
FROM (
  SELECT total_revenue, ROW_NUMBER() OVER (ORDER BY total_revenue) AS row_num,
         COUNT(*) OVER () AS total_rows
  FROM cte3) AS subquery
WHERE row_num IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2));
----------------------------------------------------------------------------------------


-- 9. For each order, determine if it was ‘Expensive’ (total over 300), ‘Affordable’ (total over 100), or ‘Cheap’.
WITH cte AS (
	SELECT p.product_id,ot.order_id, p.price, ot.quantity FROM products p
	JOIN order_items ot ON p.product_id = ot.product_id	),
cte1 AS (
	SELECT *, (price*quantity) AS revenue FROM cte),
cte2 AS (
	SELECT order_id, SUM(revenue) AS t_revenue FROM cte1 
    GROUP BY order_id)

SELECT order_id, t_revenue,    
	CASE
	WHEN t_revenue>300 THEN "Expensive"
	WHEN t_revenue>100 THEN "Affordable"
	ELSE "Cheap" 
	END AS order_rateing
FROM cte2;
----------------------------------------------------------------------------------------


-- 10. Find customers who have ordered the product with the highest price.
WITH cte AS (
	SELECT o.customer_id, CONCAT(c.first_name, " ", c.last_name) AS customer_name,
			p.product_name, p.price
	FROM products p 
	JOIN order_items ot ON p.product_id = ot.product_id
	JOIN orders o ON o.order_id = ot.order_id
	JOIN customers c ON o.customer_id = c.customer_id)
SELECT customer_name, product_name, price FROM cte
WHERE price = (SELECT MAX(price) FROM cte);
