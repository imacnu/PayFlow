//
//  AccountAuthSheet.swift
//  Subscription Guardian
//
//  Hoja de registro e inicio de sesión accesible desde Ajustes:
//  Apple, Google y correo electrónico con contraseña.
//

import SwiftUI
import AuthenticationServices

struct AccountAuthSheet: View {
    @Environment(\.dependencies) private var deps
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AuthViewModel()

    /// Modo del formulario de correo: inicio de sesión o registro.
    private enum Mode: Hashable {
        case login, register
    }

    @State private var mode: Mode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""

    private var isFormValid: Bool {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty, !password.isEmpty else {
            return false
        }
        return mode == .login || !confirmation.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                providersSection
                emailSection
            }
            .scrollContentBackground(.hidden)
            .appBackground()
            .navigationTitle(Text("auth.sheet.title", comment: "Tu cuenta"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancelar")) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            viewModel.configure(deps: deps)
        }
    }

    // MARK: - Secciones

    private var providersSection: some View {
        Section {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                viewModel.handleAppleResult(result)
                if case .apple? = deps?.session.state { dismiss() }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 48)
            .clipShape(Capsule())
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            if AppConfig.googleSignInEnabled {
                Button {
                    Task {
                        await viewModel.signInWithGoogle()
                        if case .google? = deps?.session.state { dismiss() }
                    }
                } label: {
                    HStack(spacing: AppSpacing.s) {
                        Image(systemName: "globe")
                        Text(String(localized: "auth.google", defaultValue: "Continuar con Google"))
                    }
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 26)
                }
                .disabled(viewModel.isSigningIn)
            }
        }
    }

    private var emailSection: some View {
        Section {
            Picker("", selection: $mode) {
                Text("auth.mode.login", comment: "Iniciar sesión").tag(Mode.login)
                Text("auth.mode.register", comment: "Registrarse").tag(Mode.register)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            TextField(
                String(localized: "auth.email", defaultValue: "Correo electrónico"),
                text: $email
            )
            .keyboardType(.emailAddress)
            .textContentType(.username)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            // Sin textContentType de contraseña: el overlay de "contraseña
            // segura" de iOS bloquea la escritura en estos campos.
            SecureField(
                String(localized: "auth.password", defaultValue: "Contraseña"),
                text: $password
            )

            if mode == .register {
                SecureField(
                    String(localized: "auth.confirmPassword", defaultValue: "Repite la contraseña"),
                    text: $confirmation
                )
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                submit()
            } label: {
                Text(
                    mode == .login
                        ? String(localized: "auth.submit.login", defaultValue: "Entrar")
                        : String(localized: "auth.submit.register", defaultValue: "Crear cuenta")
                )
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .disabled(!isFormValid)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        } header: {
            Text("auth.orEmail", comment: "O con tu correo")
        } footer: {
            Text(
                "auth.localNote",
                comment: "Tu cuenta se guarda de forma segura en este dispositivo."
            )
        }
    }

    // MARK: - Acciones

    private func submit() {
        // Defensivo: garantiza las dependencias aunque `.task` no haya corrido.
        viewModel.configure(deps: deps)
        let success = mode == .login
            ? viewModel.signInWithEmail(email: email, password: password)
            : viewModel.register(email: email, password: password, confirmation: confirmation)
        if success { dismiss() }
    }
}

#Preview {
    AccountAuthSheet()
        .environment(\.dependencies, AppDependencies.preview())
}
