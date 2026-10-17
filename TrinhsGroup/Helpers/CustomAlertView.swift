//
//  CustomAlertView.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI

struct CustomAlertView: View {
    
    var message: String
    
    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .bottom) {
                Color.clear.ignoresSafeArea()
                
                VStack {
                    styledMessage
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(width: reader.size.width - 44.0)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.8))
                .cornerRadius(10)
                .padding(.bottom, 34)
                
            }
        }
    }

    /// WordPress errors arrive as HTML, e.g. "<strong>Error:</strong> Unknown username".
    /// Renders <strong>/<b> as bold and drops every other tag instead of showing raw markup.
    private var styledMessage: Text {
        let pieces = message.components(separatedBy: "<")
        var result = Text(pieces[0].decodingHTMLEntities())
        var isBold = false
        for piece in pieces.dropFirst() {
            guard let close = piece.firstIndex(of: ">") else {
                result = result + run("<" + piece, bold: isBold)
                continue
            }
            let tag = piece[..<close].lowercased()
            let name = tag.drop(while: { $0 == "/" }).split(separator: " ").first.map(String.init) ?? ""
            if name == "strong" || name == "b" {
                isBold = !tag.hasPrefix("/")
            }
            result = result + run(String(piece[piece.index(after: close)...]), bold: isBold)
        }
        return result
    }

    private func run(_ text: String, bold: Bool) -> Text {
        let run = Text(text.decodingHTMLEntities())
        return bold ? run.bold() : run
    }
}
