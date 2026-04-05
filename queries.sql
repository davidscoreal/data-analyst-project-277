-- Consulta 1: Número total de clientes
-- Cuenta todos los registros de la tabla customers
SELECT count(*) AS customers_count
FROM customers;

-- Consulta 2: Top 10 vendedores con más ingresos totales
-- Calcula la facturación total por vendedor y muestra los 10 mejores
SELECT
    concat(trim(e.first_name), ' ', trim(e.last_name)) AS seller,
    count(s.sales_id) AS operations,
    floor(sum(s.quantity * p.price)) AS income
FROM sales AS s
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY income DESC
LIMIT 10;

-- Consulta 3: Vendedores con ingreso promedio por debajo del promedio general
-- Identifica a los vendedores que necesitan apoyo comparando su promedio individual con el general
WITH seller_avg AS (
    SELECT
        e.employee_id,
        concat(trim(e.first_name), ' ', trim(e.last_name)) AS seller,
        floor(avg(s.quantity * p.price)) AS average_income
    FROM sales AS s
    INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p ON s.product_id = p.product_id
    GROUP BY e.employee_id, e.first_name, e.last_name
)

SELECT seller, average_income
FROM seller_avg
WHERE average_income < (SELECT avg(average_income) FROM seller_avg)
ORDER BY average_income;

-- Consulta 4: Ingresos por vendedor y día de la semana
-- Muestra cómo varían las ventas según el día para cada vendedor
SELECT
    concat(trim(e.first_name), ' ', trim(e.last_name)) AS seller,
    trim(lower(to_char(s.sale_date, 'day'))) AS day_of_week,
    floor(sum(s.quantity * p.price)) AS income
FROM sales AS s
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name,
    extract(DOW FROM s.sale_date),
    to_char(s.sale_date, 'day')
ORDER BY extract(DOW FROM s.sale_date), seller;

-- Consulta 5: Clientes por grupo de edad
-- Divide a los clientes en tres segmentos etarios
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    count(*) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category;

-- Consulta 6: Clientes únicos e ingresos por mes
-- Muestra la evolución mensual del negocio
SELECT
    to_char(s.sale_date, 'YYYY-MM') AS selling_month,
    count(DISTINCT s.customer_id) AS total_customers,
    floor(sum(s.quantity * p.price)) AS income
FROM sales AS s
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY selling_month
ORDER BY selling_month;

-- Consulta 7: Clientes cuya primera compra fue durante una promoción
-- Encuentra clientes que empezaron comprando productos gratuitos (precio = 0)
WITH first_purchases AS (
    SELECT
        s.customer_id,
        min(s.sale_date) AS first_date
    FROM sales AS s
    INNER JOIN products AS p ON s.product_id = p.product_id
    WHERE p.price = 0
    GROUP BY s.customer_id
)

SELECT
    concat(trim(c.first_name), ' ', trim(c.last_name)) AS customer,
    fp.first_date AS sale_date,
    concat(trim(e.first_name), ' ', trim(e.last_name)) AS seller
FROM first_purchases AS fp
INNER JOIN sales AS s
    ON s.customer_id = fp.customer_id AND s.sale_date = fp.first_date
INNER JOIN products AS p ON s.product_id = p.product_id AND p.price = 0
INNER JOIN customers AS c ON c.customer_id = fp.customer_id
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
ORDER BY fp.customer_id;
