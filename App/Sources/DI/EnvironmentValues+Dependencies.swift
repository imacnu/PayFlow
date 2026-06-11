import SwiftUI

extension EnvironmentValues {
    /// Dependencias de la app inyectadas en el entorno. Opcional para evitar
    /// construir contenedores como valor por defecto del entorno.
    @Entry var dependencies: AppDependencies? = nil
}
