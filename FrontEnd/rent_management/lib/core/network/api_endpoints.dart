class ApiEndpoints {
  ApiEndpoints._();

  // Android emulator -> host machine's localhost is 10.0.2.2, NOT 127.0.0.1/localhost.
  // iOS simulator can use localhost directly. A physical device needs your machine's
  // LAN IP instead. Swap this to your Render/Railway URL once deployed.
  static const String baseUrl =
      'https://rentmanagementsystem-brdv.onrender.com';
  //   static const String baseUrl = 'http://10.212.135.86:8080';

  static const String register = '/auth/register';
  static const String login = '/auth/login';

  static const String properties = '/properties';
  static String propertyById(int id) => '/properties/$id';
  static const String adminProperties = '/admin/properties';
  static String adminPropertyById(int id) => '/admin/properties/$id';
  static String adminPropertyActive(int id) => '/admin/properties/$id/active';

  static const String rentalRequests = '/rental-requests';
  static const String myRentalRequests = '/rental-requests/mine';
  static String rentalRequestById(int id) => '/rental-requests/$id';
  static String rentalRequestReturnRequest(int id) =>
      '/rental-requests/$id/return-request';
  static const String adminRentalRequests = '/admin/rental-requests';
  static String adminRentalRequestDecision(int id) =>
      '/admin/rental-requests/$id/decision';
  static String adminRentalRequestReturnDecision(int id) =>
      '/admin/rental-requests/$id/return-decision';

  static const String myBills = '/bills/mine';
  static String billsByRentalRequest(int rentalRequestId) =>
      '/rental-requests/$rentalRequestId/bills';
  static String billClaimPayment(int billId) => '/bills/$billId/claim-payment';
  static String adminBillVerify(int billId) => '/admin/bills/$billId/verify';
  static String adminBillRefund(int billId) => '/admin/bills/$billId/refund';

  static const String adminUsersPending = '/admin/users/pending';
  static const String adminUsers = '/admin/users';
  static String adminUserApprove(int userId) => '/admin/users/$userId/approve';

  static const String adminUploadPropertyImage =
      '/admin/uploads/property-image';
  static const String uploadPaymentProofImage = '/uploads/payment-proof-image';
}
