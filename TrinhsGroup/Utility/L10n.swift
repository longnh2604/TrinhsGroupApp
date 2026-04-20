import Foundation
import SwiftUI

enum L10n {
    enum Common {
        static let ok = "common.ok"
        static let cancel = "common.cancel"
        static let submit = "common.submit"
        static let save = "common.save"
        static let done = "common.done"
        static let error = "common.error"
        static let success = "common.success"
        static let warning = "common.warning"
        static let yes = "common.yes"
        static let no = "common.no"
        static let total = "common.total"
        static let subtotal = "common.subtotal"
        static let email = "common.email"
        static let emptyString = "common.emptyString"
        static let back = "common.back"
        static let update = "common.update"
        static let logout = "common.logout"
        static let redeem = "common.redeem"
    }
    
    enum Auth {
        static let login = "auth.login"
        static let signup = "auth.signup"
        static let email = "auth.email"
        static let password = "auth.password"
        static let username = "auth.username"
        static let forgetPassword = "auth.forgetPassword"
        static let forgetPasswordTitle = "auth.forgetPasswordTitle"
        static let dontHaveAccount = "auth.dontHaveAccount"
        static let accountCreated = "auth.accountCreated"
        static let send = "auth.send"
        static let enterEmailPrompt = "auth.enterEmailPrompt"
        static let invalidEmail = "auth.invalidEmail"
    }
    
    enum OrderReceived {
        static let items = "orderReceived.items"
        static let title = "orderReceived.title"
        static let thankYouMessage = "orderReceived.thankYouMessage"
        static let checkout = "orderReceived.checkout"
        static let discount = "orderReceived.discount"
        static let orderNo = "orderReceived.orderNo"
        static let date = "orderReceived.date"
        static let note = "orderReceived.note"
        static let addition = "orderReceived.addition"
    }
    
    enum Profile {
        static let orderNoFormat = "profile.orderNoFormat"
        static let showMore = "profile.showMore"
        static let guestUser = "profile.guestUser"
        static let notLoggedIn = "profile.notLoggedIn"
        static let accountSettings = "profile.accountSettings"
        static let changeAvatar = "profile.changeAvatar"
        static let changeAvatarSubtitle = "profile.changeAvatarSubtitle"
        static let changePassword = "profile.changePassword"
        static let changePasswordSubtitle = "profile.changePasswordSubtitle"
        static let manageAddress = "profile.manageAddress"
        static let manageAddressSubtitle = "profile.manageAddressSubtitle"
        static let personalInformation = "profile.personalInformation"
        static let firstName = "profile.firstName"
        static let lastName = "profile.lastName"
        static let phone = "profile.phone"
        static let billingAddress = "profile.billingAddress"
        static let myOrders = "profile.myOrders"
        static let noOrdersTitle = "profile.noOrdersTitle"
        static let noOrdersMessage = "profile.noOrdersMessage"
        static let orderDetail = "profile.orderDetail"
        static let note = "profile.note"
        static let status = "profile.status"
        static let points = "profile.points"
        static let member = "profile.member"
        static let earnPointsInfo = "profile.earnPointsInfo"
        static let redeemVouchers = "profile.redeemVouchers"
        static let vouchersValidInfo = "profile.vouchersValidInfo"
        static let voucherHistory = "profile.voucherHistory"
        static let noVouchersTitle = "profile.noVouchersTitle"
        static let noVouchersMessage = "profile.noVouchersMessage"
        static let voucherAmountFormat = "profile.voucherAmountFormat"
        static let voucherExpiresFormat = "profile.voucherExpiresFormat"
        static let preferences = "profile.preferences"
        static let pushNotifications = "profile.pushNotifications"
        static let pushNotificationsSubtitle = "profile.pushNotificationsSubtitle"
        static let helpAndSupport = "profile.helpAndSupport"
        static let legal = "profile.legal"
        static let logoutButton = "profile.logoutButton"
        static let appVersionFormat = "profile.appVersionFormat"
        static let madeWithLove = "profile.madeWithLove"
        static let rewards = "profile.rewards"
        static let seeAll = "profile.seeAll"
        static let accountTitle = "profile.accountTitle"
        static let accountSubtitle = "profile.accountSubtitle"
        static let ordersSubtitleFormat = "profile.ordersSubtitleFormat"
        static let rewardsSubtitle = "profile.rewardsSubtitle"
        static let contactSupport = "profile.contactSupport"
        static let faq = "profile.faq"
        static let termsOfService = "profile.termsOfService"
        static let privacyPolicy = "profile.privacyPolicy"
        static let orderStatus = "profile.orderStatus"
        static let pointsSuffix = "profile.pointsSuffix"
        static let pointsSuffixShort = "profile.pointsSuffixShort"
        static let editBillingAddress = "profile.editBillingAddress"
        static let updatedUserSuccessful = "profile.updatedUserSuccessful"
        static let profileTitle = "profile.profileTitle"
        static let accountNav = "profile.accountNav"
        static let name = "profile.name"
        static let firstName_placeholder = "profile.firstName_placeholder"
        static let lastName_placeholder = "profile.lastName_placeholder"
        static let country = "profile.country"
        static let streetAddress = "profile.streetAddress"
        static let state = "profile.state"
        static let cityTown = "profile.cityTown"
        static let postcode = "profile.postcode"
    }
    
    enum Alert {
        static let logoutTitle = "alert.logoutTitle"
        static let logoutMessage = "alert.logoutMessage"
        static let logoutConfirm = "alert.logoutConfirm"
        static let redeemTitle = "alert.redeemTitle"
        static let redeemConfirmFormat = "alert.redeemConfirmFormat"
        static let redeemConfirm = "alert.redeemConfirm"
        static let voucherCreatedTitle = "alert.voucherCreatedTitle"
        static let voucherCreatedMessageFormat = "alert.voucherCreatedMessageFormat"
        static let voucherCreatedSuccess = "alert.voucherCreatedSuccess"
        static let redemptionFailedTitle = "alert.redemptionFailedTitle"
        static let avatarUpdateTitle = "alert.avatarUpdateTitle"
        static let avatarUpdateMessage = "alert.avatarUpdateMessage"
        static let chooseFromLibrary = "alert.chooseFromLibrary"
        static let takeNewPhoto = "alert.takeNewPhoto"
        static let removeAvatar = "alert.removeAvatar"
        static let deleteAvatarTitle = "alert.deleteAvatarTitle"
        static let deleteAvatarMessage = "alert.deleteAvatarMessage"
        static let deleteConfirm = "alert.deleteConfirm"
        static let avatarErrorTitle = "alert.avatarErrorTitle"
    }
    
    enum CheckOut {
        static let title = "checkout.title"
        static let placeOrder = "checkout.placeOrder"
        static let paymentFailed = "checkout.paymentFailed"
        static let paymentFailedRetry = "checkout.paymentFailedRetry"
        static let billingDetails = "checkout.billingDetails"
        static let firstName = "checkout.firstName"
        static let lastName = "checkout.lastName"
        static let address = "checkout.address"
        static let city = "checkout.city"
        static let state = "checkout.state"
        static let postcode = "checkout.postcode"
        static let phone = "checkout.phone"
        static let paymentMethod = "checkout.paymentMethod"
        static let couponCode = "checkout.couponCode"
        static let applyCoupon = "checkout.applyCoupon"
        static let removeCoupon = "checkout.removeCoupon"
        static let orderNotes = "checkout.orderNotes"
        static let noPaymentMethods = "checkout.noPaymentMethods"
    }
    
    enum Setting {
        static let title = "setting.title"
    }
    
    enum Error {
        static let invalidAvatarURL = "error.invalidAvatarURL"
        static let missingResponse = "error.missingResponse"
        static let avatarUnauthorized = "error.avatarUnauthorized"
        static let imageDataMissing = "error.imageDataMissing"
        static let unsupportedAvatarUpdate = "error.unsupportedAvatarUpdate"
        static let unsupportedAvatarDelete = "error.unsupportedAvatarDelete"
        static let fallbackAvatarEndpoint = "error.fallbackAvatarEndpoint"
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    var localizedKey: LocalizedStringKey {
        return LocalizedStringKey(self)
    }
}
