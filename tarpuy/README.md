# TARPUY

**Inteligencia agrícola para sembrar hoy, regenerar mañana.**

Proyecto web independiente creado en `tarpuy/`. El proyecto Flutter anterior, en la carpeta superior, no se modifica ni se importa. Se conserva Flutter/Dart porque ya está instalado en el entorno y el prompt solicita conservar las tecnologías configuradas. No requiere Node, claves NASA ni paquetes de mapas adicionales.

## Ejecutar la aplicación completa

Requisitos: Flutter estable compatible con Dart 3.12, conexión para NASA y OpenStreetMap.

Desde esta carpeta:

```powershell
flutter pub get
flutter build web --no-web-resources-cdn
dart run server/server.dart
```

Abrir **http://localhost:8787**. El servidor sirve el frontend y `/api/power` en el mismo origen. Se enlaza únicamente a la interfaz local del equipo. Detener con Ctrl+C.

Para desarrollo con recarga, usar dos terminales:

```powershell
# Terminal 1, en tarpuy/
dart run server/server.dart
```

```powershell
# Terminal 2, en tarpuy/
flutter run -d chrome --web-port 8080 --dart-define=POWER_PROXY=http://localhost:8787/api/power
```

No ejecutar estos comandos desde el proyecto padre: allí sigue existiendo la aplicación anterior.

En VS Code puedes abrir `TARPUY.code-workspace` para trabajar solo con esta aplicación. Incluye una tarea para iniciar el servidor NASA y una configuración de depuración de Chrome; inicia primero la tarea del servidor.

## Recorrido funcional

1. Abrir **Mi terreno**. Mover el mapa y hacer clic para marcar coordenadas, o escribirlas. La vista inicial de Cusco es una referencia, no una parcela precargada.
2. Completar ubicación administrativa, superficie y agua; añadir altitud y resultados de laboratorio solo si se conocen. Guardar.
3. En **Observación NASA**, seleccionar fechas y consultar POWER. El rango inicial termina siete días antes para evitar parte de la latencia de publicación. Si un dato no llega, se conserva como ausente.
4. Consultar la serie diaria y la agregación por mes. Copiar CSV con procedencia desde el panel NASA.
5. Explorar el **Calendario agrícola**, registrar actividades y marcarlas completadas. El catálogo se filtra por altitud; las ventanas son heurísticas explícitas de agua y altura, pendientes de validación agronómica regional.
6. Diseñar y guardar una secuencia en **Simulador de rotación**; comparar sus índices con un monocultivo y consultar sus supuestos en pantalla.
7. Abrir **Impacto ambiental** para revisar el escenario guardado. Los valores son simulados y no certifican impacto.
8. En **Economía agrícola**, introducir cotizaciones y costos propios. No hay precios actuales precargados. Las comparaciones y el historial son locales.
9. Consultar prácticas regenerativas, efemérides aproximadas y el asistente por reglas.

## Funcionalidad y límites por fase del prompt

| Fase | Implementado | Pendiente |
|---|---|---|
| 1 | Identidad visual andina, dashboard, diez secciones, navegación adaptable, carga/errores/vacíos | Verificación visual en navegador real |
| 2 | Registro editable, mapa de punto con desplazamiento/zoom, coordenadas, agua, cultivo anterior, pH/materia orgánica opcionales, persistencia, copia/restauración JSON | Dibujo de polígonos, geocodificación y verificación administrativa; sincronización multiusuario |
| 3 | Conector real POWER, backend separado, validación, normalización, caché 6 h y solicitudes compartidas, gráficos y CSV | Caché distribuida/persistente para producción; alertas y pronósticos |
| 4 | Calendario enero–diciembre, agenda persistida, catálogo, filtro de altitud, ciclos/agua/nutrición/cosecha ilustrativos | Calendarios y variedades validados por distrito y ajuste climático calibrado |
| 5 | Secuencias editables y horizontes 3/5/10 años, comparación cuantitativa, supuestos visibles, persistencia | Modelos agronómicos validados, rendimientos, balance real de N/agua/carbono |
| 6 | Adaptadores independientes y fichas SMAP/GPM/MODIS/HLS, con estado pendiente real | Autenticación Earthdata, descarga/procesamiento, NDVI, mapas temáticos, SRTM y GLDAS |
| 7 | Economía con datos propios, mercados local/nacional/internacional, asistente contextual por reglas | Conectores MIDAGRI/SISAP, demanda/precios oficiales, proveedor de IA generativa |
| 8 | Comparación ambiental didáctica, pruebas y esquema Supabase con RLS | Medición y validación de impacto, aplicación de migraciones en una base real, autenticación y operación de producción |

Es un MVP funcional, no una integración completa de las ocho fases. En particular, las fichas de fuentes pendientes no se presentan como conexiones terminadas.

## Fuentes realmente utilizadas

- **NASA POWER**: solicitudes HTTP reales al endpoint diario oficial, ejecutadas por `server/server.dart` bajo demanda. No se sustituye una respuesta fallida por datos de ejemplo. Parámetros: `T2M`, `T2M_MAX`, `T2M_MIN`, `PRECTOTCORR`, `RH2M`, `ALLSKY_SFC_SW_DWN`; comunidad `AG`, formato JSON y estándar UTC. El conector conserva las unidades de la respuesta. Las estimaciones regionales no son mediciones puntuales del agricultor.
- **OpenStreetMap**: teselas cartográficas bajo demanda. No es una imagen satelital ni una capa NASA. La atribución permanece visible. Para despliegue con tráfico, seleccionar un proveedor de teselas y cumplir sus condiciones; no se realizan descargas masivas ni precarga de áreas.
- **NOAA**: cálculo local aproximado de amanecer/atardecer basado en sus ecuaciones publicadas; no se consulta una API NOAA.

Las demás fuentes tienen adaptadores que fallan explícitamente como no implementados; no realizan consultas ficticias.

## Procedencia y tipos de datos

Cada medición normalizada contiene `datasetId`, `provider`, `variable`, `value`, `unit`, `latitude`, `longitude`, `spatialResolution`, `temporalResolution`, `observationDate`, `fetchedAt`, `type`, `qualityFlag` y `sourceUrl`. El backend conserva su fecha de consulta incluso al responder desde caché. POWER se etiqueta **estimado regional** por precaución: integra productos meteorológicos y satelitales, sin ser un sensor local. Los valores `fill_value`/`-999` pasan a `null`.

No hay series ambientales ni precios de demostración precargados. El plan inicial papa → haba → quinua es una **secuencia ilustrativa editable**, no una recomendación personalizada. Los coeficientes del simulador son supuestos didácticos visibles, no parámetros calibrados. El catálogo de cultivos es orientativo y requiere validación regional antes de usarse para decisiones productivas. El asistente es un motor determinista, no un LLM.

El registro del agricultor no se certifica como medición de laboratorio: la interfaz indica que es aportado. El esquema de base de datos reserva campos para origen y laboratorio. Las regiones naturales bajas no se determinan solamente por altura: se solicita confirmar la vertiente.

## Arquitectura

```text
lib/
  main.dart                   tema, navegación y estructura adaptable
  data/
    models.dart               parcela, cultivos, rotación y reglas de orientación
    app_state.dart            estado, tareas, caché de sesión y persistencia
    storage*.dart             localStorage web / memoria en pruebas
  services/
    nasa/power.dart            consulta y contrato uniforme de observación
    nasa/{smap,gpm,modis,landsat,source}.dart
    astronomy.dart            cálculo solar NOAA y ciclo lunar aproximado
  ui/
    dashboard.dart            panel principal
    plot_screen.dart          registro y respaldo de parcela
    modules.dart              calendario, simulación y otros módulos
    widgets.dart              componentes, mapa y gráfico
server/server.dart            proxy NASA, caché acotada y archivos estáticos
supabase/migrations/001_initial.sql
test/                         dominio, servicios/backend e interfaz
```

El mapa usa proyección Web Mercator y teselas estándar. Los gráficos se dibujan con Flutter y mantienen huecos cuando faltan observaciones. El proxy permite un máximo de 366 días de intervalo y no acepta un endpoint arbitrario del cliente. Caché en memoria: hasta 128 consultas, seis horas; se pierde al reiniciar el proceso. Los registros del usuario permanecen en localStorage de este origen/navegador y pueden perderse al borrar datos del sitio. No hay cuentas, sincronización ni credenciales incrustadas.

## Variables de entorno

Ver `.env.example`. No se carga automáticamente un archivo `.env`.

| Variable | Uso |
|---|---|
| `PORT` | Entorno del proceso Dart; por defecto `8787` |
| `POWER_PROXY` | Compilación Flutter con `--dart-define`; por defecto `/api/power` |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Reservadas para la futura integración; esta versión no las consume |

POWER no requiere una clave. No se ha conectado Earthdata ni un proveedor de IA. Sus futuras credenciales deben permanecer en servidor. Para otro puerto en PowerShell: `$env:PORT='8790'` antes de ejecutar Dart.

## Base de datos preparada

La migración es para un **nuevo proyecto Supabase**, no se ha ejecutado. Incluye perfiles vinculados a `auth.users`, parcelas, ubicaciones/geométricas, análisis de suelo, cultivos, historial de siembra, rotaciones, recomendaciones, observaciones, precios y simulaciones. Las vistas meteorológicas y satelitales heredan RLS mediante `security_invoker`. Las referencias compuestas impiden asociar datos a parcelas de otro propietario. La restricción única de observaciones facilita `upsert` sin duplicar series.

La aplicación usa almacenamiento local; para conectar Supabase faltan autenticación, repositorios de persistencia, migración de registros y pruebas de aislamiento de usuarios sobre una instancia real. No hace falta Supabase para probar el MVP.

## Verificación

```powershell
flutter analyze
flutter test --reporter expanded
flutter build web --no-web-resources-cdn
```

Las pruebas de NASA usan fixtures aisladas y clientes HTTP falsos para verificar faltantes, unidades, caché, solicitudes simultáneas, reintentos y validación. Nunca aparecen como mediciones en la interfaz. Los tests de widgets comprueban navegación de los diez módulos, tamaños de escritorio/móvil y validación de campos vacíos. Los cálculos de simulación y astronomía tienen pruebas de dominio.

Resultado verificado el 14 de noviembre de 2026: analizador sin incidencias, **17 pruebas aprobadas** y compilación web de producción generada. Se verificó además el conector real con `dart run tool/verify_power.dart`: tres días de enero de 2025 para Cusco, 18 valores válidos y radiación devuelta en `MJ/m^2/day`. Son observaciones históricas consultadas para verificar el conector, no datos actuales precargados. No se realizó una inspección visual en un navegador real; las comprobaciones de interfaz son pruebas de widgets en escritorio y móvil.

La aplicación compilada respondió HTTP 200 desde el servidor integrado. La consulta NASA a través de `/api/power` respondió correctamente y la segunda solicitud conservó la fecha de consulta desde caché. El servidor de verificación se detuvo al terminar; usa los comandos de ejecución para volver a iniciarlo.

## Documentación consultada

- NASA POWER Daily API: https://power.larc.nasa.gov/docs/services/api/temporal/daily/
- SMAP SPL3SMP_E v6 (referencia): https://nsidc.org/data/spl3smp_e/versions/6
- GPM IMERG: https://gpm.nasa.gov/data/imerg
- HLS: https://hls.gsfc.nasa.gov/products-description/
- NOAA, ecuaciones solares: https://gml.noaa.gov/grad/solcalc/solareqns.PDF
- MOD13Q1: https://lpdaac.usgs.gov/products/mod13q1v061/ (el acceso documental devolvió 403 en este entorno; ficha conservada como referencia pendiente de verificación antes de integrar).

El texto adjunto describe varias fuentes sin conservar sus hipervínculos originales. Se utilizaron las páginas oficiales identificables, sin afirmar haber recuperado enlaces ausentes. Versiones, resoluciones y permisos deben verificarse otra vez al implementar cada conector satelital.
