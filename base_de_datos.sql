PRAGMA foreign_keys = ON;

-- TABLAS

-- customers: guarda los datos de cada cliente
CREATE TABLE IF NOT EXISTS customers (  

    customer_id  INTEGER PRIMARY KEY,   

    full_name    TEXT    NOT NULL,      

    email        TEXT    NOT NULL       
                         UNIQUE,        

    phone        TEXT,                  

    city         TEXT,                  

    segment      TEXT    NOT NULL       
                         CHECK(segment IN ('retail','wholesale','vip','online_only')),

    created_at   TEXT    NOT NULL,      

    is_active    INTEGER NOT NULL       
                         DEFAULT 1      
                         CHECK(is_active IN (0,1)), 

    deleted_at   TEXT                   
);

-- products: catálogo de productos disponibles
CREATE TABLE IF NOT EXISTS products (

    product_id   INTEGER PRIMARY KEY,   
    
    sku          TEXT    NOT NULL       
                         UNIQUE,        

    product_name TEXT    NOT NULL,      

    category     TEXT,                  

    brand        TEXT,                  

    unit_price   REAL    NOT NULL       
                         CHECK(unit_price >= 0),  -

    unit_cost    REAL    NOT NULL      
                         CHECK(unit_cost >= 0),   

    created_at   TEXT    NOT NULL,      

    is_active    INTEGER NOT NULL       
                         DEFAULT 1
                         CHECK(is_active IN (0,1)),

    deleted_at   TEXT                   
);


-- orders: cada pedido realizado por un cliente
CREATE TABLE IF NOT EXISTS orders (

    order_id       INTEGER PRIMARY KEY,  

    customer_id    INTEGER NOT NULL,     

    order_datetime TEXT    NOT NULL,     

    channel        TEXT    NOT NULL      
                           CHECK(channel IN ('web','mobile','store','phone')),
                                         
    currency       TEXT    NOT NULL      
                           CHECK(currency IN ('PYG','USD')), 

    current_status TEXT    NOT NULL      
                           CHECK(current_status IN ('created','packed','shipped','delivered','paid','cancelled','refunded')),

    is_active      INTEGER NOT NULL      
                           DEFAULT 1
                           CHECK(is_active IN (0,1)),

    deleted_at     TEXT,                 

    order_total    REAL                  
                   CHECK(order_total >= 0),

    -- FK: customer_id debe existir en la tabla customers
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- order_items: las líneas (productos) de cada pedido

CREATE TABLE IF NOT EXISTS order_items (

    order_item_id INTEGER PRIMARY KEY,   

    order_id      INTEGER NOT NULL,      

    product_id    INTEGER NOT NULL,      

    quantity      INTEGER NOT NULL       
                          CHECK(quantity > 0),  

    unit_price    REAL    NOT NULL       
                          CHECK(unit_price >= 0),

    discount_rate REAL    NOT NULL       
                          DEFAULT 0      
                          CHECK(discount_rate >= 0 AND discount_rate <= 1), 

    line_total    REAL    NOT NULL      
                          CHECK(line_total >= 0),

    FOREIGN KEY (order_id)   REFERENCES orders(order_id),   
    FOREIGN KEY (product_id) REFERENCES products(product_id) 
);


-- payments: registra los pagos asociados a cada pedido

CREATE TABLE IF NOT EXISTS payments (

    payment_id       INTEGER PRIMARY KEY,  

    order_id         INTEGER NOT NULL,     

    payment_datetime TEXT    NOT NULL,     

    method           TEXT    NOT NULL      
                             CHECK(method IN ('card','cash','transfer','wallet')),

    payment_status   TEXT    NOT NULL     
                             CHECK(payment_status IN ('approved','pending','rejected','refunded')),

    amount           REAL    NOT NULL      
                             CHECK(amount >= 0),

    currency         TEXT    NOT NULL      
                             CHECK(currency IN ('PYG','USD')),

    FOREIGN KEY (order_id) REFERENCES orders(order_id)  
);

-- order_status_history: historial de todos los cambios de estado
CREATE TABLE IF NOT EXISTS order_status_history (

    status_history_id INTEGER PRIMARY KEY,  

    order_id          INTEGER NOT NULL,     

    status            TEXT    NOT NULL      
                              CHECK(status IN ('created','packed','shipped','delivered','paid','cancelled','refunded')),

    changed_at        TEXT    NOT NULL,     

    changed_by        TEXT    NOT NULL,     

    reason            TEXT,                 

    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- order_audit: auditoría campo por campo
CREATE TABLE IF NOT EXISTS order_audit (

    audit_id   INTEGER PRIMARY KEY,  

    order_id   INTEGER NOT NULL,     

    field_name TEXT    NOT NULL,     

    old_value  TEXT,                 

    new_value  TEXT,                 

    changed_at TEXT    NOT NULL,     

    changed_by TEXT    NOT NULL,     

    FOREIGN KEY (order_id) REFERENCES orders(order_id)  
);

-- ÍNDICES

CREATE INDEX IF NOT EXISTS idx_orders_customer   ON orders(customer_id);

CREATE INDEX IF NOT EXISTS idx_items_order       ON order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_payments_order    ON payments(order_id);

CREATE INDEX IF NOT EXISTS idx_status_order      ON order_status_history(order_id);

CREATE INDEX IF NOT EXISTS idx_audit_order       ON order_audit(order_id);

CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

-- CONSULTAS ESTRUCTURALES

-- Todos los pedidos mostrando el nombre del cliente 
SELECT
    o.order_id,                 
    c.full_name    AS cliente,    
    c.city         AS ciudad,    
    o.order_datetime AS fecha_pedido,
    o.channel      AS canal,      
    o.current_status AS estado,
    o.order_total  AS total
FROM orders o                              
JOIN customers c ON o.customer_id = c.customer_id  
ORDER BY o.order_datetime DESC;            


-- Los productos de un pedido específico
SELECT
    oi.order_item_id,
    oi.order_id,
    p.product_name   AS producto,    
    p.category       AS categoria,
    oi.quantity      AS cantidad,
    oi.unit_price    AS precio_unitario,
    oi.discount_rate AS descuento,   
    oi.line_total    AS total_linea
FROM order_items oi                              
JOIN products p ON oi.product_id = p.product_id 
WHERE oi.order_id = 1                           
ORDER BY oi.order_item_id;                      


-- Pagos aprobados con el estado del pedido al que pertenecen
SELECT
    p.payment_id,
    p.order_id,
    o.current_status   AS estado_pedido,   
    p.payment_datetime AS fecha_pago,
    p.method           AS metodo,
    p.payment_status   AS estado_pago,
    p.amount           AS monto,
    p.currency         AS moneda
FROM payments p                              
JOIN orders o ON p.order_id = o.order_id    
WHERE p.payment_status = 'approved'          
ORDER BY p.payment_datetime DESC;


-- Historial cronológico de estados de un pedido 
SELECT
    sh.status_history_id,
    sh.order_id,
    sh.status      AS estado,
    sh.changed_at  AS fecha_cambio,
    sh.changed_by  AS cambiado_por,  
    sh.reason      AS motivo
FROM order_status_history sh         
WHERE sh.order_id = 100              
ORDER BY sh.changed_at ASC;          


-- Auditoría de un pedido: qué campos se modificaron y por quién
SELECT
    a.audit_id,
    a.order_id,
    a.field_name  AS campo_modificado,  
    a.old_value   AS valor_anterior,    
    a.new_value   AS valor_nuevo,       
    a.changed_at  AS fecha_cambio,
    a.changed_by  AS modificado_por
FROM order_audit a          
WHERE a.order_id = 1       
ORDER BY a.changed_at ASC;  


-- Todos los pedidos cancelados con los datos del cliente
SELECT
    o.order_id,
    c.full_name   AS cliente,
    c.email,
    o.order_datetime,
    o.order_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.current_status = 'cancelled'   
ORDER BY o.order_datetime DESC;


-- Todos los productos activos, del más caro al más barato
SELECT
    product_id,
    sku,
    product_name AS nombre,
    category     AS categoria,
    brand        AS marca,
    unit_price   AS precio,
    unit_cost    AS costo
FROM products
WHERE is_active = 1          
ORDER BY unit_price DESC;    


-- Clientes activos filtrados por segmento
SELECT
    customer_id,
    full_name  AS nombre,
    email,
    city       AS ciudad,
    segment    AS segmento,
    created_at AS fecha_alta
FROM customers
WHERE is_active = 1              
  AND segment = 'vip'            
ORDER BY full_name ASC;          



-- DETECCIÓN DE INCONSISTENCIAS

-- Pedidos cuyo customer_id no existe en la tabla customers 
SELECT o.order_id, o.customer_id
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id  
WHERE c.customer_id IS NULL;                             


-- Ítems de pedido cuyo product_id no existe en products 
SELECT oi.order_item_id, oi.product_id
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;  -- 


-- Pagos cuyo order_id no existe en orders 
SELECT p.payment_id, p.order_id
FROM payments p
LEFT JOIN orders o ON p.order_id = o.order_id
WHERE o.order_id IS NULL;  


-- Pedido cancelado que además tiene un pago aprobado
SELECT
    o.order_id,
    o.current_status AS estado_pedido,
    p.payment_status AS estado_pago,
    p.amount
FROM orders o
JOIN payments p ON o.order_id = p.order_id  
WHERE o.current_status = 'cancelled'          
  AND p.payment_status = 'approved';          


-- Pedidos sin ningún ítem registrado 
SELECT o.order_id, o.customer_id, o.current_status
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id  
WHERE oi.order_id IS NULL;                             


-- Pedidos en estado avanzado que no tienen ningún pago registrado
SELECT o.order_id, o.customer_id, o.current_status, o.order_total
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id        
WHERE p.payment_id IS NULL                             
  AND o.current_status NOT IN ('created','cancelled'); 


-- Productos cuyo precio de venta es menor al costo 
SELECT product_id, product_name, unit_price, unit_cost
FROM products
WHERE unit_price < unit_cost   -
ORDER BY product_name;