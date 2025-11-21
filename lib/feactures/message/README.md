# Feature: Message (HTTP-Only)

Este feature maneja el envío, recepción y almacenamiento de mensajes en conversaciones entre usuarios y bots usando únicamente HTTP REST API.

## Arquitectura

### Estructura del Feature
```
message/
├── data/
│   ├── datasource/
│   │   ├── message_remote_datasource.dart    # HTTP API para mensajes
│   │   └── local_message_datasource.dart     # Persistencia local SQLite
│   └── repository_impl/
│       └── message_repository_impl.dart      # Implementación del repositorio
├── domain/
│   ├── entities/
│   │   └── message_entity.dart               # Entidad de mensaje
│   └── repository/
│       └── message_repository.dart           # Interfaz del repositorio
└── presentation/
    ├── bloc/
    │   ├── message_bloc.dart                 # Lógica de estado
    │   ├── message_event.dart                # Eventos
    │   └── message_state.dart                # Estados
    └── ui/
        └── pages/
            └── message_page.dart             # UI de chat
```

## Funcionamiento (HTTP-Only)

### Envío de Mensajes (HTTP POST)

**Endpoint:** `POST /messages/send`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer {jwtToken}"  // Opcional para usuarios autenticados
}
```

**Body enviado:**
```json
{
  "conversationId": "string",     // ID de la conversación
  "session_token": "string",      // Token de sesión (para usuarios anónimos)
  "sender": "string",             // ID del usuario o "user" para anónimos
  "content": "string"             // Contenido del mensaje
}
```

### Estructura de Respuesta Esperada

El servidor debe responder con la siguiente estructura JSON:

```json
{
  "success": true,
  "userMessage": {
    "id": "uuid-mensaje-usuario",
    "content": "Hola, tengo una pregunta",
    "sender": "user",
    "conversationId": "uuid-conversacion",
    "created_at": "2025-11-21T10:30:00.000Z"
  },
  "botResponse": {
    "id": "uuid-respuesta-bot", 
    "content": "¡Hola! ¿En qué puedo ayudarte?",
    "sender": "bot",
    "conversationId": "uuid-conversacion",
    "created_at": "2025-11-21T10:30:01.000Z"
  }
}
```

### Campos de MessageEntity

```dart
class MessageEntity {
  final String id;              // ID único del mensaje
  final String content;         // Contenido del mensaje
  final String sender;          // Remitente ("user", "bot", userId)
  final DateTime created_at;    // Timestamp de creación
  final String? senderId;       // ID del remitente (opcional)
  final String? externalId;     // ID externo (opcional)
  final String? sessionId;      // ID de sesión (opcional)
  final String? n8nMessage;     // Mensaje de n8n (opcional)
}
```

### Recepción de Mensajes (HTTP GET)

**Endpoint:** `GET /conversation/{conversationId}/message`

**Headers:**
```json
{
  "Authorization": "Bearer {token}"
}
```

**Respuesta esperada:**
```json
[
  {
    "id": "string",
    "content": "string", 
    "sender": "string",
    "created_at": "ISO8601_string",
    "sender_id": "string",        // Opcional
    "external_id": "string",      // Opcional
    "session_id": "string",       // Opcional
    "n8n_message": "string"       // Opcional
  }
]
```

## Flujo de Datos (HTTP-Only)

1. **Usuario escribe mensaje** → `MessageBloc.SendMessageEvent`
2. **MessageBloc** → `MessageRepository.sendMessage()`
3. **Repository** usa **HTTP POST** → `MessageRemoteDataSource.sendMessage()`
4. **Respuesta del servidor** procesada → retorna `Map<String, MessageEntity>`
   - `"userMessage"`: El mensaje enviado por el usuario
   - `"botResponse"`: La respuesta automática del bot
5. **Persistencia local** → ambos mensajes se guardan en SQLite
6. **UI actualizada** → muestra ambos mensajes en el chat

## Características

- **HTTP-Only**: Sin conexiones WebSocket o Socket.IO
- **Polling para actualizaciones**: Usar `getListMessages()` periódicamente para nuevos mensajes
- **Sin tiempo real**: Los mensajes no aparecen instantáneamente
- **Optimistic UI**: Mostrar mensajes localmente antes de confirmación del servidor

## Autenticación

- **Usuarios autenticados**: Bearer Token en Authorization header
- **Usuarios anónimos**: session_token en el body del request
- **Fallback**: si no hay token, usa session_token del SessionManager

## Persistencia

- **Remoto**: HTTP API únicamente
- **Local**: SQLite para offline y cache
- **Temporal**: SessionManager para estado en memoria
- **Sin tiempo real**: Usar polling para actualizaciones
