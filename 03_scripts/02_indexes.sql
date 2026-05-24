-- =============================================================
-- Ecommify · Módulo Transaccional PostgreSQL
-- Archivo : 02_indexes.sql
-- Descripción: Índices para cargas OLTP y consultas analíticas
-- =============================================================

-- -------------------------------------------------------------
-- GEOLOCATIONS
-- -------------------------------------------------------------
-- Búsqueda por prefijo de código postal (lookup frecuente)
CREATE INDEX idx_geo_zip ON geolocations (zip_code_prefix);

-- Índice espacial para consultas de proximidad con PostGIS
-- (requiere columna geometry; se añade si se migra a POINT)
-- CREATE INDEX idx_geo_point ON geolocations USING GIST (geom);

-- -------------------------------------------------------------
-- CUSTOMERS
-- -------------------------------------------------------------
CREATE INDEX idx_customers_geo   ON customers (geolocation_id);
CREATE INDEX idx_customers_name  ON customers (name);

-- -------------------------------------------------------------
-- SELLERS
-- -------------------------------------------------------------
CREATE INDEX idx_sellers_geo     ON sellers (geolocation_id);

-- -------------------------------------------------------------
-- PRODUCTS
-- -------------------------------------------------------------
-- FK a categories
CREATE INDEX idx_products_category ON products (category_id);

-- Búsqueda fuzzy por nombre (pg_trgm) — tolera errores tipográficos
CREATE INDEX idx_products_name_trgm ON products USING GIN (name gin_trgm_ops);

-- Búsqueda dentro del array de imágenes
CREATE INDEX idx_products_images ON products USING GIN (images);

-- -------------------------------------------------------------
-- PRODUCT_DETAILS
-- -------------------------------------------------------------
-- Consultas sobre atributos JSONB (ej: filtros por especificaciones)
CREATE INDEX idx_pdetails_attributes ON product_details USING GIN (attributes);

-- -------------------------------------------------------------
-- ORDERS
-- -------------------------------------------------------------
-- FK a customers (join frecuente)
CREATE INDEX idx_orders_customer ON orders (customer_id);

-- Filtros por estado del pedido
CREATE INDEX idx_orders_status ON orders (order_status);

-- Rango temporal para particionamiento lógico y análisis OLAP
CREATE INDEX idx_orders_purchase ON orders (purchase_timestamp DESC);

-- Pedidos entregados en rango de fechas
CREATE INDEX idx_orders_delivered ON orders (delivered_customer_date)
    WHERE delivered_customer_date IS NOT NULL;

-- -------------------------------------------------------------
-- ORDER_ITEMS
-- -------------------------------------------------------------
-- FK a producto (consultas: "¿cuántas veces se vendió X?")
CREATE INDEX idx_oi_product ON order_items (product_id);

-- FK a seller (consultas: "ventas por seller")
CREATE INDEX idx_oi_seller  ON order_items (seller_id);

-- -------------------------------------------------------------
-- ORDER_PAYMENTS
-- -------------------------------------------------------------
CREATE INDEX idx_op_order        ON order_payments (order_id);
CREATE INDEX idx_op_payment_type ON order_payments (payment_type);

-- -------------------------------------------------------------
-- REVIEWS
-- -------------------------------------------------------------
CREATE INDEX idx_reviews_order ON reviews (order_id);
CREATE INDEX idx_reviews_score ON reviews (score);

-- Búsqueda full-text sobre comentarios
CREATE INDEX idx_reviews_message_trgm ON reviews
    USING GIN (comment_message gin_trgm_ops);

-- -------------------------------------------------------------
-- VISTAS MATERIALIZADAS (OLAP)
-- -------------------------------------------------------------

-- Ventas mensuales por categoría
CREATE MATERIALIZED VIEW mv_sales_by_category_monthly AS
SELECT
    c.name                                    AS category_name,
    DATE_TRUNC('month', o.purchase_timestamp) AS month,
    COUNT(DISTINCT o.id)                      AS total_orders,
    SUM(oi.price)                             AS total_revenue,
    SUM(oi.freight_value)                     AS total_freight
FROM order_items  oi
JOIN orders       o  ON o.id  = oi.order_id
JOIN products     p  ON p.id  = oi.product_id
JOIN categories   c  ON c.id  = p.category_id
GROUP BY c.name, DATE_TRUNC('month', o.purchase_timestamp)
WITH DATA;

CREATE UNIQUE INDEX idx_mv_sales_cat_month
    ON mv_sales_by_category_monthly (category_name, month);

-- Segmentación de clientes (RFM simplificado)
CREATE MATERIALIZED VIEW mv_customer_segments AS
SELECT
    cu.id                                         AS customer_id,
    cu.name,
    COUNT(DISTINCT o.id)                          AS order_count,
    MAX(o.purchase_timestamp)                     AS last_purchase,
    SUM(oi.price)                                 AS lifetime_value,
    CASE
        WHEN COUNT(DISTINCT o.id) >= 10 THEN 'VIP'
        WHEN COUNT(DISTINCT o.id) >= 3  THEN 'Recurrente'
        ELSE 'Nuevo'
    END                                           AS segment
FROM customers   cu
JOIN orders      o  ON o.customer_id = cu.id
JOIN order_items oi ON oi.order_id   = o.id
GROUP BY cu.id, cu.name
WITH DATA;

CREATE UNIQUE INDEX idx_mv_customer_seg ON mv_customer_segments (customer_id);

-- Para refrescar manualmente (job semanal recomendado):
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_sales_by_category_monthly;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_segments;