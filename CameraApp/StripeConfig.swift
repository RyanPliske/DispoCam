// Stripe configuration struct
struct StripeConfig {
  #if DEBUG
    static let publishableKey = "pk_test_iUY4JoQxe0LwndEc7jUhJPq6"
  #else
    static let publishableKey = "pk_live_seB3OBvasmB0hsYzF7Efxy48"
  #endif
  
  static let appleMerchantId = "merchant.com.photojojo.dca"
}