//
//  AddOnGroupsView.swift
//  TrinhsGroup
//
//  Renders the YITH add-on groups for one product and reports back what was chosen.
//
//  Each type is drawn the way the website draws it, because a saved order cannot tell a
//  `select` from a `radio` and the kitchen ticket has to read the same either way: `select`
//  becomes a menu (the website's native dropdown), `radio` a single-choice list, `checkbox` a
//  multi-choice list. Prices shown are the server's own — nothing here totals an order.
//

import SwiftUI

struct AddOnGroupsView: View {
    let groups: [AddOnGroup]
    @Binding var selection: AddOnSelection

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    header(for: group)

                    if group.type == "select" {
                        menu(for: group)
                    } else {
                        list(for: group)
                    }
                }
            }
        }
    }

    // MARK: Header

    private func header(for group: AddOnGroup) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(group.title)
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    .foregroundColor(Constants.AppColor.primaryBlack)

                if group.required {
                    Text("Required")
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 10))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color("ColorPrimary"))
                        .cornerRadius(4)
                }

                Spacer()

                if let limit = limitText(for: group) {
                    Text(limit)
                        .font(.custom(Constants.AppFont.regularFont, size: 11))
                        .foregroundColor(Constants.AppColor.secondaryBlack)
                }
            }

            if !group.description.isEmpty {
                Text(group.description)
                    .font(.custom(Constants.AppFont.regularFont, size: 12))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
        }
    }

    private func limitText(for group: AddOnGroup) -> String? {
        switch (group.min, group.max) {
        case let (min?, max?): return "Choose \(min)–\(max)"
        case let (nil, max?): return "Up to \(max)"
        case let (min?, nil): return "At least \(min)"
        default: return nil
        }
    }

    // MARK: select — the website's dropdown

    private func menu(for group: AddOnGroup) -> some View {
        Menu {
            ForEach(group.options) { option in
                Button(action: { selection.toggle(group: group, option: option) }) {
                    // A tick beside the current answer, so reopening the menu shows it.
                    if selection.isChosen(group: group, option: option) {
                        Label(optionText(option), systemImage: "checkmark")
                    } else {
                        Text(optionText(option))
                    }
                }
            }
        } label: {
            HStack {
                Text(selection.chosenLabel(group: group) ?? "Select an option")
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    .foregroundColor(selection.chosenCount(group: group) > 0
                                     ? Constants.AppColor.primaryBlack
                                     : Constants.AppColor.secondaryBlack)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Constants.AppColor.lightGrayColor)
            .cornerRadius(14)
        }
    }

    // MARK: radio and checkbox

    private func list(for group: AddOnGroup) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(group.options.enumerated()), id: \.element.id) { position, option in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selection.toggle(group: group, option: option)
                    }
                }) {
                    HStack(spacing: 12) {
                        indicator(
                            isChosen: selection.isChosen(group: group, option: option),
                            isRound: !group.allowsMultiple
                        )

                        Text(option.label)
                            .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                            .foregroundColor(Constants.AppColor.primaryBlack)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if let price = option.displayPrice {
                            Text(priceText(price))
                                .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                                .foregroundColor(Constants.AppColor.secondaryBlack)
                        }
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                if position < group.options.count - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal, 14)
        .background(Constants.AppColor.lightGrayColor)
        .cornerRadius(14)
    }

    private func indicator(isChosen: Bool, isRound: Bool) -> some View {
        ZStack {
            Group {
                if isRound {
                    Circle().fill(isChosen ? Color("ColorPrimary") : Color.white)
                    Circle().stroke(isChosen ? Color("ColorPrimary") : Color.gray.opacity(0.4), lineWidth: 1.5)
                } else {
                    RoundedRectangle(cornerRadius: 7).fill(isChosen ? Color("ColorPrimary") : Color.white)
                    RoundedRectangle(cornerRadius: 7).stroke(isChosen ? Color("ColorPrimary") : Color.gray.opacity(0.4), lineWidth: 1.5)
                }
            }

            if isChosen {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 22, height: 22)
    }

    // MARK: Formatting

    private func optionText(_ option: AddOnOption) -> String {
        guard let price = option.displayPrice else { return option.label }
        return "\(option.label)  \(priceText(price))"
    }

    private func priceText(_ price: Double) -> String {
        let sign = price < 0 ? "-" : "+"
        let amount = getPriceAndCurrencySymbol(
            price: abs(price),
            currency: "$",
            currencyPosition: "left"
        )
        return sign + amount
    }
}

struct AddOnGroupsView_Previews: PreviewProvider {
    static var previews: some View {
        AddOnGroupsView(
            groups: [
                AddOnGroup(
                    addonId: 28,
                    type: "select",
                    title: "1st Pho",
                    required: true,
                    options: [
                        AddOnOption(optionId: "0", label: "Chicken", submitKey: "28", submitValue: "0"),
                        AddOnOption(optionId: "1", label: "Beef", submitKey: "28", submitValue: "1")
                    ]
                ),
                AddOnGroup(
                    addonId: 2,
                    type: "checkbox",
                    title: "Addition",
                    selectionType: "multiple",
                    max: 2,
                    options: [
                        AddOnOption(optionId: "0", label: "Add Meat", price: 3, priceMethod: "increase", submitKey: "2-0", submitValue: "1"),
                        AddOnOption(optionId: "1", label: "Add Tofu", price: 2, priceMethod: "increase", submitKey: "2-1", submitValue: "1"),
                        AddOnOption(optionId: "2", label: "No Chili", submitKey: "2-2", submitValue: "1")
                    ]
                )
            ],
            selection: .constant(AddOnSelection())
        )
        .padding()
    }
}
