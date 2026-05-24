# Ecommify · Database Design

Diseño relacional avanzado del módulo transaccional de la plataforma e-commerce **Ecommify**, implementado en PostgreSQL con arquitectura híbrida PostgreSQL + MongoDB.

> Unidad 2 · Maestría en Arquitectura de Software

---

## Estructura

```
Ecommify_Database_Design/
├── architecture/
│   ├── 01_er_conceptual.png
│   ├── 02_logical_schema.png
│   └── 03_reference_architecture.png
├── scripts/
│   ├── ddl/        → 01_ddl_schema.sql
│   ├── indexes/    → 02_indexes.sql
│   ├── data/       → 03_seed_data.sql
│   └── queries/    → 04_queries_demo.sql
└── docs/
    ├── Documento_Tecnico_Diseno.pdf
    └── Presentacion_Ejecutiva.pdf
```

---

## Arquitectura híbrida

| Módulo | Motor | Razón |
|---|---|---|
| Transaccional (orders, payments, customers) | PostgreSQL · Amazon RDS | ACID, integridad referencial |
| Catálogo analítico (product_catalog, reviews) | MongoDB · Atlas | Esquema flexible, escalabilidad |

---

## Tipos avanzados utilizados

| Campo | Tipo | Uso |
|---|---|---|
| `products.images` | `TEXT[]` | URLs de imágenes en S3 |
| `product_details.attributes` | `JSONB` | Especificaciones variables por categoría |
| Todos los IDs | `UUID` | `gen_random_uuid()` via `pgcrypto` |
| Fechas | `TIMESTAMPTZ` | Soporte multi-región |

---

## Extensiones

| Extensión | Uso |
|---|---|
| `pgcrypto` | Generación de UUIDs |
| `pg_trgm` | Búsqueda fuzzy en `products.name` |
| `postgis` | Consultas geoespaciales (RDS / Supabase) |

---

## Ejecución

```bash
psql -U postgres -d ecommify -f scripts/ddl/01_ddl_schema.sql
psql -U postgres -d ecommify -f scripts/indexes/02_indexes.sql
psql -U postgres -d ecommify -f scripts/data/03_seed_data.sql
psql -U postgres -d ecommify -f scripts/queries/04_queries_demo.sql
```


