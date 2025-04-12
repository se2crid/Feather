//
//  TransferPreview.swift
//  feather
//
//  Created by samara on 8/16/24.
//  Copyright © 2024 Lakr Aream. All Rights Reserved.
//  ORIGINALLY LICENSED UNDER GPL-3.0, MODIFIED FOR USE FOR FEATHER
//

import SwiftUI
import UIKit
import SafariServices

struct TransferPreview: View {
	@Environment(\.presentationMode) var presentationMode
	
	@State var appPath: String
	@State var appName: String
	@State var isSharing: Bool = false
	
	@State private var packaging: Bool = true
	@State private var showShareSheet = false
	@State private var shareURL: URL?

	var icon: String {
		if packaging {
			return "archivebox.fill"
		} else if !isSharing {
            return "app.gift"
		} else {
			return "checkmark.circle"
		}
	}
	
	var text: String {
		if packaging {
			return String.localized("TRANSFER_PREVIEW_PACKAGING")
		} else if !isSharing {
            return String.localized("TRANSFER_PREVIEW_READY")
		} else {
			return String.localized("TRANSFER_PREVIEW_COMPLETED")
		}
	}
	
	@State private var isPresentWebView = false
	
	var body: some View {
		VStack {
			Spacer()
			VStack(spacing: 18) {
				Image(systemName: icon)
					.antialiased(true)
					.resizable()
					.cornerRadius(8)
					.frame(width: 42, height: 42, alignment: .center)
				Text(text)
					.font(.system(.body, design: .rounded))
					.bold()
					.frame(alignment: .center)
			}

			.onAppear {
				archivePayload(at: appPath, with: appName) { archiveURL in
					if let archiveURL = archiveURL {
                        startInstallation(ipaPath: archiveURL.path) { cool in
                            if let cool {
                                print("error :( \(cool)")
                            }
                        }
					}
				}
			}

			.padding()
			Spacer()
		}
		.animation(.spring, value: text)
		.animation(.spring, value: icon)
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
		.background(Color(UIColor.quaternarySystemFill))
		.cornerRadius(12)
		.padding()
	}
	
	func archivePayload(at filePath: String, with fileName: String, completion: @escaping (URL?) -> Void) {
		DispatchQueue.global(qos: .userInitiated).async {
			let uuid = UUID().uuidString
			let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(uuid)
			let payloadPath = tempDirectory.appendingPathComponent("Payload")
			let sanitizedFileName = fileName.replacingOccurrences(of: "/", with: "_").trimmingCharacters(in: .whitespacesAndNewlines)
			let ipaPath = tempDirectory.appendingPathComponent("\(sanitizedFileName).ipa")
			
			do {
				try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
				try FileManager.default.copyItem(atPath: filePath, toPath: payloadPath.path)
				try FileManager.default.zipItem(at: payloadPath, to: ipaPath)
				
				DispatchQueue.main.async {
					self.packaging = false
					completion(ipaPath)
				}
			} catch {
				Debug.shared.log(message: "Error creating archive: \(error)", type: .error)
				DispatchQueue.main.async {
					completion(nil)
				}
			}
		}
	}

}

struct ActivityViewController: UIViewControllerRepresentable {
	var activityItems: [Any]
	var applicationActivities: [UIActivity]? = nil

	func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
		return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
	}

	func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

struct SafariWebView: UIViewControllerRepresentable {
	let url: URL
	
	func makeUIViewController(context: Context) -> SFSafariViewController {
		return SFSafariViewController(url: url)
	}
	
	func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
		//
	}
}
