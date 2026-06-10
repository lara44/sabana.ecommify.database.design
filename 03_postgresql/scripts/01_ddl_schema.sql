-- =============================================================
-- Ecommify · Módulo Transaccional PostgreSQL
-- Archivo : 01_ddl_schema.sql
-- Descripción: DDL completo — tablas, constraints y tipos avanzados
-- Autor   : Luis (SoftwareOne)
-- =============================================================

-- Extensiones requeridas
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- búsqueda fuzzy sobre products.name
-- PostGIS requiere instalación previa en el SO (paquete postgresql-16-postgis-3).
-- En Amazon RDS, Supabase y Docker (postgis/postgis:16-3.4) está disponible de fábrica.
-- Descomenta la siguiente línea solo si PostGIS está instalado en tu entorno:
-- CREATE EXTENSION IF NOT EXISTS "postgis";  -- coordenadas en geolocations

-- -------------------------------------------------------------
-- 1. GEOLOCATIONS
-- -------------------------------------------------------------
CREATE TABLE geolocations (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    zip_code_prefix  VARCHAR(10)   NOT NULL,
    lat              DECIMAL(9,6)  NOT NULL,
    lng              DECIMAL(9,6)  NOT NULL,
    city             VARCHAR(100)  NOT NULL,
    state            VARCHAR(5)    NOT NULL
);

-- -------------------------------------------------------------
-- 2. CUSTOMERS
-- -------------------------------------------------------------
CREATE TABLE customers (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    geolocation_id   UUID          NULL
                        REFERENCES geolocations(id) ON DELETE SET NULL,
    name             VARCHAR(200)  NOT NULL
);

-- -------------------------------------------------------------
-- 3. SELLERS
-- -------------------------------------------------------------
CREATE TABLE sellers (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    geolocation_id   UUID          NULL
                        REFERENCES geolocations(id) ON DELETE SET NULL,
    name             VARCHAR(200)  NOT NULL
);

-- -------------------------------------------------------------
-- 4. CATEGORIES
-- -------------------------------------------------------------
CREATE TABLE categories (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    name             VARCHAR(100)  NOT NULL UNIQUE
);

-- -------------------------------------------------------------
-- 5. PRODUCTS
-- -------------------------------------------------------------
CREATE TABLE products (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    category_id      UUID          NULL
                        REFERENCES categories(id) ON DELETE SET NULL,
    name             VARCHAR(200)  NOT NULL,
    images           TEXT[]        NULL          -- Array de URLs (S3 / Azure Blob)
);

-- -------------------------------------------------------------
-- 6. PRODUCT_DETAILS  (WeakEntity 1:1 con products)
-- -------------------------------------------------------------
CREATE TABLE product_details (
    product_id       UUID          PRIMARY KEY NOT NULL
                        REFERENCES products(id) ON DELETE CASCADE,
    attributes       JSONB         NULL,         -- especificaciones flexibles
    description      TEXT          NULL
);

-- -------------------------------------------------------------
-- 7. ORDERS
-- -------------------------------------------------------------
CREATE TABLE orders (
    id                       UUID          PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    customer_id              UUID          NOT NULL
                               REFERENCES customers(id) ON DELETE RESTRICT,
    order_status             VARCHAR(30)   NOT NULL,
    purchase_timestamp       TIMESTAMPTZ   NOT NULL,
    approved_at              TIMESTAMPTZ   NULL,
    delivered_customer_date  TIMESTAMPTZ   NULL,
    estimated_delivery_date  TIMESTAMPTZ   NULL,
    delivered_carrier_date   TIMESTAMPTZ   NULL,
    update_at                TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- -------------------------------------------------------------
-- 8. ORDER_ITEMS  (WeakEntity — PK compuesta)
-- -------------------------------------------------------------
CREATE TABLE order_items (
    order_id         UUID          NOT NULL
                        REFERENCES orders(id) ON DELETE CASCADE,
    item_sequence    INT           NOT NULL,
    product_id       UUID          NOT NULL
                        REFERENCES products(id) ON DELETE RESTRICT,
    seller_id        UUID          NOT NULL
                        REFERENCES sellers(id) ON DELETE RESTRICT,
    price            DECIMAL(10,2) NOT NULL,
    freight_value    DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, item_sequence)
);

-- -------------------------------------------------------------
-- 9. ORDER_PAYMENTS
-- -------------------------------------------------------------
CREATE TABLE order_payments (
    id                   UUID          PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    order_id             UUID          NOT NULL
                           REFERENCES orders(id) ON DELETE CASCADE,
    payment_type         VARCHAR(30)   NOT NULL,
    payment_installments INT           NOT NULL,
    payment_value        DECIMAL(10,2) NOT NULL,
    update_at            TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- -------------------------------------------------------------
-- 10. REVIEWS
-- -------------------------------------------------------------
CREATE TABLE reviews (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    order_id         UUID          NULL
                        REFERENCES orders(id) ON DELETE SET NULL,
    score            INT           NOT NULL CHECK (score BETWEEN 1 AND 5),
    comment_title    VARCHAR(200)  NULL,
    comment_message  TEXT          NULL,
    creation_date    TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- -------------------------------------------------------------
-- Trigger: mantener update_at automáticamente
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_set_update_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_update_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION fn_set_update_at();

CREATE TRIGGER trg_order_payments_update_at
    BEFORE UPDATE ON order_payments
    FOR EACH ROW EXECUTE FUNCTION fn_set_update_at();