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

    var body: some View {
        NavigationStack {
            Form {
                accountSection
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
        case .guest?:
            return String(localized: "settings.provider.guest", defaultValue: "Invitado")
        default:
            return ""
        }
    }

    private var premiumSection: some View {
        Section(String(localized: "settings.premium", defaultValue: "Premium")) {
            if viewModel.isPremium {
                HStack {
                    Text("settings.premium.status", comment: "Estado de la suscripción")
                    Spacer()
                    PillBadge(text: "Premium", tint: .electricBlue)
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
                        PillBadge(text: "Premium", tint: .electricBlue)
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
