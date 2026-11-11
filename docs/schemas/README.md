# Contrato de datos del ecosistema Hotelia

> **Versión del esquema: 1**
> Última actualización: 2026-11-11 · Issue #12


Ninguna app habla con otra directamente. El contrato es Firestore, y estas dos
colecciones son el canal por el que fluye el flujo estrella:

```
HoteliaMovil (check-out)  ──escribe──>  /tasks  ──lee──>  hotel-wear-app
                                           │                    │
                                           │              (actualiza status)
                                           │                    │
                                           └────lee────>  hotel-smart-app
```

| App | Repositorio | Rol sobre estas colecciones |
|---|---|---|
| Móvil | `HoteliaApp/HoteliaMovil` | Escribe tareas y alertas; lee para el dashboard |
| Smartwatch | `Manuel-Mata/hotel-wear-app` | Lee tareas y alertas; actualiza `status` y `isAcknowledged` |
| Smart TV | `MonseCastanon/hotel-smart-app` | Solo lectura (tablero Kanban y panel de alertas) |

---

## Reglas generales

1. **camelCase** en todos los nombres de campo. No se usa `snake_case`.
2. **Fechas en texto ISO 8601 UTC**, generadas con `DateTime.toIso8601String()`.
   No se usa `Timestamp` de Firestore ni `FieldValue.serverTimestamp()` en estas
   dos colecciones, porque las tres apps parsean con `DateTime.parse()`.
   Los mappers deben aceptar ambos de todos modos, por tolerancia.
3. **Todo campo declarado como requerido existe siempre**, aunque sea con valor
   vacío (`""`, `0`) o explícitamente `null` cuando el tipo lo admite. No se
   omiten campos: un campo ausente obliga a cada app a inventar un valor por
   defecto distinto, que es el origen de las discrepancias actuales.
4. **El `id` del documento es igual al campo `id`.** Se genera en el cliente con
   el patrón `task-<millisSinceEpoch>` o `alert-<millisSinceEpoch>`.
5. **`schemaVersion` va en todo documento nuevo.** Permite que un consumidor
   detecte documentos viejos y decida si los soporta o los ignora.

---

## Colección `/tasks`

Tareas operativas del personal. Las crea recepción (automáticamente en el
check-out, o manualmente desde el diálogo de alertas) y las consume el reloj.

| Campo | Tipo | Req. | Valores / notas |
|---|---|:---:|---|
| `id` | string | ✓ | Igual al id del documento |
| `roomId` | string | ✓ | Id del documento en `/rooms`. Ej. `"room-201"` |
| `roomNumber` | number (int) | ✓ | Número físico de la habitación. Ej. `201`. **Nunca el `roomId`** |
| `taskType` | string | ✓ | `cleaning` · `maintenance` · `inspection` · `delivery` · `guest_request` |
| `status` | string | ✓ | `pending` · `inProgress` · `completed` · `cancelled` — **camelCase** |
| `description` | string | ✓ | Texto legible para el operario |
| `guestName` | string | ✓ | `""` cuando no aplica |
| `assignedBy` | string | ✓ | UID de quien creó la tarea |
| `assignedByName` | string | ✓ | Nombre legible de quien la creó |
| `assignedTo` | string \| null | ✓ | UID del operario asignado. `null` = sin asignar, visible para todos |
| `priority` | number (int) | ✓ | `1` a `5`. Check-out automático usa `4`; alerta manual usa `5` |
| `createdAt` | string ISO 8601 | ✓ | |
| `completedAt` | string ISO 8601 \| null | ✓ | `null` mientras no se completa |
| `notes` | string \| null | ✓ | Lo escribe el reloj al completar. `null` si no hay |
| `schemaVersion` | number (int) | ✓ | `1` |

### Ciclo de vida de `status`

```
pending ──(reloj: Aceptar)──> inProgress ──(reloj: Completar)──> completed
   │                               │
   └───────────(cancelada)─────────┴──> cancelled
```

Al pasar a `completed`, el escritor **debe** fijar también `completedAt`.

### Ejemplo

```json
{
  "id": "task-1763000000000",
  "roomId": "room-201",
  "roomNumber": 201,
  "taskType": "cleaning",
  "status": "pending",
  "description": "Limpieza post check-out — Hab. 201. Huésped: Juan Pérez",
  "guestName": "Juan Pérez",
  "assignedBy": "SjK2mQ8vXcZ...",
  "assignedByName": "Recepción",
  "assignedTo": null,
  "priority": 4,
  "createdAt": "2026-11-11T18:05:00.000Z",
  "completedAt": null,
  "notes": null,
  "schemaVersion": 1
}
```

---

## Colección `/alerts`

Avisos que recepción manda al reloj y que la Smart TV muestra en su panel
superior. Una alerta **siempre** acompaña a una tarea: `taskId` apunta al
documento de `/tasks` que se creó junto con ella.

| Campo | Tipo | Req. | Valores / notas |
|---|---|:---:|---|
| `id` | string | ✓ | Igual al id del documento |
| `taskId` | string | ✓ | Id de la tarea asociada en `/tasks` |
| `title` | string | ✓ | Ej. `"Mantenimiento — Hab. 201"` |
| `message` | string | ✓ | Ej. `"Hab. 201: fuga en el lavabo"` |
| `severity` | string | ✓ | `low` · `medium` · `high` · `urgent` |
| `priority` | number (int) | ✓ | `1` a `5`. Debe coincidir con la tarea asociada |
| `roomId` | string | ✓ | Id del documento en `/rooms` |
| `roomNumber` | number (int) | ✓ | Número físico. **Nunca el `roomId`** |
| `assignedBy` | string | ✓ | UID de quien la generó |
| `assignedByName` | string | ✓ | Nombre legible |
| `createdAt` | string ISO 8601 | ✓ | |
| `isAcknowledged` | boolean | ✓ | `true` cuando el reloj la reconoce |
| `acknowledgedAt` | string ISO 8601 \| null | ✓ | `null` mientras no se reconoce |
| `schemaVersion` | number (int) | ✓ | `1` |

### Correspondencia entre `priority` y `severity`

Son dos vistas del mismo dato. `priority` es el valor canónico; `severity` se
deriva de él para que el reloj y la TV puedan colorear sin hacer aritmética:

| `priority` | `severity` |
|:---:|---|
| 1 – 2 | `low` |
| 3 | `medium` |
| 4 | `high` |
| 5 | `urgent` |

---

## Discrepancias que este contrato corrige

Estado anterior a la issue #12, verificado en los tres repositorios:

| # | Síntoma | Causa |
|---|---|---|
| 1 | El reloj muestra siempre "Sin asignar" | Lee `assignedTo`, que el móvil nunca escribía |
| 2 | La TV muestra "Hab. room-201" en el panel de alertas | `/alerts` no traía `roomNumber`, y el modelo caía al `roomId` |
| 3 | La TV no puede ordenar por urgencia | `/alerts` no traía `priority` |
| 4 | El reloj no muestra el título de la alerta | El modelo del reloj no lee `title` |
| 5 | Riesgo de excepción al parsear fechas | Los mappers hacen `DateTime.parse()` directo; un `Timestamp` los rompe |
| 6 | Imposible distinguir documentos viejos | No existía `schemaVersion` |

---

## Versión 2 — reservada para la issue #24 (multi-inquilino)

Declarada aquí para que el trabajo de Fase 2 pueda construirse contra un
contrato cerrado sin esperar a la migración.

La v2 **agrega** los siguientes campos a `/tasks` y `/alerts`, sin quitar ni
renombrar ninguno de los actuales:

| Campo | Tipo | Notas |
|---|---|---|
| `hotelId` | string | Id del hotel propietario del documento. Ej. `"hotel_valle_01"` |
| `schemaVersion` | number | Pasa a `2` |

Y se incorpora la colección de inquilinos:

### Colección `/hotels`

| Campo | Tipo | Req. | Notas |
|---|---|:---:|---|
| `id` | string | ✓ | Igual al id del documento |
| `name` | string | ✓ | Nombre comercial del hotel |
| `floors` | number (int) | ✓ | Número de pisos |
| `address` | string | ✓ | |
| `createdAt` | string ISO 8601 | ✓ | |
| `plan` | string | ✓ | `basic` · `standard` · `premium` |
| `schemaVersion` | number | ✓ | `2` |

El documento de empleado en `/users` incorpora `hotelId` (string), que es el
que determina a qué inquilino pertenece cada sesión.

> **Nota sobre la nota técnica de la issue.** El plan pide "un mapper compartido
> en Kotlin (Wear OS) y Dart (Flutter)". El wearable no está escrito en Kotlin
> sino en Flutter, igual que las otras dos apps, por lo que no hay dos lenguajes
> que reconciliar. Lo que se entrega en su lugar es este contrato más los tres
> mappers de Dart alineados a él, uno por repositorio.