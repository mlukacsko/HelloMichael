//
//  ContentView.swift
//  HelloMichael
//
//  Created by Evie Rockwood on 3/16/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct CalendarItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let thumbnailPath: String
    let sampleImagePaths: [String]
}

struct ContentView: View {
    @State private var calendars: [CalendarItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && calendars.isEmpty {
                    ProgressView("Loading calendars...")
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Text("Something went wrong")
                            .font(.headline)

                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)

                        Button("Try Again") {
                            Task {
                                await loadCalendars()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(calendars) { calendar in
                                NavigationLink(destination: CalendarDetailView(calendar: calendar)) {
                                    CalendarCardView(calendar: calendar)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Calendar Marketplace")
            .task {
                if calendars.isEmpty {
                    await loadCalendars()
                }
            }
        }
    }

    func loadCalendars() async {
        isLoading = true
        errorMessage = nil

        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("calendars").getDocuments()

            print("Firestore returned \(snapshot.documents.count) documents")

            let loadedCalendars: [CalendarItem] = snapshot.documents.compactMap { document in
                let data = document.data()

                print("-----")
                print("Inspecting doc: \(document.documentID)")
                print("Raw data: \(data)")

                guard let title = data["title"] as? String else {
                    print("Skipping \(document.documentID): missing or invalid 'title'")
                    return nil
                }

                guard let description = data["description"] as? String else {
                    print("Skipping \(document.documentID): missing or invalid 'description'")
                    return nil
                }

                guard let thumbnailPath = data["thumbnailPath"] as? String else {
                    print("Skipping \(document.documentID): missing or invalid 'thumbnailPath'")
                    return nil
                }

                guard let sampleImagePaths = data["sampleImagePaths"] as? [String] else {
                    print("Skipping \(document.documentID): missing or invalid 'sampleImagePaths'")
                    return nil
                }

                print("Loaded calendar doc: \(document.documentID)")
                print("title: \(title)")
                print("thumbnailPath: \(thumbnailPath)")
                print("sampleImagePaths: \(sampleImagePaths)")

                return CalendarItem(
                    id: document.documentID,
                    title: title,
                    description: description,
                    thumbnailPath: thumbnailPath,
                    sampleImagePaths: sampleImagePaths
                )
            }

            calendars = loadedCalendars.sorted { $0.title < $1.title }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct CalendarCardView: View {
    let calendar: CalendarItem
    @State private var thumbnailURL: URL?
    @State private var isLoadingThumbnail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))

                if let thumbnailURL {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else if isLoadingThumbnail {
                    ProgressView()
                } else {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(calendar.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .task {
            await loadThumbnailURL()
        }
    }

    func loadThumbnailURL() async {
        guard thumbnailURL == nil else { return }

        isLoadingThumbnail = true
        defer { isLoadingThumbnail = false }

        do {
            print("Trying thumbnail path: \(calendar.thumbnailPath)")
            let ref = Storage.storage().reference(withPath: calendar.thumbnailPath)
            thumbnailURL = try await ref.downloadURL()
            print("Thumbnail loaded for \(calendar.title)")
        } catch {
            print("Failed thumbnail path: \(calendar.thumbnailPath)")
            print("Thumbnail error: \(error.localizedDescription)")
        }
    }
}

struct CalendarDetailView: View {
    let calendar: CalendarItem

    @State private var sampleURLs: [URL] = []
    @State private var isLoadingSamples = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(calendar.title)
                    .font(.largeTitle)
                    .bold()

                Text(calendar.description)
                    .font(.body)

                Text("Sample Images")
                    .font(.title2)
                    .bold()

                if isLoadingSamples && sampleURLs.isEmpty {
                    ProgressView("Loading sample images...")
                        .frame(maxWidth: .infinity, minHeight: 120)
                }

                ForEach(sampleURLs, id: \.self) { url in
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 180)

                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                        case .failure:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 180)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )

                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(calendar.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSampleURLs()
        }
    }

    func loadSampleURLs() async {
        guard sampleURLs.isEmpty else { return }

        isLoadingSamples = true
        defer { isLoadingSamples = false }

        var urls: [URL] = []

        for path in calendar.sampleImagePaths {
            do {
                print("Trying sample path: \(path)")
                let ref = Storage.storage().reference(withPath: path)
                let url = try await ref.downloadURL()
                urls.append(url)
                print("Loaded sample path: \(path)")
            } catch {
                print("Failed sample path: \(path)")
                print("Sample error: \(error.localizedDescription)")
            }
        }

        sampleURLs = urls
    }
}

#Preview {
    ContentView()
}
