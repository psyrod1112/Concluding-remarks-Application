import 'dart:convert';
import 'package:http/http.dart' as http;

/// 백엔드 서버 주소 설정
/// - 웹 브라우저 / iOS 시뮬레이터: localhost
/// - Android 에뮬레이터: 10.0.2.2 (에뮬레이터에서 호스트 PC를 가리키는 주소)
/// - 실제 기기: 서버 PC의 로컬 IP (예: 192.168.0.10)
const String _baseUrl = 'http://43.201.247.193';

class ApiClient {
  static String? _accessToken;
  static String? _refreshToken;

  static String get baseUrl => _baseUrl;

  static String? get accessToken => _accessToken;

  static Uri get webSocketUri {
    final uri = Uri.parse(_baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: scheme);
  }

  /// 로그인 성공 시 토큰 저장
  static void setTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// 로그아웃 시 토큰 초기화
  static void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  static String? get refreshToken => _refreshToken;

  /// 모든 요청에 공통으로 붙는 헤더
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  /// POST 요청
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  /// GET 요청
  static Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
    );
    return _parse(response);
  }

  /// 응답 파싱 — 2xx면 Map 반환, 그 외면 ApiException throw
  static Map<String, dynamic> _parse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? '서버 오류가 발생했습니다.',
    );
  }
}

/// 백엔드가 4xx / 5xx 에러를 내렸을 때 던지는 예외
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
