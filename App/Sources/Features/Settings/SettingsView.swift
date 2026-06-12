//
//  SettingsView.swift
//  Subscription Guardian
//
//  Ajustes: cuenta, premium, datos (iCloud y exportación), notificaciones
//  y acerca de.
//

import SwiftUI
import SubscriptionGuardianCore

struct SettingsView: View {
    @Environment(\.dependencies) private var deps

    @State private var viewModel = SettingsViewModel()
    @State private var showPaywall = false
    @State private var showSignOutConfirmation = false
    @State private var showAccountSheet = false

    /// Preferencias de apariencia e idioma persistidas en UserDefaults.
    @AppStorage(AppAppearance.storageKey) private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                preferencesSection
                premiumSection
                dataSection
                notificationsSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .appBackground()
            .navigationTitle(Text("settings.title", comment: "Ajustes"))
            .sheet(isPresented: $showPaywall, onDismiss: { viewModel.load() }) {
                PaywallView()
            }
            .sheet(isPresented: $showAccountSheet, onDismiss: { viewModel.load() }) {
                AccountAuthSheet()
            }
            .confirmationDialog(
                String(localized: "settings.signOut.confirm", defaultValue: "¿Cerrar sesión?"),
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    String(localized: "settings.signOut", defaultValue: "Cerrar sesión"),
                    role: .destructive
                ) {
                    viewModel.signOut()
                }
            }
        }
        .task {
            viewModel.configure(deps: deps)
            viewModel.load()
        }
    }

    // MARK: - Secciones

    private var accountSection: some View {
        Section(String(localized: "settings.account", defaultValue: "Cuenta")) {
            HStack(spacing: AppSpacing.m) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(LinearGradient.appAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.session?.displayName ?? "")
                        .font(.subheadline.bold())
                    Text(providerLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.session?.state == .guest {
                Text(
                    "settings.guestHint",
                    comment: "Sugerencia para crear cuenta desde modo invitado"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Button {
                    showAccountSheet = true
                } label: {
                    Label(
                        String(
                            localized: "settings.account.signIn",
                            defaultValue: "Iniciar sesión o crear cuenta"
                        ),
                        systemImage: "person.badge.key.fill"
                    )
                }
            }

            Button(role: .destructive) {
                showSignOutConfirmation = true
            } label: {
                Text("settings.signOut", comment: "Cerrar sesión")
            }
        }
    }

    private var providerLabel: String {
        switch viewModel.session?.state {
        case .apple?:
            return "Apple"
        case .google?:
            return "Google"
        case .email?:
            return String(localized: "settings.provider.email", defaultValue: "Correo electrónico")
        case .guest?:
            return String(localized: "settings.provider.guest", defaultValue: "Invitado")
        default:
            return ""
        }
    }

    /// Preferencias de la app: apariencia e idioma de la interfaz.
    private var preferencesSection: some View {
        Section {
            Picker(
                String(localized: "settings.appearance", defaultValue: "Apariencia"),
                selection: $appearanceRaw
            ) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(appearance.localizedName).tag(appearance.rawValue)
                }
            }

            // El cambio de idioma lo aplica SubscriptionGuardianApp al
            // observar esta preferencia (override del bundle + re-render).
            Picker(
                String(localized: "settings.language", defaultValue: "Idioma"),
                selection: $languageRaw
            ) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language.rawValue)
                }
            }
        } header: {
            Text("settings.preferences", comment: "Preferencias")
        } footer: {
            Text(
                "settings.language.footer",
                comment: "El cambio de idioma se aplica al instante."
            )
        }
    }

    private var premiumSection: some View {
        Section(String(localized: "settings.premium", defaultValue: "Premium")) {
            if viewModel.isPremium {
                HStack {
                    Text("settings.premium.status", comment: "Estado de la suscripción")
                    Spacer()
                    PillBadge(text: "Premium", tint: .appCyan)
                }
            } else {
                LabeledContent(
                    String(localized: "settings.premium.usage", defaultValue: "Plan gratuito")
                ) {
                    Text(viewModel.usageDescription)
                        .font(.caption)
                }

                Button {
                    showPaywall = true
                } label: {
                    Label(
                        String(localized: "settings.premium.upgrade", defaultValue: "Hazte Premium"),
                        systemImage: "crown.fill"
                    )
                }
            }
        }
    }

    private var dataSection: some View {
        Section(String(localized: "settings.data", defaultValue: "Datos")) {
            LabeledContent(
                String(localized: "settings.icloud", defaultValue: "Sincronización iCloud")
            ) {
                Text(
                    AppConfig.cloudKitEnabled
                        ? String(localized: "settings.icloud.on", defaultValue: "Activada")
                        : String(localized: "settings.icloud.off", defaultValue: "Desactivada (ver README)")
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if viewModel.isPremium {
                Button {
                    viewModel.prepareExport()
                } label: {
                    Label(
                        String(localized: "settings.exportCSV", defaultValue: "Exportar CSV"),
                        systemImage: "square.and.arrow.up"
                    )
                }

                if let url = viewModel.exportURL {
                    ShareLink(item: url) {
                        Label(
                            String(localized: "settings.shareCSV", defaultValue: "Compartir exportación"),
                            systemImage: "doc.text"
                        )
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label(
                            String(localized: "settings.exportCSV", defaultValue: "Exportar CSV"),
                            systemImage: "square.and.arrow.up"
                        )
                        Spacer()
                        PillBadge(text: "Premium", tint: .appCyan)
                    }
                }
            }
        }
    }

    private var notificationsSection: some View {
        Section(String(localized: "settings.notifications", defaultValue: "Notificaciones")) {
            Button {
                viewModel.requestNotificationPermission()
            } label: {
                Label(
                    String(
                        localized: "settings.notifications.allow",
                        defaultValue: "Permitir notificaciones"
                    ),
                    systemImage: "bell.badge"
                )
            }
        }
    }

    private var aboutSection: some View {
        Section(String(localized: "settings.about", defaultValue: "Acerca de")) {
            LabeledContent(
                String(localized: "settings.version", defaultValue: "Versión")
            ) {
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")
            }
            Link(
                String(localized: "settings.privacy", defaultValue: "Política de privacidad"),
                destination: URL(string: "https://example.com/privacy")!
            )
            Link(
                String(localized: "settings.terms", defaultValue: "Términos de uso"),
                destination: URL(string: "https://example.com/terms")!
            )
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.dependencies, AppDependencies.preview())
}
