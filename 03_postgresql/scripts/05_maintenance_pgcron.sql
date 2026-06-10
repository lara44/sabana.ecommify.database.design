-- =============================================================
-- Ecommify · Módulo Transaccional PostgreSQL
-- Archivo : 05_maintenance_pgcron.sql
-- Descripción: Jobs programados de mantenimiento con pg_cron
-- Nota: pg_cron debe estar habilitado en Supabase Dashboard
--       Settings → Database → Extensions → pg_cron
-- =============================================================

-- Activar extensión
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- -------------------------------------------------------------
-- VACUUM diario a las 2:00 AM
-- Libera espacio de filas eliminadas y actualiza estadísticas
-- -------------------------------------------------------------
SELECT cron.schedule(
    'vacuum-orders-daily',
    '0 2 * * *',
    'VACUUM ANALYZE orders'
);

SELECT cron.schedule(
    'vacuum-order-items-daily',
    '10 2 * * *',
    'VACUUM ANALYZE order_items'
);

-- -------------------------------------------------------------
-- REFRESH vistas materializadas
-- -------------------------------------------------------------

-- Ventas por categoría — diario 2:30 AM
SELECT cron.schedule(
    'refresh-mv-sales',
    '30 2 * * *',
    'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_sales_by_category_monthly'
);

-- Segmentación de clientes — semanal domingos 3:00 AM
SELECT cron.schedule(
    'refresh-mv-customers',
    '0 3 * * 0',
    'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_segments'
);

-- -------------------------------------------------------------
-- Verificar jobs programados
-- -------------------------------------------------------------
-- SELECT * FROM cron.job;

-- -------------------------------------------------------------
-- Eliminar un job si es necesario
-- -------------------------------------------------------------
-- SELECT cron.unschedule('vacuum-orders-daily');