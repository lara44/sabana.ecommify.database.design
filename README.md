# Ecommify · Database Design

Diseño relacional avanzado del módulo transaccional de la plataforma e-commerce **Ecommify**, implementado en PostgreSQL con arquitectura híbrida PostgreSQL + MongoDB.

> Unidad 2 · Maestría en Arquitectura de Software

---

## Estructura

```
SABANA.ECOMMIFY.DATABASE.DESIGN/
├── 01_architecture/
│   ├── 01_er_conceptual.png
│   ├── 02_logical_schema.png
│   └── 03_reference_architecture.png
├── 02_objects/
│   └── ecommify_er.drawio        # Archivo fuente editable con 3 pestañas:
│                                 #   · Tab 1: ER Conceptual
│                                 #   · Tab 2: Esquema Lógico
│                                 #   · Tab 3: Arquitectura de Referencia
├── 03_scripts/
│   ├── 01_ddl_schema.sql
│   ├── 02_indexes.sql
│   ├── 03_seed_data.sql
│   └── 04_queries_demo.sql
└── README.md
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
psql -U postgres -d ecommify -f 03_scripts/01_ddl_schema.sql
psql -U postgres -d ecommify -f 03_scripts/02_indexes.sql
psql -U postgres -d ecommify -f 03_scripts/03_seed_data.sql
psql -U postgres -d ecommify -f 03_scripts/04_queries_demo.sql
```
