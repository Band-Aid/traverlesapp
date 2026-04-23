import SwiftUI
import PhotosUI

/// Lets the user pick a screenshot of their JMB dashboard, runs Vision OCR,
/// feeds the text through `JMBTextParser`, and returns the draft to the
/// caller. The caller is responsible for prefilling its own form.
struct JMBScanSheet: View {
    let onResult: (JMBDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selection: PhotosPickerItem?
    @State private var preview: UIImage?
    @State private var isProcessing = false
    @State private var errorText: String?
    @State private var draft: JMBDraft?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    explainer
                    imageArea
                    if let draft {
                        draftCard(draft)
                    }
                    if let errorText {
                        errorBanner(errorText)
                    }
                    PhotosPicker(selection: $selection, matching: .images) {
                        Label(preview == nil ? "Choose screenshot" : "Choose a different one",
                              systemImage: "photo.on.rectangle")
                            .font(.jal(15, .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(JALTheme.crane)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(JALTheme.mist.ignoresSafeArea())
            .navigationTitle("Scan screenshot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use") {
                        if let draft { onResult(draft) }
                        dismiss()
                    }
                    .bold()
                    .disabled(draft == nil)
                }
            }
            .onChange(of: selection) { _, newValue in
                Task { await handleSelection(newValue) }
            }
        }
    }

    private var explainer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Point it at your dashboard.")
                .font(.jal(18, .heavy))
                .foregroundStyle(JALTheme.ink)
            Text("Open the JAL app or web portal, screenshot the JMB page with your miles, tier, and member number visible. We'll read it on-device — nothing leaves your phone.")
                .font(.jal(13))
                .foregroundStyle(JALTheme.inkSoft)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var imageArea: some View {
        Group {
            if let preview {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(JALTheme.line, lineWidth: 1)
                        )
                    if isProcessing {
                        ProgressView()
                            .tint(JALTheme.crane)
                            .padding(10)
                            .background(.white.opacity(0.9), in: Circle())
                            .padding(10)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white)
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 10) {
                            Image(systemName: "doc.viewfinder")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(JALTheme.crane)
                            Text("No image yet")
                                .font(.jal(13, .semibold))
                                .foregroundStyle(JALTheme.inkSoft)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(style: .init(lineWidth: 1.5, dash: [6, 6]))
                            .foregroundStyle(JALTheme.crane.opacity(0.5))
                    )
            }
        }
    }

    private func draftCard(_ draft: JMBDraft) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(JALTheme.gold)
                Text("Found on your screenshot")
                    .font(.jal(12, .heavy))
                    .tracking(1.0)
                    .foregroundStyle(JALTheme.inkSoft)
            }
            draftRow("Name", draft.name)
            draftRow("Member #", draft.memberNumber)
            draftRow("Tier", draft.tier)
            draftRow("Miles", draft.miles.map { $0.formatted() })
            draftRow("Flights YTD", draft.flightsYTD.map { "\($0)" })
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(JALTheme.gold.opacity(0.35), lineWidth: 1)
        )
    }

    private func draftRow(_ label: String, _ value: String?) -> some View {
        HStack {
            Text(label)
                .font(.jal(12, .semibold))
                .foregroundStyle(JALTheme.inkSoft)
                .frame(width: 96, alignment: .leading)
            Text(value ?? "—")
                .font(.jalMono(13, .bold))
                .foregroundStyle(value == nil ? JALTheme.inkSoft : JALTheme.ink)
            Spacer()
        }
    }

    private func errorBanner(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(JALTheme.warning)
            Text(text)
                .font(.jal(12, .semibold))
                .foregroundStyle(JALTheme.ink)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(JALTheme.warning.opacity(0.12))
        )
    }

    // MARK: - Actions

    private func handleSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        errorText = nil
        draft = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorText = "Couldn't load that image."
                return
            }
            preview = image
            isProcessing = true
            defer { isProcessing = false }
            let lines = try await JMBOCRService.recognize(in: image)
            let parsed = JMBTextParser.parse(lines)
            draft = parsed
            if parsed.miles == nil && parsed.memberNumber == nil && parsed.tier == nil {
                errorText = "Couldn't find JMB details in that image. Try a clearer screenshot."
            }
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    JMBScanSheet { _ in }
}
