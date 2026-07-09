import 'package:flutter_test/flutter_test.dart';
import 'package:shoefit/services/api_client.dart';
import 'package:shoefit/services/order_service.dart';

void main() {
  test('customer receipt confirmation uses the dedicated endpoint', () async {
    final apiClient = _RecordingApiClient();
    final service = OrderService(apiClient: apiClient);

    await service.confirmOrderReceived(userId: 'user_42', orderId: '17');

    expect(apiClient.lastPath, '/confirm_order_received.php');
    expect(apiClient.lastBody, {'user_id': 'user_42', 'order_id': 17});
  });

  test('customer receipt confirmation requires a logged-in user id', () async {
    final apiClient = _RecordingApiClient();
    final service = OrderService(apiClient: apiClient);

    await expectLater(
      service.confirmOrderReceived(userId: ' ', orderId: '17'),
      throwsException,
    );
    expect(apiClient.lastPath, isNull);
  });
}

class _RecordingApiClient extends ApiClient {
  String? lastPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPath = path;
    lastBody = body;
    return {'success': true};
  }
}
