--Lista todos los locales con su ciudad y tipo de zona.
SELECT nombre, ciudad, tipo_zona
FROM locales;
--Lista los productos de la categoría "Pizza", ordenados de más caro a más barato.
SELECT nombre, categoria, precio_venta
FROM productos
WHERE categoria = 'Pizza'
ORDER BY precio_venta DESC;
--¿Cuántas líneas de venta hay en total en la tabla ventas?
SELECT COUNT(*) AS total_lineas
FROM ventas;
--Lista las 10 ventas con mayor importe total.
SELECT *
FROM ventas
ORDER BY importe_total DESC
LIMIT 10;
--¿Qué productos tienen un margen (margen_pct) superior al 70%?
SELECT nombre, categoria, margen_pct
FROM productos
WHERE margen_pct > 0.70;
--Ventas totales (suma de importe_total) por local, ordenadas de mayor a menor. 
SELECT l.nombre, ROUND(SUM(v.importe_total),2) AS ventas_totales
FROM ventas v
JOIN locales l ON v.local_id = l.local_id
GROUP BY l.nombre
ORDER BY ventas_totales DESC;
--Top 10 productos más vendidos en unidades (todos los locales, todo el periodo).
SELECT p.nombre, SUM(v.unidades_vendidas) AS unidades
FROM ventas v
JOIN productos p ON v.producto_id = p.producto_id
GROUP BY p.nombre
ORDER BY unidades DESC
LIMIT 10;
--. Ticket medio (importe_total medio por línea de venta) por categoría de producto.
SELECT p.categoria, ROUND(AVG(v.importe_total),2) AS ticket_medio
FROM ventas v
JOIN productos p ON v.producto_id = p.producto_id
GROUP BY p.categoria
ORDER BY ticket_medio DESC;
--Ventas totales por mes de todo 2025 (una fila por mes, con el total de ese mes).
SELECT strftime('%Y-%m', fecha) AS mes, ROUND(SUM(importe_total),2) AS ventas_mes
FROM ventas
WHERE fecha >= '2025-01-01' AND fecha < '2026-01-01'
GROUP BY mes
ORDER BY mes;
--¿Cuántos productos distintos se han vendido alguna vez en cada local?
SELECT l.nombre, COUNT(DISTINCT v.producto_id) AS productos_distintos
FROM ventas v
JOIN locales l ON v.local_id = l.local_id
GROUP BY l.nombre
ORDER BY productos_distintos DESC;
--. Margen bruto total (en euros) generado por cada local
SELECT l.nombre,
  ROUND(SUM(v.unidades_vendidas * (p.precio_venta - p.coste_unitario)), 2) AS margen_bruto_total
FROM ventas v
JOIN locales l ON v.local_id = l.local_id
JOIN productos p ON v.producto_id = p.producto_id
GROUP BY l.nombre
ORDER BY margen_bruto_total DESC;
--Para cada local, el producto más vendido en unidades dentro de ese local (un producto por local).
WITH ventas_producto_local AS (
  SELECT v.local_id, v.producto_id, SUM(v.unidades_vendidas) AS unidades,
         ROW_NUMBER() OVER (PARTITION BY v.local_id ORDER BY SUM(v.unidades_vendidas) DESC) AS rn
  FROM ventas v
  GROUP BY v.local_id, v.producto_id
)
SELECT l.nombre AS local, p.nombre AS producto_top, vpl.unidades
FROM ventas_producto_local vpl
JOIN locales l ON vpl.local_id = l.local_id
JOIN productos p ON vpl.producto_id = p.producto_id
WHERE vpl.rn = 1
ORDER BY l.nombre;
--Evolución mensual de ventas de Bracet Blanes (local_id 4) vs Bracet Eixample (local_id 1)
SELECT strftime('%Y-%m', fecha) AS mes,
   ROUND(SUM(CASE WHEN local_id = 4 THEN importe_total END),2) AS ventas_blanes,
   ROUND(SUM(CASE WHEN local_id = 1 THEN importe_total END),2) AS ventas_eixample
FROM ventas
WHERE local_id IN (1,4)
GROUP BY mes
ORDER BY mes;
--¿Qué locales facturaron por encima de la media de todos los locales en julio de 2025?
WITH ventas_julio AS (
  SELECT local_id, SUM(importe_total) AS total
  FROM ventas
  WHERE fecha >= '2025-07-01' AND fecha < '2025-08-01'
  GROUP BY local_id
)
SELECT l.nombre, vj.total
FROM ventas_julio vj
JOIN locales l ON vj.local_id = l.local_id
WHERE vj.total > (SELECT AVG(total) FROM ventas_julio)
ORDER BY vj.total DESC;
--. Compara las ventas de postres de Bracet Blanes durante la promoción "Verano Costa Brava 2x1 Postres" (1-15 agosto 2024) frente a los 15 días inmediatamente posteriores (16-31 agosto 2024). ¿Vendió más unidades con la promoción activa?
SELECT
  CASE WHEN v.fecha BETWEEN '2024-08-01' AND '2024-08-15' THEN 'Durante promo'
       WHEN v.fecha BETWEEN '2024-08-16' AND '2024-08-31' THEN 'Despues de promo' END AS periodo,
  SUM(v.unidades_vendidas) AS unidades,
  ROUND(SUM(v.importe_total),2) AS ventas_postres
FROM ventas v
JOIN productos p ON v.producto_id = p.producto_id
WHERE v.local_id = 4
  AND p.categoria = 'Postres'
  AND (v.fecha BETWEEN '2024-08-01' AND '2024-08-15' OR v.fecha BETWEEN '2024-08-16' AND '2024-08-31')
GROUP BY periodo;
--Ranking de los 5 productos más rentables (margen total en euros) en 2025, con el nombre de categoría.
SELECT p.nombre AS producto, p.categoria,
   ROUND(SUM(v.unidades_vendidas * (p.precio_venta - p.coste_unitario)),2) AS margen_total
FROM ventas v
JOIN productos p ON v.producto_id = p.producto_id
WHERE v.fecha >= '2025-01-01' AND v.fecha < '2026-01-01'
GROUP BY p.nombre, p.categoria
ORDER BY margen_total DESC
LIMIT 5;
--Calcula el crecimiento de ventas de cada local comparando el primer semestre de 2025 con el primer semestre de 2026 (% de variación).
WITH h1_2025 AS (
  SELECT local_id, SUM(importe_total) AS total
  FROM ventas WHERE fecha >= '2025-01-01' AND fecha < '2025-07-01'
  GROUP BY local_id
),
h1_2026 AS (
  SELECT local_id, SUM(importe_total) AS total
  FROM ventas WHERE fecha >= '2026-01-01' AND fecha < '2026-07-01'
  GROUP BY local_id
)
SELECT l.nombre,
   ROUND(h25.total,2) AS ventas_h1_2025,
   ROUND(h26.total,2) AS ventas_h1_2026,
   ROUND((h26.total - h25.total) / h25.total * 100, 1) AS crecimiento_pct
FROM h1_2025 h25
JOIN h1_2026 h26 ON h25.local_id = h26.local_id
JOIN locales l ON l.local_id = h25.local_id
ORDER BY crecimiento_pct DESC;





