//
//  SearchNoResultsView.swift
//  Counter
//

import SwiftUI

struct SearchNoResultsView: View {
    let searchTerm: String

    var body: some View {
        VStack() {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            Text("No Results for “\(searchTerm)”")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text("Check the spelling or try a new search.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 36)
    }
}

#Preview {
    SearchNoResultsView(searchTerm: "Blahgg")
        .preferredColorScheme(.dark)
}
