import SwiftUI

/// Vista raíz: decide entre la pantalla de autenticación y las pestañas
/// principales según el estado de la sesión.
struct RootView: View {
    @Environment(\.dependencies) private var dependencies

    var body: some View {
        if let deps = dependencies {
            content(deps)
        } else {
            // Defensivo: nunca debería ocurrir, la app inyecta las dependencias.
            ProgressView()
        }
    }

    @ViewBuilder
    private func content(_ deps: AppDependencies) -> some View {
        Group {
            switch deps.session.state {
            case .signedOut:
                AuthLandingView()
            case .guest, .apple, .google, .email:
                MainTabView()
            }
        }
        .animation(.spring, value: deps.session.state)
    }
}
