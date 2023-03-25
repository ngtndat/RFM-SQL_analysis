#RECENCY
WITH rfm AS(
SELECT recency, COUNT(*) cnt
FROM
	(SELECT 
		customer_key,
		ABS(DATEDIFF(MAX(order_date), '2018-01-01')) recency
	FROM sales_2017
	GROUP BY customer_key) h
GROUP BY recency
ORDER BY recency
)

SELECT *,
	SUM(cnt)OVER(ORDER BY recency) running_ttl,
	SUM(cnt)OVER() cnt_ttl,
	CONCAT(SUM(cnt)OVER(ORDER BY recency)*100/SUM(cnt)OVER(),'%')perc,
	FLOOR((SUM(cnt)OVER(ORDER BY recency))*1.0/((SUM(cnt)OVER())+1)*5+1)quintiles															#giá trị nguyên gần 0 nhất: floor[running_ttl/(ttl+1)*5 + 1]
FROM rfm
ORDER BY recency;

#FREQUENCY
WITH rfm2 AS (
SELECT frequency, COUNT(*) ttl_order
FROM	
    (SELECT 
		customer_key, 
		ROUND(ABS(DATEDIFF(min(order_date),'2018-01-01'))/COUNT(*),0) frequency
	FROM sales_2017
	GROUP BY customer_key) h
GROUP BY frequency
ORDER BY frequency
)
SELECT *,
    SUM(ttl_order) OVER(ORDER BY frequency) running_ttl_f,
    SUM(ttl_order) OVER() order_ttl,
    CONCAT(SUM(ttl_order)OVER(ORDER BY frequency)*100/ SUM(ttl_order)OVER(),'%') perc,
    FLOOR((SUM(ttl_order)OVER(ORDER BY frequency))*1.0/ ((SUM(ttl_order)OVER())+1)*5+1) quintiles											#giá trị nguyên gần 0 nhất: floor[running_ttl/(ttl+1)*5 + 1]
FROM rfm2
GROUP BY frequency;

#MONETARY
SELECT 	customer_key,
		SUM(order_qty) ttl_order,
        ROUND(SUM(order_qty*product_price),2) ttl_amt,
        ROUND(SUM(order_qty*product_price)/SUM(order_qty),2) avg_amt,
        rank()OVER(ORDER BY ROUND(SUM(order_qty*product_price)/SUM(order_qty),2) DESC) rmk,
        COUNT(*)OVER() order_ttl,
        FLOOR((RANK()OVER(ORDER BY ROUND(SUM(order_qty*product_price)/SUM(order_qty),2) DESC))/COUNT(*)OVER()*5)+1 AS monetary 				#giá trị nguyên gần 0 nhất: floor[rmk/order_ttl*5] + 1
FROM sales_2017
LEFT JOIN products
ON sales_2017.product_key = products.product_key
GROUP BY customer_key