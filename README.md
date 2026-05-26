# Ecommify · Database Design

Diseño relacional avanzado del módulo transaccional de la plataforma e-commerce **Ecommify**, implementado en PostgreSQL con arquitectura híbrida PostgreSQL + MongoDB.

> Unidad 2 · Maestría en Arquitectura de Software

## Equipo

| Integrante | Rol |
|---|---|
| Astrid Carolina Rodríguez Cristancho | EDA + Normalización |
| Luis Alberto Rojas Adames | Modelado ER + DDL + Repositorio |
| Alexander Caballero García | Extensiones PostgreSQL + MongoDB |
| Brian Maldonado | Arquitectura híbrida + OLTP/OLAP |

## Estructura

```
SABANA.ECOMMIFY.DATABASE.DESIGN/
├── 01_architecture/
│   ├── 01_er_conceptual.png          # Diagrama ER conceptual
│   ├── 02_logical_schema.png         # Esquema lógico con tipos de datos
│   └── 03_reference_architecture.png # Arquitectura híbrida cloud
│
├── 02_objects/
│   └── ecommify_er.drawio            # Archivo fuente editable (3 pestañas):
│                                     #   · Tab 1: ER Conceptual
│                                     #   · Tab 2: Esquema Lógico
│                                     #   · Tab 3: Arquitectura de Referencia
│
├── 03_scripts/
│   ├── 01_ddl_schema.sql             # DDL completo: tablas, constraints, triggers
│   ├── 02_indexes.sql                # Índices OLTP/OLAP + vistas materializadas
│   ├── 03_seed_data.sql              # Datos de ejemplo para desarrollo y demos
│   └── 04_queries_demo.sql           # Queries: TEXT[], JSONB, pg_trgm, OLTP, OLAP
│   └── 05_maintenance_pgcron.sql     
│
├── 04_docs/
│   ├── 01_Documento_Tecnico.pdf      # Documento técnico de diseño (ver docs/)
│   └── 02_Ecommify_Presentacion_Ejecutiva.pptx
│
├── 05_notebooks/
│   └── Data_Exploration_Analysis.ipynb  # EDA completo sobre dataset Olist en Colab
│
├── 06_mongodb/
│   ├── product_catalog_schema.json   # Esquema colección product_catalog
│   └── reviews_schema.json           # Esquema colección reviews
│
└── README.md
```

---

## Arquitectura híbrida

| Módulo | Motor | Razón |
|---|---|---|
| Transaccional (orders, payments, customers, sellers) | PostgreSQL · Supabase / Amazon RDS | ACID, integridad referencial nativa |
| Analítico / Catálogo (product_catalog, reviews) | MongoDB · Atlas M0 | Esquema flexible, escalabilidad horizontal |

---

## Tipos avanzados utilizados

| Campo | Tipo | Uso |
|---|---|---|
| `products.images` | `TEXT[]` | URLs de imágenes en S3 / Azure Blob |
| `product_details.attributes` | `JSONB` | Especificaciones variables por categoría |
| Todos los IDs | `UUID` | `gen_random_uuid()` via `pgcrypto` |
| Fechas | `TIMESTAMPTZ` | Soporte multi-región / zona horaria explícita |

---

## Extensiones PostgreSQL

| Extensión | Uso |
|---|---|
| `pgcrypto` | Generación de UUIDs criptográficamente seguros |
| `pg_trgm` | Búsqueda fuzzy tolerante a errores en `products.name` |
| `postgis` | Consultas geoespaciales sobre `geolocations` (distancia vendedor-cliente) |
| `hstore` | Metadatos planos de vendedores |

---

## Vistas materializadas (OLAP)

| Vista | Descripción | Refresh recomendado |
|---|---|---|
| `mv_sales_by_category_monthly` | Ventas por categoría y mes | Diario 2:30 AM |
| `mv_customer_segments` | Segmentación RFM de clientes | Semanal domingos |

---

## Ejecución

```bash
# 1. Crear esquema completo
psql -U postgres -d ecommify -f 03_scripts/01_ddl_schema.sql

# 2. Crear índices y vistas materializadas
psql -U postgres -d ecommify -f 03_scripts/02_indexes.sql

# 3. Cargar datos de ejemplo
psql -U postgres -d ecommify -f 03_scripts/03_seed_data.sql

# 4. Ejecutar queries demo
psql -U postgres -d ecommify -f 03_scripts/04_queries_demo.sql
```

---

## Dataset

Brazilian E-Commerce Public Dataset by Olist · Kaggle  
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

El análisis exploratorio completo está disponible en `05_notebooks/Data_Exploration_Analysis.ipynb`