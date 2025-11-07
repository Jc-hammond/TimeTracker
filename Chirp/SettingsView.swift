//
//  SettingsView.swift
//  Chirp
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.spacious) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .padding(.top, DesignSystem.Spacing.dramatic)

            Text("Settings")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.primaryText)

            Text("Coming soon...")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.secondaryBackground)
    }
}
