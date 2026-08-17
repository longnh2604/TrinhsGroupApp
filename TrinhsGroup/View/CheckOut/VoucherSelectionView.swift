//
//  VoucherSelectionView.swift
//  TrinhsGroup
//
//  Voucher selection dropdown for checkout
//

import SwiftUI

struct VoucherSelectionView: View {
    let vouchers: [VoucherResponse]
    @Binding var selectedVoucher: VoucherResponse?
    var isLoading: Bool = false
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apply Voucher")
                .font(.headline)
            
            // Dropdown button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading vouchers...")
                            .foregroundColor(.gray)
                    } else if let voucher = selectedVoucher {
                        // Selected voucher display
                        VStack(alignment: .leading, spacing: 2) {
                            Text(voucher.code)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(Color("ColorPrimary"))
                            Text("$\(Int(voucher.amount)) discount")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        Text(vouchers.isEmpty ? "No vouchers available" : "Select a voucher (optional)")
                            .foregroundColor(vouchers.isEmpty ? .gray : .primary)
                    }
                    
                    Spacer()
                    
                    if !vouchers.isEmpty && !isLoading {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedVoucher != nil ? Color("ColorPrimary") : Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(vouchers.isEmpty || isLoading)
            
            // Expandable voucher list
            if isExpanded && !vouchers.isEmpty {
                VStack(spacing: 0) {
                    // "No voucher" option to clear selection
                    Button(action: {
                        selectedVoucher = nil
                        withAnimation {
                            isExpanded = false
                        }
                    }) {
                        HStack {
                            Text("No voucher")
                                .foregroundColor(.gray)
                            Spacer()
                            if selectedVoucher == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("ColorPrimary"))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(selectedVoucher == nil ? Color("ColorPrimary").opacity(0.1) : Color.white)
                    }
                    
                    Divider()
                    
                    // Voucher options
                    ForEach(vouchers) { voucher in
                        Button(action: {
                            selectedVoucher = voucher
                            withAnimation {
                                isExpanded = false
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(voucher.code)
                                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text("$\(Int(voucher.amount))")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                    
                                    Text("Expires: \(voucher.formattedExpiryDate)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                if selectedVoucher?.id == voucher.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color("ColorPrimary"))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(selectedVoucher?.id == voucher.id ? Color("ColorPrimary").opacity(0.1) : Color.white)
                        }
                        
                        if voucher.id != vouchers.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
    }
}

// MARK: - Preview
struct VoucherSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // With vouchers
            VoucherSelectionView(
                vouchers: [
                    VoucherResponse(
                        id: 1,
                        code: "RW107-ABCD1234",
                        amount: 10,
                        currency: "AUD",
                        expiresAt: "2026-03-25T00:00:00+00:00",
                        usageCount: 0,
                        usageLimit: 1,
                        status: "active"
                    ),
                    VoucherResponse(
                        id: 2,
                        code: "RW107-WXYZ5678",
                        amount: 20,
                        currency: "AUD",
                        expiresAt: "2026-04-01T00:00:00+00:00",
                        usageCount: 0,
                        usageLimit: 1,
                        status: "active"
                    )
                ],
                selectedVoucher: .constant(nil)
            )
            .padding()
            
            // Empty state
            VoucherSelectionView(
                vouchers: [],
                selectedVoucher: .constant(nil)
            )
            .padding()
            
            // Loading state
            VoucherSelectionView(
                vouchers: [],
                selectedVoucher: .constant(nil),
                isLoading: true
            )
            .padding()
        }
        .background(Color(hex: "f9f9f9"))
    }
}
