//
//  Category.swift
//  Chirp
//
//  Created on 11/7/25.
//

import Foundation
import SwiftUI

enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case building = "Building"
    case content = "Content"
    case marketing = "Marketing"
    case design = "Design"
    case customer = "Customer"
    case business = "Business"
    case learning = "Learning"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .building: return "hammer.fill"
        case .content: return "doc.text.fill"
        case .marketing: return "megaphone.fill"
        case .design: return "paintbrush.fill"
        case .customer: return "person.2.fill"
        case .business: return "chart.bar.fill"
        case .learning: return "book.fill"
        }
    }

    var color: Color {
        switch self {
        case .building: return .blue
        case .content: return .purple
        case .marketing: return .orange
        case .design: return .pink
        case .customer: return .green
        case .business: return .gray
        case .learning: return .cyan
        }
    }

    var description: String {
        switch self {
        case .building: return "Core product development, coding, architecture"
        case .content: return "Writing blogs, documentation, tutorials, social posts"
        case .marketing: return "SEO, outreach, community engagement, ads"
        case .design: return "UI/UX work, graphics, branding"
        case .customer: return "Support, user interviews, feedback analysis"
        case .business: return "Planning, metrics, finance, admin tasks"
        case .learning: return "Research, tutorials, skill development"
        }
    }
}
