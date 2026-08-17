package com.trinhsgroup.shared.service

import com.trinhsgroup.shared.model.AnyCodableValue
import com.trinhsgroup.shared.model.Category
import com.trinhsgroup.shared.model.Order
import com.trinhsgroup.shared.model.OrderQuote
import com.trinhsgroup.shared.model.Payment
import com.trinhsgroup.shared.model.Product
import com.trinhsgroup.shared.model.ProductOrder
import com.trinhsgroup.shared.model.User
import com.trinhsgroup.shared.network.HttpMethod
import com.trinhsgroup.shared.network.WooCommerceApi
import com.trinhsgroup.shared.network.WooCommerceEndpoint
import com.trinhsgroup.shared.network.request
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Main service for categories, products, orders, and payment methods.
 * Mirrors Swift's MainServices class.
 */
class MainService(
    private val api: WooCommerceApi = WooCommerceApi()
) {
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _isCategoryProductsLoading = MutableStateFlow(false)
    val isCategoryProductsLoading: StateFlow<Boolean> = _isCategoryProductsLoading.asStateFlow()

    private val _error = MutableStateFlow("")
    val error: StateFlow<String> = _error.asStateFlow()

    private val _categories = MutableStateFlow<List<Category>>(emptyList())
    val categories: StateFlow<List<Category>> = _categories.asStateFlow()

    private val _popularProducts = MutableStateFlow<List<Product>>(emptyList())
    val popularProducts: StateFlow<List<Product>> = _popularProducts.asStateFlow()

    private val _selectedCategoryProducts = MutableStateFlow<List<Product>>(emptyList())
    val selectedCategoryProducts: StateFlow<List<Product>> = _selectedCategoryProducts.asStateFlow()

    private val _payments = MutableStateFlow<List<Payment>>(emptyList())
    val payments: StateFlow<List<Payment>> = _payments.asStateFlow()

    private val _order = MutableStateFlow(Order.Default)
    val order: StateFlow<Order> = _order.asStateFlow()

    /**
     * Fetches all product categories.
     * Mirrors Swift's onFetchCategories().
     */
    suspend fun onFetchCategories() {
        _isLoading.value = true
        _error.value = ""

        try {
            val categoryList: List<Category> = api.request(
                endpoint = WooCommerceEndpoint.FetchCategories,
                method = HttpMethod.GET
            )
            _categories.value = categoryList
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to fetch categories"
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Fetches popular products.
     * Mirrors Swift's onFetchPopularProducts().
     */
    suspend fun onFetchPopularProducts() {
        _isLoading.value = true
        _error.value = ""

        try {
            val products: List<Product> = api.request(
                endpoint = WooCommerceEndpoint.FetchPopularProducts,
                method = HttpMethod.GET
            )
            _popularProducts.value = products
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to fetch popular products"
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Fetches products for a specific category.
     * Mirrors Swift's fetchSelectedCategoryProducts().
     *
     * @param categoryId The category ID to fetch products for
     */
    suspend fun fetchSelectedCategoryProducts(categoryId: Int) {
        _isCategoryProductsLoading.value = true
        _error.value = ""

        try {
            val products: List<Product> = api.request(
                endpoint = WooCommerceEndpoint.FetchProductsCategory(categoryId),
                method = HttpMethod.GET
            )
            _selectedCategoryProducts.value = products
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to fetch category products"
        } finally {
            _isCategoryProductsLoading.value = false
        }
    }

    /**
     * Fetches available payment methods.
     * Mirrors Swift's onFetchPaymentMethods().
     * Filters to only enabled payment methods.
     */
    suspend fun onFetchPaymentMethods() {
        _isLoading.value = true
        _error.value = ""

        try {
            val allPayments: List<Payment> = api.request(
                endpoint = WooCommerceEndpoint.PaymentMethods,
                method = HttpMethod.GET
            )
            
            // Standalone enabled gateways only. woocommerce_payments_* (Apple/Google Pay
            // express methods) and stripe_* (Link, SEPA, ...) are handled inside their
            // parent gateway's own checkout, not shown as separate options.
            val enabledPayments = allPayments.filter {
                it.enabled &&
                    it.title.isNotEmpty() &&
                    !it.id.startsWith("woocommerce_payments_") &&
                    !it.id.startsWith("stripe_")
            }
            _payments.value = enabledPayments
            
            if (enabledPayments.isEmpty()) {
                _error.value = "No payment methods available"
            }
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to fetch payment methods"
            _payments.value = emptyList()
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * What the basket costs, priced by the server, without creating an order.
     * Mirrors Swift's fetchOrderQuote().
     *
     * The payment method is part of the question, not decoration: the cash-on-pickup
     * discount is a negative gateway fee, so the total depends on the gateway chosen.
     *
     * @return the quote, or null when the server could not price the basket
     */
    suspend fun fetchOrderQuote(
        paymentMethod: String,
        productOrders: List<ProductOrder>,
        couponCode: String? = null
    ): OrderQuote? {
        return try {
            val body = buildJsonObject {
                put("payment_method", paymentMethod)
                put("line_items", buildLineItemsJson(productOrders))
                if (!couponCode.isNullOrEmpty()) {
                    put("coupon_code", couponCode)
                }
            }
            api.request<OrderQuote>(
                endpoint = WooCommerceEndpoint.OrderQuote,
                method = HttpMethod.POST,
                body = body
            )
        } catch (e: Exception) {
            // The server rejects a basket for reasons the customer can act on — a voucher
            // past its usage limit, an unsupported gateway — so the reason has to reach them
            // rather than leaving the screen showing a total the server would not honour.
            println("❌ MainService.fetchOrderQuote: ${e::class.simpleName}: ${e.message}")
            _error.value = e.message ?: "Could not price this order"
            null
        }
    }

    /**
     * Creates an order.
     * Mirrors Swift's onCreateOrder() exactly for JSON parity.
     *
     * The order JSON structure must match iOS exactly:
     * - payment_method, payment_method_title, customer_note, status
     * - billing block (9 fields)
     * - line_items (product_id, quantity, meta_data)
     * - meta_data: [{key:"pickup_datetime", value: pickupDateTime}]
     * - coupon_lines (when couponCode non-empty)
     *
     * @param user The customer placing the order
     * @param paymentMethod Payment method ID (e.g., "stripe")
     * @param paymentMethodTitle Human-readable payment method title
     * @param customerNote Optional note from customer
     * @param status Order status ("pending" for stripe, "on-hold" otherwise)
     * @param productOrders List of products to order
     * @param pickupDateTime Pickup date/time string in "yyyy-MM-dd HH:mm:ss" format
     * @param couponCode Optional voucher/coupon code
     * @return Pair of (orderId, paymentURL) or (null, null) on failure
     */
    suspend fun onCreateOrder(
        user: User,
        paymentMethod: String,
        paymentMethodTitle: String,
        customerNote: String,
        status: String,
        productOrders: List<ProductOrder>,
        pickupDateTime: String,
        couponCode: String? = null
    ): Pair<Int?, String?> {
        _isLoading.value = true
        _error.value = ""

        // Debug logging for input validation
        println("📦 MainService.onCreateOrder: Starting order creation...")
        println("📦 MainService.onCreateOrder: user.id=${user.id}, user.email=${user.email}")
        println("📦 MainService.onCreateOrder: billing.firstName=${user.billing.firstName}, billing.lastName=${user.billing.lastName}")
        println("📦 MainService.onCreateOrder: billing.email=${user.billing.email}, billing.phone=${user.billing.phone}")
        println("📦 MainService.onCreateOrder: paymentMethod=$paymentMethod, status=$status")
        println("📦 MainService.onCreateOrder: productOrders count=${productOrders.size}")
        println("📦 MainService.onCreateOrder: pickupDateTime=$pickupDateTime")
        println("📦 MainService.onCreateOrder: couponCode=${couponCode ?: "(none)"}")

        // Validate inputs
        if (user.id <= 0) {
            println("❌ MainService.onCreateOrder: Invalid user ID: ${user.id}")
            _error.value = "Invalid user ID"
            _isLoading.value = false
            return Pair(null, null)
        }

        if (productOrders.isEmpty()) {
            println("❌ MainService.onCreateOrder: No products in order")
            _error.value = "Cart is empty"
            _isLoading.value = false
            return Pair(null, null)
        }

        try {
            val orderJson = buildOrderJson(
                user = user,
                paymentMethod = paymentMethod,
                paymentMethodTitle = paymentMethodTitle,
                customerNote = customerNote,
                status = status,
                productOrders = productOrders,
                pickupDateTime = pickupDateTime,
                couponCode = couponCode
            )

            println("📦 MainService.onCreateOrder: Built order JSON = $orderJson")

            val createdOrder: Order = api.request(
                endpoint = WooCommerceEndpoint.MyOrders,
                method = HttpMethod.POST,
                body = orderJson
            )
            
            println("✅ MainService.onCreateOrder: Order created successfully, id = ${createdOrder.id}")
            _order.value = createdOrder
            return Pair(createdOrder.id, createdOrder.paymentURL)
        } catch (e: Exception) {
            println("❌ MainService.onCreateOrder: Error - ${e::class.simpleName}: ${e.message}")
            e.printStackTrace()
            _error.value = e.message ?: "Failed to create order"
            return Pair(null, null)
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Builds the order JSON object matching iOS structure exactly.
     *
     * Internal rather than private so the payload can be asserted directly in tests — it is
     * the one place where a silent change bills the customer the wrong amount.
     */
    internal fun buildOrderJson(
        user: User,
        paymentMethod: String,
        paymentMethodTitle: String,
        customerNote: String,
        status: String,
        productOrders: List<ProductOrder>,
        pickupDateTime: String,
        couponCode: String?
    ): JsonObject {
        // customer_id and set_paid are deliberately absent: the server forces both from the
        // JWT, so an order can never be filed against another account or mark itself paid.
        // No prices are sent either — the server builds the real WooCommerce cart, so YITH
        // prices the add-ons and the cash-on-pickup discount arrives as the gateway fee the
        // website is configured with. POST /me/orders/preview quotes that same cart.
        return buildJsonObject {
            put("payment_method", paymentMethod)
            put("payment_method_title", paymentMethodTitle)
            put("customer_note", customerNote)
            // The server allowlists "pending" and "on-hold".
            put("status", status)

            // Billing block. Falls back to the account's own name and email so an order is
            // never filed without a way to contact the customer.
            put("billing", buildJsonObject {
                put("first_name", user.billing.firstName.ifEmpty { user.firstName })
                put("last_name", user.billing.lastName.ifEmpty { user.lastName })
                put("country", user.billing.country.ifEmpty { "AU" })
                put("address_1", user.billing.address1)
                put("city", user.billing.city)
                put("postcode", user.billing.postcode)
                put("state", user.billing.state)
                put("email", user.billing.email.ifEmpty { user.email })
                put("phone", user.billing.phone)
            })

            // Line items
            put("line_items", buildLineItemsJson(productOrders))

            // Meta data with pickup_datetime
            put("meta_data", buildJsonArray {
                add(buildJsonObject {
                    put("key", "pickup_datetime")
                    put("value", pickupDateTime)
                })
            })

            // Coupon lines (if voucher code provided)
            if (!couponCode.isNullOrEmpty()) {
                put("coupon_lines", buildJsonArray {
                    add(buildJsonObject {
                        put("code", couponCode)
                    })
                })
            }
        }
    }

    /**
     * Builds the line_items JSON array for the order.
     */
    private fun buildLineItemsJson(productOrders: List<ProductOrder>): JsonArray {
        return buildJsonArray {
            for (p in productOrders) {
                add(buildJsonObject {
                    put("product_id", p.productId)
                    put("quantity", p.quantity)
                    put("meta_data", buildJsonArray {
                        for (m in p.metaData) {
                            add(buildJsonObject {
                                put("id", m.id)
                                put("key", m.key)
                                put("value", convertAnyCodableValueToJson(m.value))
                            })
                        }
                    })
                })
            }
        }
    }

    /**
     * Converts AnyCodableValue to JsonElement for serialization.
     */
    private fun convertAnyCodableValueToJson(value: AnyCodableValue): JsonElement {
        return when (value) {
            is AnyCodableValue.IntegerValue -> JsonPrimitive(value.value)
            is AnyCodableValue.StringValue -> JsonPrimitive(value.value)
            is AnyCodableValue.FloatValue -> JsonPrimitive(value.value)
            is AnyCodableValue.DoubleValue -> JsonPrimitive(value.value)
            is AnyCodableValue.BooleanValue -> JsonPrimitive(value.value)
            is AnyCodableValue.NullValue -> JsonNull
        }
    }

    /**
     * Clears the error state.
     */
    fun clearError() {
        _error.value = ""
    }

    /**
     * Clears selected category products.
     */
    fun clearSelectedCategoryProducts() {
        _selectedCategoryProducts.value = emptyList()
    }
}
