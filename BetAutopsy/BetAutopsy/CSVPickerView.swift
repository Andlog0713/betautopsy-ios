//
//  CSVPickerView.swift
//  BetAutopsy
//
//  SwiftUI wrapper over UIDocumentPickerViewController, scoped to
//  .commaSeparatedText.
//
//  Security-scoped resource note: the picker grants temporary access via
//  startAccessingSecurityScopedResource. The defer block stops access at
//  the end of the delegate callback. Callers must read the file
//  synchronously inside `onPicked` — typically via Data(contentsOf: url) —
//  before this scope exits. Async reads will lose access.
//

import SwiftUI
import UniformTypeIdentifiers

struct CSVPickerView: UIViewControllerRepresentable {
    let onPicked: (URL) -> Void
    let onCancelled: () -> Void

    func makeUIViewController(context: Context)
        -> UIDocumentPickerViewController
    {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.commaSeparatedText])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked, onCancelled: onCancelled)
    }

    final class Coordinator: NSObject,
                              UIDocumentPickerDelegate
    {
        let onPicked: (URL) -> Void
        let onCancelled: () -> Void

        init(onPicked: @escaping (URL) -> Void,
             onCancelled: @escaping () -> Void) {
            self.onPicked = onPicked
            self.onCancelled = onCancelled
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            guard let url = urls.first else {
                onCancelled()
                return
            }
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            onPicked(url)
        }

        func documentPickerWasCancelled(
            _ controller: UIDocumentPickerViewController
        ) {
            onCancelled()
        }
    }
}
