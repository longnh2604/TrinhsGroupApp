package com.trinhsgroup.shared.viewmodel

import com.trinhsgroup.shared.model.AddOnGroup
import com.trinhsgroup.shared.model.AppSetting
import com.trinhsgroup.shared.model.Category
import com.trinhsgroup.shared.model.Coupon
import com.trinhsgroup.shared.model.Order
import com.trinhsgroup.shared.model.OrderQuote
import com.trinhsgroup.shared.model.Payment
import com.trinhsgroup.shared.model.Product
import com.trinhsgroup.shared.model.ProductOrder
import com.trinhsgroup.shared.model.ShipMethod
import com.trinhsgroup.shared.model.Slider
import com.trinhsgroup.shared.model.User
import com.trinhsgroup.shared.model.Zone
import com.trinhsgroup.shared.service.MainService
import com.trinhsgroup.shared.storage.FavoritesRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch

/**
 * Enum for different view presentation types.
 * Mirrors Swift's PresentedType enum.
 */
enum class PresentedType {
    CHECK_OUT,
    PRODUCT_DETAIL,
    ORDER_RECEIVED,
    CART,
    NONE,
    EDIT_USER_INFO,
    ORDER_HISTORY
}

/**
 * Shared ViewModel for main app functionality including cart, categories, products.
 * Mirrors Swift's MainViewModel class.
 *
 * Note: On Android, wrap this in an AndroidX ViewModel.
 * On iOS, use this directly with lifecycle management.
 */
class MainViewModel(
    private val service: MainService,
    private val favoritesRepository: FavoritesRepository
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // UI State
    private val _appSetting = MutableStateFlow<AppSetting?>(null)
    val appSetting: StateFlow<AppSetting?> = _appSetting.asStateFlow()

    private val _showLoading = MutableStateFlow(false)
    val showLoading: StateFlow<Boolean> = _showLoading.asStateFlow()

    private val _showNewSeason = MutableStateFlow(false)
    val showNewSeason: StateFlow<Boolean> = _showNewSeason.asStateFlow()

    private val _showCart = MutableStateFlow(false)
    val showCart: StateFlow<Boolean> = _showCart.asStateFlow()

    private val _showDiscount = MutableStateFlow(false)
    val showDiscount: StateFlow<Boolean> = _showDiscount.asStateFlow()

    private val _showCategoryProducts = MutableStateFlow(true)
    val showCategoryProducts: StateFlow<Boolean> = _showCategoryProducts.asStateFlow()

    private val _showDetail = MutableStateFlow(false)
    val showDetail: StateFlow<Boolean> = _showDetail.asStateFlow()

    private val _showCheckout = MutableStateFlow(false)
    val showCheckout: StateFlow<Boolean> = _showCheckout.asStateFlow()

    private val _showOrderReceived = MutableStateFlow(false)
    val showOrderReceived: StateFlow<Boolean> = _showOrderReceived.asStateFlow()

    private val _message = MutableStateFlow("")
    val message: StateFlow<String> = _message.asStateFlow()

    private val _presentedType = MutableStateFlow(PresentedType.NONE)
    val presentedType: StateFlow<PresentedType> = _presentedType.asStateFlow()

    private val _isCategoryProductsLoading = MutableStateFlow(false)
    val isCategoryProductsLoading: StateFlow<Boolean> = _isCategoryProductsLoading.asStateFlow()

    // Data
    private val _sliders = MutableStateFlow<List<Slider>>(emptyList())
    val sliders: StateFlow<List<Slider>> = _sliders.asStateFlow()

    private val _items = MutableStateFlow<List<Product>>(emptyList())
    val items: StateFlow<List<Product>> = _items.asStateFlow()

    private val _products = MutableStateFlow<List<Product>>(emptyList())
    val products: StateFlow<List<Product>> = _products.asStateFlow()

    private val _selectedProduct = MutableStateFlow<Product?>(null)
    val selectedProduct: StateFlow<Product?> = _selectedProduct.asStateFlow()

    private val _categories = MutableStateFlow<List<Category>>(emptyList())
    val categories: StateFlow<List<Category>> = _categories.asStateFlow()

    private val _subcategories = MutableStateFlow<List<Category>>(emptyList())
    val subcategories: StateFlow<List<Category>> = _subcategories.asStateFlow()

    private val _categoryProducts = MutableStateFlow<List<Product>>(emptyList())
    val categoryProducts: StateFlow<List<Product>> = _categoryProducts.asStateFlow()

    private val _selectedCategory = MutableStateFlow(Category.Default)
    val selectedCategory: StateFlow<Category> = _selectedCategory.asStateFlow()

    private val _selectedSubCategory = MutableStateFlow(Category.Default)
    val selectedSubCategory: StateFlow<Category> = _selectedSubCategory.asStateFlow()

    private val _selectedShip = MutableStateFlow(ShipMethod.Default)
    val selectedShip: StateFlow<ShipMethod> = _selectedShip.asStateFlow()

    private val _shipMethods = MutableStateFlow<List<ShipMethod>>(emptyList())
    val shipMethods: StateFlow<List<ShipMethod>> = _shipMethods.asStateFlow()

    private val _coupon = MutableStateFlow(Coupon.Default)
    val coupon: StateFlow<Coupon> = _coupon.asStateFlow()

    private val _selectedPayment = MutableStateFlow<Payment?>(null)
    val selectedPayment: StateFlow<Payment?> = _selectedPayment.asStateFlow()

    private val _receivedOrder = MutableStateFlow(Order.Default)
    val receivedOrder: StateFlow<Order> = _receivedOrder.asStateFlow()

    private val _payments = MutableStateFlow<List<Payment>>(emptyList())
    val payments: StateFlow<List<Payment>> = _payments.asStateFlow()

    private val _zones = MutableStateFlow<List<Zone>>(emptyList())
    val zones: StateFlow<List<Zone>> = _zones.asStateFlow()

    private val _popularProducts = MutableStateFlow<List<Product>>(emptyList())
    val popularProducts: StateFlow<List<Product>> = _popularProducts.asStateFlow()

    // Favorites
    private val _favoriteProductIDs = MutableStateFlow<Set<Int>>(emptySet())
    val favoriteProductIDs: StateFlow<Set<Int>> = _favoriteProductIDs.asStateFlow()

    private val _favoriteProducts = MutableStateFlow<List<Product>>(emptyList())
    val favoriteProducts: StateFlow<List<Product>> = _favoriteProducts.asStateFlow()

    // Navigation
    private val _categoryToNavigate = MutableStateFlow<Category?>(null)
    val categoryToNavigate: StateFlow<Category?> = _categoryToNavigate.asStateFlow()

    // ============ Computed Properties (Cart Math) ============

    /**
     * Total number of items in cart.
     * Mirrors Swift's numberOfItems computed property.
     */
    val numberOfItems: Int
        get() {
            val cartItems = _items.value
            return if (cartItems.isNotEmpty()) {
                cartItems.sumOf { it.quantity }
            } else {
                0
            }
        }

    /**
     * Total discounts (difference between regular price and sale price).
     * Mirrors Swift's discounts computed property.
     */
    val discounts: Double
        get() {
            val cartItems = _items.value
            return if (cartItems.isNotEmpty()) {
                cartItems.sumOf { (it.regularPrice - it.price) * it.quantity.toDouble() }
            } else {
                0.0
            }
        }

    /**
     * Subtotal (sum of price * quantity for all items).
     * Mirrors Swift's subtotal computed property.
     */
    val subtotal: Double
        get() {
            val cartItems = _items.value
            return if (cartItems.isNotEmpty()) {
                cartItems.sumOf { it.price * it.quantity.toDouble() }
            } else {
                0.0
            }
        }

    /**
     * Total of regular prices (before any discounts).
     * Mirrors Swift's regularPriceTotal computed property.
     */
    val regularPriceTotal: Double
        get() {
            val cartItems = _items.value
            return if (cartItems.isNotEmpty()) {
                cartItems.sumOf { it.regularPrice * it.quantity.toDouble() }
            } else {
                0.0
            }
        }

    /**
     * Total amount (subtotal + shipping cost).
     * Mirrors Swift's total computed property.
     */
    val total: Double
        get() {
            val shippingCost = _selectedShip.value.settings.cost.value.toDoubleOrNull() ?: 0.0
            return if (_items.value.isNotEmpty()) {
                subtotal + shippingCost
            } else {
                shippingCost
            }
        }

    /**
     * Fixed discount amount from coupon (for fixed_cart type coupons).
     * Mirrors Swift's fixedDiscount computed property.
     */
    val fixedDiscount: Double
        get() {
            val currentCoupon = _coupon.value
            return if (currentCoupon.id != Coupon.Default.id) {
                currentCoupon.amount?.toDoubleOrNull() ?: 0.0
            } else {
                0.0
            }
        }

    /**
     * Percent discount amount from coupon (for percent type coupons).
     * Mirrors Swift's percentDiscount computed property.
     */
    val percentDiscount: Double
        get() {
            val currentCoupon = _coupon.value
            return if (currentCoupon.id != Coupon.Default.id) {
                val percentage = currentCoupon.amount?.toDoubleOrNull() ?: 0.0
                total * (percentage / 100.0)
            } else {
                0.0
            }
        }

    init {
        bindingData()
        loadFavoritesFromStorage()
    }

    private fun bindingData() {
        service.isLoading.onEach { isLoading ->
            _showLoading.value = isLoading
        }.launchIn(scope)

        service.isCategoryProductsLoading.onEach { isLoading ->
            _isCategoryProductsLoading.value = isLoading
        }.launchIn(scope)

        service.error.onEach { error ->
            _message.value = error
        }.launchIn(scope)

        service.categories.onEach { categories ->
            _categories.value = categories
        }.launchIn(scope)

        service.selectedCategoryProducts.onEach { products ->
            _categoryProducts.value = products
        }.launchIn(scope)

        service.order.onEach { order ->
            if (order.id != Order.Default.id) {
                _receivedOrder.value = order
            }
        }.launchIn(scope)

        service.popularProducts.onEach { products ->
            _popularProducts.value = products
        }.launchIn(scope)

        service.payments.onEach { payments ->
            _payments.value = payments
        }.launchIn(scope)
    }

    // ============ Cart Operations ============

    /**
     * Gets the number of a specific item in cart.
     * Mirrors Swift's getNumberOfInCart(item:) method.
     */
    fun getNumberOfInCart(item: Product): Int {
        return _items.value.find { it.id == item.id }?.quantity ?: 0
    }

    /**
     * Adds an item to cart.
     * If item with same cartIdentifier exists, increments quantity.
     * Otherwise, adds as new item with quantity 1.
     * Mirrors Swift's add(item:) method.
     */
    fun add(item: Product) {
        val currentItems = _items.value.toMutableList()
        val index = currentItems.indexOfFirst { it.cartIdentifier == item.cartIdentifier }

        if (index != -1) {
            currentItems[index] = currentItems[index].withQuantity(currentItems[index].quantity + 1)
        } else {
            currentItems.add(item.withQuantity(1))
        }
        _items.value = currentItems
    }

    /**
     * Removes one quantity of an item from cart.
     * If quantity becomes 0, removes the item entirely.
     * Mirrors Swift's remove(item:) method.
     */
    fun remove(item: Product) {
        val currentItems = _items.value.toMutableList()
        val index = currentItems.indexOfFirst { it.cartIdentifier == item.cartIdentifier }

        if (index != -1) {
            if (currentItems[index].quantity > 1) {
                currentItems[index] = currentItems[index].withQuantity(currentItems[index].quantity - 1)
            } else {
                currentItems.removeAt(index)
            }
            _items.value = currentItems
        }
    }

    /**
     * Removes all quantities of an item from cart.
     * Mirrors Swift's removeAll(item:) method.
     */
    fun removeAll(item: Product) {
        val currentItems = _items.value.toMutableList()
        val index = currentItems.indexOfFirst { it.cartIdentifier == item.cartIdentifier }

        if (index != -1) {
            currentItems.removeAt(index)
            _items.value = currentItems
        }
    }

    /**
     * Clears the entire cart.
     * Mirrors Swift's reset() method.
     */
    fun reset() {
        _items.value = emptyList()
    }

    // ============ Service Operations ============

    fun onFetchCategories() {
        scope.launch {
            service.onFetchCategories()
        }
    }

    fun onFetchPopularProducts() {
        scope.launch {
            service.onFetchPopularProducts()
        }
    }

    fun onFetchSelectedCategoryProducts(categoryId: Int) {
        scope.launch {
            service.fetchSelectedCategoryProducts(categoryId = categoryId)
        }
    }

    fun onFetchPaymentMethods() {
        scope.launch {
            service.onFetchPaymentMethods()
        }
    }

    /**
     * Add-on groups for one product. Handed to the caller so each product screen owns its own
     * set of ticks. Mirrors Swift's onFetchAddOnGroups().
     */
    fun onFetchAddOnGroups(productId: Int, completion: (List<AddOnGroup>) -> Unit) {
        scope.launch {
            completion(service.fetchAddOnGroups(productId))
        }
    }

    /**
     * Prices the current basket server-side. Nothing is created.
     * Mirrors Swift's onFetchOrderQuote method.
     *
     * The payment method is part of the question, not decoration: the cash-on-pickup
     * discount is a negative gateway fee, so the total depends on the gateway chosen.
     */
    fun onFetchOrderQuote(
        productOrders: List<ProductOrder>,
        couponCode: String? = null,
        completion: (OrderQuote?) -> Unit
    ) {
        scope.launch {
            completion(
                service.fetchOrderQuote(
                    paymentMethod = _selectedPayment.value?.id ?: "",
                    productOrders = productOrders,
                    couponCode = couponCode
                )
            )
        }
    }

    /**
     * Creates an order.
     * Sets status based on payment method (stripe = pending, otherwise = on-hold).
     * Mirrors Swift's onCreateOrder method.
     */
    fun onCreateOrder(
        user: User,
        productOrders: List<ProductOrder>,
        pickupDateTime: String,
        couponCode: String? = null,
        completion: (orderId: Int?, paymentURL: String?) -> Unit
    ) {
        val payment = _selectedPayment.value
        if (payment == null) {
            completion(null, null)
            return
        }

        // Set order status based on payment method
        // Stripe payment (credit card) -> pending (awaiting payment)
        // Other payment methods (cash on pickup, etc.) -> on-hold
        val desiredStatus = if (payment.id.lowercase() == "stripe") {
            "pending"
        } else {
            "on-hold"
        }

        // The discount is computed server-side from catalog prices, so it cannot be
        // inflated by a tampered request.
        scope.launch {
            val result = service.onCreateOrder(
                user = user,
                paymentMethod = payment.id,
                paymentMethodTitle = payment.title,
                customerNote = "",
                status = desiredStatus,
                productOrders = productOrders,
                pickupDateTime = pickupDateTime,
                couponCode = couponCode
            )
            completion(result.first, result.second)
        }
    }

    // ============ Favorites ============

    /**
     * Loads favorites from storage.
     * Mirrors Swift's loadFavoritesFromStorage() method.
     */
    fun loadFavoritesFromStorage() {
        val stored = favoritesRepository.loadFavorites()
        _favoriteProducts.value = stored
        _favoriteProductIDs.value = stored.map { it.id }.toSet()
    }

    /**
     * Checks if a product is a favorite.
     * Mirrors Swift's isFavorite(productId:) method.
     */
    fun isFavorite(productId: Int): Boolean {
        return _favoriteProductIDs.value.contains(productId)
    }

    /**
     * Toggles a product's favorite status.
     * Mirrors Swift's toggleFavorite(product:) method.
     */
    fun toggleFavorite(product: Product) {
        val currentIds = _favoriteProductIDs.value.toMutableSet()
        val currentProducts = _favoriteProducts.value.toMutableList()

        if (currentIds.contains(product.id)) {
            // Remove from favorites
            currentIds.remove(product.id)
            currentProducts.removeAll { it.id == product.id }
            favoritesRepository.removeFavorite(product)
        } else {
            // Add to favorites
            currentIds.add(product.id)
            currentProducts.add(product)
            favoritesRepository.saveFavorite(product)
        }

        _favoriteProductIDs.value = currentIds
        _favoriteProducts.value = currentProducts
    }

    // ============ Setters ============

    fun setSelectedProduct(product: Product?) {
        _selectedProduct.value = product
    }

    fun setSelectedCategory(category: Category) {
        _selectedCategory.value = category
    }

    fun setSelectedSubCategory(category: Category) {
        _selectedSubCategory.value = category
    }

    fun setSelectedShip(shipMethod: ShipMethod) {
        _selectedShip.value = shipMethod
    }

    fun setSelectedPayment(payment: Payment?) {
        _selectedPayment.value = payment
    }

    fun setCoupon(coupon: Coupon) {
        _coupon.value = coupon
    }

    fun setPresentedType(type: PresentedType) {
        _presentedType.value = type
    }

    fun setShowCart(show: Boolean) {
        _showCart.value = show
    }

    fun setShowDetail(show: Boolean) {
        _showDetail.value = show
    }

    fun setShowCheckout(show: Boolean) {
        _showCheckout.value = show
    }

    fun setShowOrderReceived(show: Boolean) {
        _showOrderReceived.value = show
    }

    fun setCategoryToNavigate(category: Category?) {
        _categoryToNavigate.value = category
    }

    fun clearMessage() {
        _message.value = ""
    }

    /**
     * Finds a product by ID from all available product lists.
     * Searches in popularProducts, categoryProducts, and favoriteProducts.
     */
    fun findProductById(productId: Int): Product? {
        return _popularProducts.value.find { it.id == productId }
            ?: _categoryProducts.value.find { it.id == productId }
            ?: _favoriteProducts.value.find { it.id == productId }
            ?: _products.value.find { it.id == productId }
    }

    /**
     * Selects a product by ID for viewing details.
     * Mirrors iOS behavior of setting selectedProduct.
     */
    fun selectProductById(productId: Int) {
        val product = findProductById(productId)
        _selectedProduct.value = product
    }
}
