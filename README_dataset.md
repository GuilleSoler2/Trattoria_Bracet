# Dataset — Bracet Trattoria (cadena ficticia de restaurantes italianos)

Cadena ficticia de 6 restaurantes italianos en Barcelona y provincia de Girona,
con 24 meses de histórico (agosto 2024 – julio 2026). Diseñado como base para
un proyecto de portfolio en **Excel → SQL → Power BI**.

## Contexto de negocio (para el storytelling del proyecto)

Bracet Trattoria tiene locales urbanos en Barcelona (demanda estable todo el
año) y locales en la Costa Brava (Blanes, Lloret de Mar, Girona, Figueres) con
fuerte estacionalidad turística. En marzo de 2025 abrió un local nuevo
(Figueres) y en enero de 2025 el local de Gràcia estuvo cerrado tres semanas
por reforma. Estos dos eventos están reflejados en los datos a propósito, para
poder analizarlos (rampa de apertura, caída y recuperación tras una reforma).

## Tablas

### `dim_locales.csv`
| Columna | Descripción |
|---|---|
| local_id | Identificador del restaurante |
| nombre | Nombre del local |
| ciudad / provincia | Ubicación |
| tipo_zona | Urbana / Turística media / Turística alta — define la estacionalidad |
| fecha_apertura | Fecha de apertura del local |
| m2 / capacidad_comensales | Tamaño del local |

### `dim_productos.csv`
| Columna | Descripción |
|---|---|
| producto_id | Identificador del plato/bebida |
| nombre / categoria | Entrantes, Pasta, Pizza, Principales, Pescados, Menú del día, Postres, Bebidas |
| precio_venta | PVP |
| coste_unitario | Coste de materia prima (food cost) |
| margen_pct | Margen bruto calculado |

### `dim_promociones.csv`
Campañas promocionales por fecha, local (vacío = todos) y categoría (vacío =
todas). Incluye una campaña deliberadamente "fallida"
(`Blue Monday -20% Pasta`) que apenas mueve la demanda — para que el análisis
de impacto de promociones no salga siempre positivo.

### `dim_empleados_costes.csv`
Coste de personal mensual simplificado por local (nº empleados y coste
empresa), con refuerzo de plantilla en temporada alta en los locales
turísticos. Sirve para calcular margen operativo, no solo margen bruto.

### `fact_ventas.csv` (tabla de hechos, ~124.000 filas)
| Columna | Descripción |
|---|---|
| venta_id | Identificador de línea de venta |
| fecha | Fecha de la venta |
| local_id | FK a dim_locales |
| producto_id | FK a dim_productos |
| unidades_vendidas | Unidades vendidas ese día de ese producto en ese local |
| precio_unitario_aplicado | Precio aplicado (puede diferir del PVP si había promoción activa) |
| importe_total | Importe de la línea |

## Defectos de calidad incluidos a propósito

Este dataset **no está limpio**, como pasaría con una extracción real de un
TPV. Antes de pasar a SQL/Power BI, la fase de Excel debe detectar y resolver:

- **Duplicados exactos** (~364 filas): filas de venta repetidas.
- **Precio unitario en blanco** (~621 filas): hay que recalcularlo o
  descartarlo según el caso.
- **Unidades negativas** (~186 filas): errores de picking en el TPV.
- **Importes que no cuadran** con `unidades × precio` (~250 filas): fallo de
  cálculo del propio TPV — buen caso para una columna de validación
  (`importe_calculado` vs `importe_total`) y una regla de decisión documentada
  (¿se corrige o se descarta?).
- El local de Gràcia no tiene ventas entre el 20/01/2025 y el 05/02/2025
  (cierre real por reforma, no es un error).
- El local de Figueres no existe antes de marzo de 2025 (apertura real).

## Próximos pasos sugeridos

1. **Excel**: limpieza de los defectos anteriores + tablas dinámicas
   exploratorias (ranking de productos, ventas por local/mes).
2. **SQL**: modelo relacional, consultas de agregación, evolución temporal,
   impacto de promociones, margen por producto/local.
3. **Power BI**: dashboard ejecutivo con KPIs, comparativa entre locales,
   estacionalidad, y página de insights/recomendaciones.
