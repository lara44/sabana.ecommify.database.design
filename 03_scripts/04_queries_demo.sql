-- =============================================================
-- Ecommify · Módulo Transaccional PostgreSQL
-- Archivo : 04_queries_demo.sql
-- Descripción: Queries demo — tipos avanzados, extensiones y OLAP
-- =============================================================

-- ─────────────────────────────────────────────────────────────
-- SECCIÓN 1: Consultas sobre TEXT[] (imágenes)
-- ─────────────────────────────────────────────────────────────

-- Q1: Listar la primera imagen (thumbnail) de cada producto
SELECT
    p.id,
    p.name,
    p.images[1] AS thumbnail_url
FROM products p
WHERE p.images IS NOT NULL
ORDER BY p.name;

-- Q2: Productos con más de 2 imágenes cargadas
SELECT
    p.name,
    array_length(p.images, 1) AS total_images
FROM products p
WHERE array_length(p.images, 1) > 2;

-- Q3: Productos que contengan una URL específica en su array
SELECT p.name
FROM products p
WHERE 'https://ecommify-assets.s3.amazonaws.com/products/e1000003/img2.jpg' = ANY(p.images);

-- Q4: Agregar una imagen nueva sin reemplazar las existentes
UPDATE products
SET images = array_append(images, 'https://ecommify-assets.s3.amazonaws.com/products/e1000001/img3.jpg')
WHERE id = 'e1000000-0000-0000-0000-000000000001';

-- ─────────────────────────────────────────────────────────────
-- SECCIÓN 2: Consultas sobre JSONB (product_details.attributes)
-- ─────────────────────────────────────────────────────────────

-- Q5: Productos electrónicos con 5G habilitado
SELECT
    p.name,
    pd.attributes->>'color'    AS color,
    pd.attributes->>'storage_gb' AS storage
FROM products        p
JOIN product_details pd ON pd.product_id = p.id
WHERE pd.attributes @> '{"5g": true}';

-- Q6: Filtrar por RAM >= 8 GB (cast numérico desde JSONB)
SELECT
    p.name,
    (pd.attributes->>'ram_gb')::int AS ram_gb
FROM products        p
JOIN product_details pd ON pd.product_id = p.id
WHERE (pd.attributes->>'ram_gb')::int >= 8
ORDER BY ram_gb DESC;

-- Q7: Listar todas las claves JSONB distintas en product_details
SELECT DISTINCT jsonb_object_keys(attributes) AS attribute_key
FROM product_details
ORDER BY 1;

-- Q8: Productos con tallas disponibles (campo "sizes" en JSONB)
SELECT
    p.name,
    pd.attributes->'sizes' AS available_sizes
FROM products        p
JOIN product_details pd ON pd.product_id = p.id
WHERE pd.attributes ? 'sizes';

-- ─────────────────────────────────────────────────────────────
-- SECCIÓN 3: Búsqueda fuzzy con pg_trgm
-- ─────────────────────────────────────────────────────────────

-- Q9: Búsqueda tolerante a errores tipográficos en nombre de producto
--     "smarthpone" → encuentra "Smartphone Galaxy A55"
SELECT
    p.name,
    similarity(p.name, 'smarthpone galaxy') AS score
FROM products p
WHERE p.name % 'smarthpone galaxy'   -- operador similarity
ORDER BY score DESC
LIMIT 5;

-- Q10: Búsqueda con LIKE fuzzy mejorado
SELECT p.name
FROM products p
WHERE p.name ILIKE '%galaxy%';

-- ─────────────────────────────────────────────────────────────
-- SECCIÓN 4: Consultas transaccionales OLTP
-- ─────────────────────────────────────────────────────────────

-- Q11: Pedidos de un cliente con su estado y total pagado
SELECT
    o.id                   AS order_id,
    o.order_status,
    o.purchase_timestamp,
    SUM(op.payment_value)  AS total_paid
FROM orders         o
JOIN order_payments op ON op.order_id = o.id
WHERE o.customer_id = 'b1000000-0000-0000-0000-000000000001'
GROUP BY o.id, o.order_status, o.purchase_timestamp
ORDER BY o.purchase_timestamp DESC;

-- Q12: Detalle completo de un pedido (items + seller + producto)
SELECT
    oi.item_sequence,
    p.name                 AS product_name,
    c.name                 AS category,
    s.name                 AS seller,
    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value AS subtotal
FROM order_items  oi
JOIN products     p  ON p.id = oi.product_id
JOIN categories   c  ON c.id = p.category_id
JOIN sellers      s  ON s.id = oi.seller_id
WHERE oi.order_id = 'f1000000-0000-0000-0000-000000000001'
ORDER BY oi.item_sequence;

-- Q13: Tiempo promedio de entrega por estado de origen del seller
SELECT
    g.state                                                  AS seller_state,
    AVG(
        EXTRACT(EPOCH FROM (o.delivered_customer_date - o.purchase_timestamp))
        / 86400
    )::NUMERIC(6,1)                                          AS avg_delivery_days
FROM orders   o
JOIN order_items oi ON oi.order_id  = o.id
JOIN sellers      s  ON s.id         = oi.seller_id
JOIN geolocations g  ON g.id         = s.geolocation_id
WHERE o.delivered_customer_date IS NOT NULL
GROUP BY g.state
ORDER BY avg_delivery_days;

-- ─────────────────────────────────────────────────────────────
-- SECCIÓN 5: Consultas analíticas OLAP (sobre MVs)
-- ─────────────────────────────────────────────────────────────

-- Q14: Top 5 categorías por ingresos en el último trimestre
SELECT
    category_name,
    SUM(total_revenue) AS revenue
FROM mv_sales_by_category_monthly
WHERE month >= DATE_TRUNC('quarter', now()) - INTERVAL '3 months'
GROUP BY category_name
ORDER BY revenue DESC
LIMIT 5;

-- Q15: Distribución de clientes por segmento
SELECT
    segment,
    COUNT(*)               AS total_customers,
    AVG(lifetime_value)    AS avg_ltv,
    AVG(order_count)       AS avg_orders
FROM mv_customer_segments
GROUP BY segment
ORDER BY avg_ltv DESC;

-- Q16: Score promedio de reviews por categoría
SELECT
    c.name            AS category,
    AVG(r.score)::NUMERIC(3,2) AS avg_score,
    COUNT(r.id)       AS total_reviews
FROM reviews      r
JOIN orders       o  ON o.id  = r.order_id
JOIN order_items  oi ON oi.order_id  = o.id
JOIN products     p  ON p.id  = oi.product_id
JOIN categories   c  ON c.id  = p.category_id
GROUP BY c.name
ORDER BY avg_score DESC;