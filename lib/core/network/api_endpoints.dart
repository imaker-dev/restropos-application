class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl =
      "https://carrier-symbols-exports-surround.trycloudflare.com/api/v1";

  // Default outlet ID
  static const int defaultOutletId = 4;

  // ============ Authentication ============
  static const String login = "/auth/login";
  static const String loginPin = "/auth/login/pin";
  static const String me = "/auth/me";
  static const String myPermissions = "/permissions/my";

  // ============ Layout (Floors & Sections) ============
  static String floors(int outletId) => "/outlets/$outletId/floors";
  static String sections(int outletId) => "/outlets/$outletId/sections";
  static String floorDetails(int floorId) => "/outlets/floors/$floorId/details";
  static String sectionById(int sectionId) => "/outlets/sections/$sectionId";

  // ============ Tables ============
  static String tablesByFloor(int floorId) => "/tables/floor/$floorId";
  static String tablesByOutlet(int outletId) => "/tables/outlet/$outletId";
  static String tablesRealtime(int outletId) => "/tables/realtime/$outletId";
  static String tableById(int tableId) => "/tables/$tableId";
  static String tableSession(int tableId) => "/tables/$tableId/session";
  static String tableMerge(int tableId) => "/tables/$tableId/merge";
  static String tableMerged(int tableId) => "/tables/$tableId/merged";
  static String tableKots(int tableId) => "/tables/$tableId/kots";

  // ============ Categories ============
  static String categories(int outletId) => "/menu/categories/outlet/$outletId";
  static String categoryTree(int outletId) =>
      "/menu/categories/outlet/$outletId/tree";
  static String categoryById(int categoryId) => "/menu/categories/$categoryId";

  // ============ Menu Items ============
  static String captainMenu(int outletId) => "/menu/$outletId/captain";
  static String captainMenuFiltered(int outletId, String filter) =>
      "/menu/$outletId/captain?filter=$filter";
  static String menuItems(int outletId) => "/menu/items/outlet/$outletId";
  static String itemsByCategory(int categoryId) =>
      "/menu/items/category/$categoryId";
  static String itemById(int itemId) => "/menu/items/$itemId";
  static String itemDetails(int itemId) => "/menu/items/$itemId/details";
  static String searchItems(int outletId) => "/menu/$outletId/search";
  static String featuredItems(int outletId) => "/menu/$outletId/featured";
  static const String calculateItem = "/menu/calculate";

  // ============ Orders ============
  static String activeOrders(int outletId) => "/orders/active/$outletId";
  static String ordersByTable(int tableId) => "/orders/table/$tableId";
  static String orderById(int orderId) => "/orders/$orderId";
  static String captainOrderDetail(int orderId) => "/orders/captain/detail/$orderId";
  static const String ordersList = "/orders";
  static const String createOrder = "/orders";
  static String addOrderItems(int orderId) => "/orders/$orderId/items";
  static String updateItemQuantity(int orderItemId) =>
      "/orders/items/$orderItemId/quantity";
  static String cancelItem(int orderItemId) =>
      "/orders/items/$orderItemId/cancel";
  static String cancelReasons(int outletId) =>
      "/orders/cancel-reasons/$outletId";
  static String transferOrder(int orderId) => "/orders/$orderId/transfer";

  // ============ KOT ============
  static String sendKot(int orderId) => "/orders/$orderId/kot";
  static String activeKots(int outletId) => "/orders/kot/active/$outletId";
  static String kotsByOrder(int orderId) => "/orders/$orderId/kots";
  static String kotById(int kotId) => "/orders/kot/$kotId";
  static String reprintKot(int kotId) => "/orders/kot/$kotId/reprint";
  static String kitchenDashboard(int outletId) =>
      "/orders/station/$outletId/kitchen";
  static String barDashboard(int outletId) => "/orders/station/$outletId/bar";

  // ============ Billing ============
  static String generateBill(int orderId) => "/orders/$orderId/bill";
  static String invoiceByOrder(int orderId) => "/orders/$orderId/invoice";
  static String invoiceById(int invoiceId) => "/orders/invoice/$invoiceId";
  static String duplicateBill(int invoiceId) =>
      "/orders/invoice/$invoiceId/duplicate";

  // ============ Payments ============
  static String paymentsByOrder(int orderId) => "/orders/$orderId/payments";
  static const String processPayment = "/orders/payment";
  static const String splitPayment = "/orders/payment/split";
  static String cashDrawerStatus(int outletId) =>
      "/orders/cash-drawer/$outletId/status";

  // ============ Discounts ============
  static String availableDiscounts(int outletId) => "/tax/discounts/$outletId";
  static String validateDiscount(int outletId) =>
      "/tax/discounts/$outletId/validate";
  static String applyDiscount(int orderId) => "/orders/$orderId/discount";
  static String serviceCharges(int outletId) =>
      "/tax/service-charges/$outletId";

  // ============ Reports ============
  static String liveDashboard(int outletId) =>
      "/orders/reports/$outletId/dashboard";

  // ============ Order History ============
  static String orderHistory(int outletId) => "/orders/captain/history/$outletId";
  static String orderHistoryByDate(int outletId, String fromDate, String toDate) =>
      "/orders/history/$outletId?from=$fromDate&to=$toDate";
  static String orderHistorySummary(int outletId) => "/orders/history/$outletId/summary";
}
