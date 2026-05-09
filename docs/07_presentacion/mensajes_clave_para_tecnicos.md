# Mensajes Clave para Tecnicos

## Proposito

Registrar explicaciones breves y tecnicamente defendibles para audiencia interna no autora del proyecto.

## Mensajes semilla

- `k-anonymity` es piso necesario, no garantia suficiente.
- el MVP actual implementa `k-anonymity` y controles heuristicos de bloqueo, pero no `l-diversity` ni `t-closeness`.
- remover nombre o documento no basta cuando el tercero ya conoce muchas variables descriptivas.
- una herramienta seria debe poder bloquear y explicar por que bloquea.
- la utilidad analitica se preserva solo dentro del margen compatible con la proteccion de datos.
- el resumen de auditoria debe traducir evidencia tecnica a una conclusion operativa defendible, no limitarse a imprimir un log interno.
- generar codigo R para reproducir transformaciones no equivale a aprobar una liberacion externa.
