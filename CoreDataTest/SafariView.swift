//
//  ContentView.swift
//  CoreDataTest
//
//  Created by yanguo sun on 2023/10/18.
//

import SwiftUI
import CoreData
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: url)
        return safariViewController
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // 更新视图控制器，如果需要
    }
}



