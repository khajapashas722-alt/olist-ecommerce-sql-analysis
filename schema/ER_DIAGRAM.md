# Entity-Relationship (ER) Diagram: Brazilian E-Commerce Database

The following diagram represents the relational schema implemented in **MySQL 8.0** for the Olist E-Commerce dataset.

```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : places
    ORDERS ||--|{ ORDER_ITEMS : contains
    ORDERS ||--|{ ORDER_PAYMENTS : "settled by"
    ORDERS ||--o{ ORDER_REVIEWS : receives
    PRODUCTS ||--o{ ORDER_ITEMS : "ordered in"
    SELLERS ||--o{ ORDER_ITEMS : fulfills
    PRODUCT_CATEGORY_NAME_TRANSLATION ||--o{ PRODUCTS : categorizes
    GEOLOCATION }o--o{ CUSTOMERS : "locates by zip"
    GEOLOCATION }o--o{ SELLERS : "locates by zip"

    GEOLOCATION {
        int geolocation_id PK
        varchar(10) geolocation_zip_code_prefix
        decimal(18_15) geolocation_lat
        decimal(18_15) geolocation_lng
        varchar(100) geolocation_city
        char(2) geolocation_state
    }

    CUSTOMERS {
        varchar(32) customer_id PK
        varchar(32) customer_unique_id
        varchar(10) customer_zip_code_prefix
        varchar(100) customer_city
        char(2) customer_state
    }

    ORDERS {
        varchar(32) order_id PK
        varchar(32) customer_id FK
        varchar(20) order_status
        datetime order_purchase_timestamp
        datetime order_approved_at
        datetime order_delivered_carrier_date
        datetime order_delivered_customer_date
        datetime order_estimated_delivery_date
    }

    ORDER_ITEMS {
        varchar(32) order_id PK,FK
        int order_item_id PK
        varchar(32) product_id FK
        varchar(32) seller_id FK
        datetime shipping_limit_date
        decimal(10_2) price
        decimal(10_2) freight_value
    }

    ORDER_PAYMENTS {
        varchar(32) order_id PK,FK
        int payment_sequential PK
        varchar(20) payment_type
        int payment_installments
        decimal(10_2) payment_value
    }

    ORDER_REVIEWS {
        varchar(32) review_id PK
        varchar(32) order_id PK,FK
        int review_score
        text review_comment_title
        text review_comment_message
        datetime review_creation_date
        datetime review_answer_timestamp
    }

    PRODUCTS {
        varchar(32) product_id PK
        varchar(100) product_category_name FK
        int product_name_length
        int product_description_length
        int product_photos_qty
        int product_weight_g
        int product_length_cm
        int product_height_cm
        int product_width_cm
    }

    SELLERS {
        varchar(32) seller_id PK
        varchar(10) seller_zip_code_prefix
        varchar(100) seller_city
        char(2) seller_state
    }

    PRODUCT_CATEGORY_NAME_TRANSLATION {
        varchar(100) product_category_name PK
        varchar(100) product_category_name_english
    }
```

### Table Relationships & Cardinality
1. **`CUSTOMERS` to `ORDERS` (1 : M)**: A single customer entity can place multiple orders over time. Note that `customer_id` is unique per transaction, while `customer_unique_id` tracks repeat individuals.
2. **`ORDERS` to `ORDER_ITEMS` (1 : M)**: An individual order can contain one or multiple line items.
3. **`ORDERS` to `ORDER_PAYMENTS` (1 : M)**: An order can be split across multiple payment methods or installment vouchers.
4. **`ORDERS` to `ORDER_REVIEWS` (1 : M)**: An order may receive customer feedback surveys.
5. **`PRODUCTS` to `ORDER_ITEMS` (1 : M)**: Products can be ordered multiple times across distinct orders.
6. **`SELLERS` to `ORDER_ITEMS` (1 : M)**: Marketplace merchants can fulfill multiple ordered items.
7. **`PRODUCT_CATEGORY_NAME_TRANSLATION` to `PRODUCTS` (1 : M)**: Lookup table mapping Brazilian Portuguese categories to international English names.
8. **`GEOLOCATION` to `CUSTOMERS` / `SELLERS` (M : N via Zip Prefix)**: Multi-observation spatial coordinate mapping. A Brazilian 5-digit zip code prefix (`CEP`) encompasses multiple spatial coordinate points. Spatial analyses derive centroid coordinates via `AVG(geolocation_lat), AVG(geolocation_lng)` to calculate buyer-merchant freight distances.
