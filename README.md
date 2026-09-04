# Base de Datos de Ventas y Auditoria con SQLite

Estructura de base de datos relacional y consultas analiticas para la gestion de clientes, productos, pedidos, pagos y auditoria.

## Caracteristicas Tecnicas

* **Integridad Referencial Activa:** Control estricto de relaciones mediante llaves foraneas activadas por software.
* **Optimizacion de Consultas:** Implementacion de indices estrategicos en campos de busqueda frecuentes y relaciones principales.
* **Auditoria de Datos Integrada:** Tablas dedicadas al seguimiento de cambios de estado y control de modificaciones campo por campo.
* **Control de Calidad (Data Quality):** Sistema de consultas preventivas para detectar inconsistencias comerciales y pedidos huerfanos.

## Arquitectura del Proyecto

* `customers`: Almacena la informacion, contacto y segmentacion de los clientes.
* `products`: Contiene el catalogo de productos con sus respectivos precios y costos.
* `orders`: Registra los encabezados de los pedidos, canales de venta y monedas.
* `order_items`: Guarda el desglose de los productos incluidos en cada pedido.
* `payments`: Registra las transacciones financieras y sus estados de aprobacion.
* `order_status_history`: Almacena el historial cronologico de los estados del pedido.
* `order_audit`: Registra las modificaciones campo por campo para control interno.
