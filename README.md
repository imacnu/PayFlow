# Subscription Guardian

Aplicación nativa para iPhone que ayuda a controlar y optimizar todos tus gastos
recurrentes: suscripciones digitales, streaming, SaaS personales, gimnasios,
seguros, membresías y financiaciones Buy Now Pay Later (BNPL).

- **Plataforma**: iOS 26+, Swift 6, SwiftUI, Observation, SwiftData, CloudKit,
  WidgetKit, App Intents, StoreKit 2.
- **Arquitectura**: MVVM + Repository + inyección de dependencias por entorno +
  async/await + lógica de negocio aislada en un paquete Swift local.
- **Diseño**: lenguaje Liquid Glass (translucidez, blur dinámico, profundidad),
  modo claro y oscuro, paleta azul eléctrico / cian / blanco cristal / grafito.

## Estructura del repositorio

```
project.yml                          Definición del proyecto (XcodeGen)
Packages/SubscriptionGuardianCore/   Lógica pura (cálculos, insights, recordatorios) + tests
App/Sources/                         App principal
  Config/                            AppConfig (placeholders) y catálogo de servicios
  Models/                            Modelos SwiftData compatibles con CloudKit
  Repositories/                      Protocolos + implementaciones SwiftData
  Services/                          Sesión, StoreKit, notificaciones, CSV, snapshot widgets
  DI/                                AppDependencies + EnvironmentKey
  DesignSystem/                      Componentes Liquid Glass reutilizables
  Features/                          Auth, Dashboard, Subscriptions, Financing,
                                     Calendar, Insights, Notifications, Paywall, Settings
  Intents/                           App Intents + Shortcuts (Siri / Apple Intelligence)
Widgets/Sources/                     Extensión WidgetKit (small/medium/large + lock screen)
```

## Puesta en marcha (macOS)

Requisitos: Xcode 26+, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
cd PayFlow
xcodegen generate
open SubscriptionGuardian.xcodeproj
```

1. En *Signing & Capabilities*, selecciona tu equipo (o rellena
   `DEVELOPMENT_TEAM` en `project.yml` y regenera).
2. Cambia el prefijo de bundle `com.example` en `project.yml` por el tuyo y
   actualiza en consecuencia:
   - `App/SubscriptionGuardian.entitlements` (contenedor iCloud y App Group)
   - `Widgets/SubscriptionGuardianWidgets.entitlements` (App Group)
   - `App/Sources/Config/AppConfig.swift` (`cloudKitContainerID`, `appGroupID`)
   - `Widgets/Sources/WidgetConfig.swift` (debe coincidir con `AppConfig`)
3. Ejecuta los tests de la lógica de negocio:

```bash
cd Packages/SubscriptionGuardianCore
swift test
```

La app compila y funciona de inmediato en el simulador: CloudKit y Google
Sign In vienen **desactivados por defecto** mediante flags en `AppConfig`.

## Activar servicios opcionales

### Sincronización iCloud (CloudKit)

1. Crea el contenedor CloudKit en el portal de desarrollador con el mismo
   identificador que pongas en los entitlements.
2. Pon `AppConfig.cloudKitEnabled = true`.
3. Si el dispositivo no tiene sesión de iCloud, la app cae automáticamente a
   almacenamiento local (sin pérdida de funcionalidad).

### Google Sign In

1. Crea un OAuth Client ID de iOS en Google Cloud Console.
2. En `project.yml`, sustituye `GIDClientID` y el esquema de URL invertido
   (`com.googleusercontent.apps.…`) y regenera el proyecto.
3. Pon `AppConfig.googleSignInEnabled = true`.

### Compras (Premium)

- Para probar en local: selecciona `App/Resources/Products.storekit` en el
  esquema de Xcode (*Run → Options → StoreKit Configuration*).
- Para producción: crea en App Store Connect las suscripciones
  `sg.premium.monthly` (2,99 €/mes) y `sg.premium.yearly` (24,99 €/año).

Límites del plan gratuito: 15 suscripciones y 5 financiaciones
(`AppConfig.freeSubscriptionLimit` / `freeFinancingLimit`).

## Liquid Glass

Todo el estilo "glass" pasa por un único punto:
`App/Sources/DesignSystem/GlassSurface.swift`. La implementación activa usa
materiales (`ultraThinMaterial`) y funciona en cualquier iOS reciente; el
archivo incluye, comentada, la línea equivalente con la API nativa
`glassEffect` de iOS 26 para cambiarla cuando compiles con el SDK final.

## Solución de problemas

- **La extensión de widgets no se embebe**: según la versión de XcodeGen puede
  ser necesario marcar la dependencia como `embed: true` en `project.yml`.
- **Error al arrancar con CloudKit activado**: comprueba que el contenedor
  existe y que hay sesión de iCloud; la app registra el error y arranca en
  modo local.
- **Los widgets muestran datos de ejemplo**: abre la app al menos una vez para
  que publique el snapshot en el App Group.

## Hoja de ruta

- App para Apple Watch (próximos pagos, resumen mensual, alertas).
- Insights generados con Apple Intelligence.
- Detección automática de subidas de precio por proveedor.
