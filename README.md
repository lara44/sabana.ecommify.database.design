# Ecommify · Database Design

> Diseño e implementación de una arquitectura híbrida de bases de datos para la plataforma e-commerce **Ecommify**, desarrollada como proyecto integrador del curso **Diseño y Optimización de Bases de Datos** — Maestría en Arquitectura de Software, Universidad de La Sabana.

---

## Equipo

| Integrante | Rol |
|---|---|
| Astrid Carolina Rodríguez Cristancho | EDA + Normalización |
| Luis Alberto Rojas Adames | Modelado ER + DDL + Repositorio |
| Alexander Caballero García | Extensiones PostgreSQL + MongoDB |
| Brian Maldonado | Arquitectura híbrida + OLTP/OLAP |

---

## Fase 1 — Diseño conceptual, lógico y arquitectónico
**Entregable evaluativo 1 · Unidades 1, 2 y 3**

### Estructura

```
SABANA.ECOMMIFY.DATABASE.DESIGN/
│
├── 01_architecture/
│   ├── 01_er_conceptual.png
│   ├── 02_logical_schema.png
│   └── 03_reference_architecture.png
│
├── 02_objects/
│   └── ecommify_er.drawio
│
├── 03_postgresql/
│   ├── scripts/
│   │   ├── 01_ddl_schema.sql
│   │   ├── 02_indexes.sql
│   │   ├── 03_seed_data.sql
│   │   ├── 04_queries_demo.sql
│   │   └── 05_maintenance_pgcron.sql
│   ├── indexes/
│   │   └── 01_indexes.sql
│   ├── notebooks/
│   │   ├── 01_Data_Exploration_Analysis.ipynb
│   │   ├── 02_ecommify_load_supabase.ipynb
│   │   ├── 03_ecommify_explain_analyze.ipynb
│   │   └── 04_ecommify_particionamiento.ipynb
│   └── evidencias/
│       └── optimizacion/
│           ├── antes/
│           └── despues/
│
├── 04_mongodb/
│   ├── schemas/
│   │   ├── product_catalog_schema.json
│   │   └── reviews_schema.json
│   ├── indexes/
│   │   └── 01_indexes.js
│   ├── pipelines/
│   │   └── 01_aggregation_pipelines.js
│   ├── notebooks/
│   │   ├── 01_MongoDB_Setup.ipynb
│   │   └── 02_MongoDB_Schema_Products.ipynb
│   └── evidencias/
│       └── optimizacion/
│           ├── antes/
│           └── despues/
│
└── README.md
```

### Arquitectura híbrida

| Módulo | Motor | Razón |
|---|---|---|
| Transaccional (orders, payments, customers, sellers) | PostgreSQL · Supabase | ACID, integridad referencial nativa |
| Analítico / Catálogo (product_catalog, reviews) | MongoDB · Atlas M0 | Esquema flexible, escalabilidad horizontal |

### Tipos avanzados utilizados

| Campo | Tipo | Uso |
|---|---|---|
| `products.images` | `TEXT[]` | URLs de imágenes en S3 / Azure Blob |
| `product_details.attributes` | `JSONB` | Especificaciones variables por categoría |
| Todos los IDs | `UUID` | `gen_random_uuid()` via `pgcrypto` |
| Fechas | `TIMESTAMPTZ` | Soporte multi-región / zona horaria explícita |

### Extensiones PostgreSQL

| Extensión | Uso |
|---|---|
| `pgcrypto` | Generación de UUIDs criptográficamente seguros |
| `pg_trgm` | Búsqueda fuzzy tolerante a errores en `products.name` |
| `postgis` | Consultas geoespaciales sobre `geolocations` (distancia vendedor-cliente) |
| `hstore` | Metadatos planos de vendedores |
| `pg_cron` | Programación de jobs: VACUUM, refresh de vistas materializadas |

### Vistas materializadas (OLAP)

| Vista | Descripción | Refresh recomendado |
|---|---|---|
| `mv_sales_by_category_monthly` | Ventas por categoría y mes | Diario 2:30 AM |
| `mv_customer_segments` | Segmentación RFM de clientes | Semanal domingos |

### Ejecución

```bash
psql -U postgres -d ecommify -f 03_postgresql/scripts/01_ddl_schema.sql
psql -U postgres -d ecommify -f 03_postgresql/scripts/02_indexes.sql
psql -U postgres -d ecommify -f 03_postgresql/scripts/03_seed_data.sql
psql -U postgres -d ecommify -f 03_postgresql/scripts/04_queries_demo.sql
```

Para MongoDB Atlas ejecutar los notebooks en orden desde `04_mongodb/notebooks/` con el secret `MONGODB_URI` configurado en Google Colab Secrets.

---

## Fase 2 — Optimización de rendimiento
**Entregable evaluativo 2 · Unidades 4 y 5**

### Configuración Supabase

Se configuró un servidor de base de datos PostgreSQL en Supabase Free Tier.

### Creación de la base de datos

La base de datos fue creada a partir del DDL generado en la Fase 1. Ver `03_postgresql/scripts/01_ddl_schema.sql`.

### Ejecución de consultas sin índices

Se ejecutaron las consultas críticas del sistema sobre el dataset Olist sin índices especializados para establecer métricas base de rendimiento.

- **PostgreSQL:** Ver notebook `03_postgresql/notebooks/03_ecommify_explain_analyze.ipynb` · Evidencias en `03_postgresql/evidencias/optimizacion/antes/`
- **MongoDB:** Ver notebook `04_mongodb/notebooks/02_MongoDB_Schema_Products.ipynb` · Evidencias en `04_mongodb/evidencias/optimizacion/antes/`

### Creación de índices

- **PostgreSQL:** Índices especializados B-tree, GIN, GIN trgm y parciales. Ver `03_postgresql/indexes/01_indexes.sql`
- **MongoDB:** Índices compuestos con regla ESR, índices parciales e índices de texto. Ver `04_mongodb/indexes/01_indexes.js`

### Ejecución de consultas con índices

Se ejecutaron nuevamente las consultas críticas tras la implementación de índices y particionamiento, documentando las mejoras obtenidas.

- **PostgreSQL:** Ver notebook `03_postgresql/notebooks/03_ecommify_explain_analyze.ipynb` · Evidencias en `03_postgresql/evidencias/optimizacion/despues/`
- **MongoDB:** Ver notebook `04_mongodb/notebooks/02_MongoDB_Schema_Products.ipynb` · Evidencias en `04_mongodb/evidencias/optimizacion/despues/`

---

## Fase 3 — Pendiente
**Entregable evaluativo 3 · Unidad siguiente**

---

## Dataset

Brazilian E-Commerce Public Dataset by Olist · Kaggle
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

---

## Referencias

- PostgreSQL Global Development Group. (2025). *Data types*. PostgreSQL 16 Documentation. https://www.postgresql.org/docs/16/datatype.html
- PostgreSQL Global Development Group. (2025). *Server programming: Extending SQL*. PostgreSQL 16 Documentation. https://www.postgresql.org/docs/16/extend.html
- MongoDB, Inc. (2025). *Data modeling patterns*. MongoDB Manual. https://www.mongodb.com/docs/manual/data-modeling/design-patterns/
- MongoDB, Inc. (2025). *Sharding*. MongoDB Manual. https://www.mongodb.com/docs/manual/sharding/
- MongoDB, Inc. (2025). *Replica sets*. MongoDB Manual. https://www.mongodb.com/docs/manual/replication/
- Olist. (2018). *Brazilian E-Commerce Public Dataset by Olist*. Kaggle. https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce