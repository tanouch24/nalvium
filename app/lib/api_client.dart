import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'community_identity.dart';

class ApiException implements Exception {
  final String message;
  final Object? cause;
  const ApiException(this.message, {this.cause});
  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  const ApiClient({String? baseUrl})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'NALVIUM_API_URL',
            defaultValue: 'http://10.0.2.2:8000',
          );

  Future<Map<String, dynamic>> _json(http.Response response) async {
    late final Map<String, dynamic> body;
    try {
      body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException catch (error) {
      throw ApiException('Réponse serveur invalide.', cause: error);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        body['detail']?.toString() ??
            'Le serveur est momentanément indisponible.',
      );
    }
    return body;
  }

  Future<String> createSession({
    String? equipmentId,
    String? assistantThreadId,
    String? actorKey,
  }) async {
    final actor = await CommunityIdentity.id();
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/sessions'),
            headers: {'content-type': 'application/json', 'X-Client-Id': actor},
            body: jsonEncode({
              'equipment_id': equipmentId,
              'assistant_thread_id': assistantThreadId,
              'actor_key': actorKey,
            }),
          )
          .timeout(const Duration(seconds: 12)),
    );
    return (await _json(response))['id'].toString();
  }

  Future<Map<String, dynamic>> getSession(String sessionId) async {
    final response = await _request(
      () => http
          .get(Uri.parse('$baseUrl/v1/sessions/$sessionId'))
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<List<Map<String, dynamic>>> activeSessions() async {
    final response = await _request(
      () => http
          .get(Uri.parse('$baseUrl/v1/sessions/active'))
          .timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(response.body) as List;
    return body
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> equipmentTimeline(
    String equipmentId,
  ) async {
    final response = await _request(
      () => http
          .get(Uri.parse('$baseUrl/v1/equipment/$equipmentId/timeline'))
          .timeout(const Duration(seconds: 20)),
    );
    final body = await _json(response);
    return (body['events'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> activity({
    int limit = 30,
    int offset = 0,
  }) async {
    final response = await _request(
      () => http
          .get(Uri.parse('$baseUrl/v1/activity?limit=$limit&offset=$offset'))
          .timeout(const Duration(seconds: 20)),
    );
    final body = await _json(response);
    return (body['events'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> similarCases(String sessionId) async {
    final response = await _request(
      () => http
          .get(Uri.parse('$baseUrl/v1/sessions/$sessionId/similar-cases'))
          .timeout(const Duration(seconds: 20)),
    );
    final body = await _json(response);
    return (body['cases'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> createAssistantThread({
    String? contextType,
    String? contextId,
    String? equipmentId,
  }) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/assistant/threads'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'context_type': contextType,
              'context_id': contextId,
              'equipment_id': equipmentId,
            }),
          )
          .timeout(const Duration(seconds: 12)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> getAssistantThread(String threadId) async {
    final response = await _request(
      () => http
          .get(Uri.parse('$baseUrl/v1/assistant/threads/$threadId'))
          .timeout(const Duration(seconds: 12)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> sendAssistantMessage({
    required String threadId,
    String text = '',
    String? mediaId,
    String? contextType,
    String? contextId,
  }) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/assistant/threads/$threadId/messages'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'media_id': mediaId,
              'context_type': contextType,
              'context_id': contextId,
            }),
          )
          .timeout(const Duration(seconds: 60)),
    );
    return _json(response);
  }

  Future<String> upload(XFile file, String sessionId) async {
    final bytes = await _readImageBytes(file);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/v1/media'),
    );
    request.fields['session_id'] = sessionId;
    final mime = _detectImageType(bytes, file.name);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
        contentType: mime,
      ),
    );
    final streamed = await _request(
      () => request.send().timeout(const Duration(seconds: 30)),
    );
    final response = await http.Response.fromStream(streamed);
    return (await _json(response))['id'].toString();
  }

  Future<String> uploadVideo(XFile file, String sessionId) async {
    final bytes = await file.readAsBytes();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/v1/media/video'),
    );
    request.fields['session_id'] = sessionId;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
        contentType: _videoType(file.path, file.mimeType),
      ),
    );
    final streamed = await _request(
      () => request.send().timeout(const Duration(seconds: 45)),
    );
    return (await _json(
      await http.Response.fromStream(streamed),
    ))['id'].toString();
  }

  Future<String> transcribeAudio(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/v1/audio/transcribe'),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.path.split('/').last,
        contentType: MediaType('audio', 'm4a'),
      ),
    );
    final streamed = await _request(
      () => request.send().timeout(const Duration(seconds: 60)),
    );
    return (await _json(
          await http.Response.fromStream(streamed),
        ))['text']?.toString() ??
        '';
  }

  MediaType _videoType(String path, String? declared) {
    if (declared != null && declared.startsWith('video/')) {
      return MediaType.parse(declared);
    }
    final lower = path.toLowerCase();
    if (lower.endsWith('.mov')) return MediaType('video', 'quicktime');
    if (lower.endsWith('.webm')) return MediaType('video', 'webm');
    return MediaType('video', 'mp4');
  }

  Future<Map<String, dynamic>> verifyRepair(
    String sessionId,
    String afterMediaId, {
    String text = '',
  }) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/sessions/$sessionId/verify'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'after_media_id': afterMediaId, 'text': text}),
          )
          .timeout(const Duration(seconds: 60)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> createProfessionalDossier({
    required String sessionId,
    String? equipmentId,
    required List<String> mediaIds,
    String summary = '',
    String firstName = '',
    String phone = '',
    String city = '',
    String postalCode = '',
    String desiredTimeWindow = '',
    bool consent = false,
  }) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/professional-dossiers'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'session_id': sessionId,
              'equipment_id': equipmentId,
              'selected_media_ids': mediaIds,
              'summary': summary,
              'first_name': firstName,
              'phone': phone,
              'city': city,
              'postal_code': postalCode,
              'desired_time_window': desiredTimeWindow,
              'consent': consent,
            }),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<Uint8List> _readImageBytes(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const ApiException('Le fichier photo est vide.');
      }
      return bytes;
    } on ApiException {
      rethrow;
    } on FileSystemException catch (error) {
      throw ApiException(
        'La photo sélectionnée n’est plus accessible. Choisissez-la à nouveau.',
        cause: error,
      );
    } catch (error) {
      throw ApiException('La photo n’a pas pu être lue.', cause: error);
    }
  }

  MediaType _detectImageType(Uint8List bytes, String filename) {
    final isJpeg =
        bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff;
    final isPng =
        bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a;
    final isWebp =
        bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
    if (isJpeg) return MediaType('image', 'jpeg');
    if (isPng) return MediaType('image', 'png');
    if (isWebp) return MediaType('image', 'webp');
    throw ApiException(
      'Ce format photo n’est pas pris en charge. Choisissez une image JPEG, PNG ou WebP.',
      cause: filename,
    );
  }

  Future<T> _request<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on SocketException catch (error) {
      throw ApiException(
        'Connexion au serveur impossible. Vérifiez l’adresse du serveur et le réseau du téléphone.',
        cause: error,
      );
    } on HttpException catch (error) {
      throw ApiException('La connexion au serveur a échoué.', cause: error);
    } on TimeoutException catch (error) {
      throw ApiException(
        'Le serveur met trop de temps à répondre.',
        cause: error,
      );
    }
  }

  Future<Map<String, dynamic>> analyze({
    required String sessionId,
    String text = '',
    String? mediaId,
    String? equipmentId,
  }) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/diagnostics/analyze'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'session_id': sessionId,
              'text': text,
              'media_id': mediaId,
              'equipment_id': equipmentId,
            }),
          )
          .timeout(const Duration(seconds: 60)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> identifyEquipment({
    String text = '',
    String? mediaId,
  }) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/equipment/identify'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'text': text, 'media_id': mediaId}),
          )
          .timeout(const Duration(seconds: 60)),
    );
    return _json(response);
  }

  Future<List<Map<String, dynamic>>> listEquipment() async {
    final response = await _request(
      () => http
          .get(Uri.parse('$baseUrl/v1/equipment'))
          .timeout(const Duration(seconds: 20)),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Les équipements n’ont pas pu être chargés.');
    }
    final body = jsonDecode(response.body) as List;
    return body
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> getEquipment(String equipmentId) async {
    final response = await _request(
      () => http
          .get(Uri.parse('$baseUrl/v1/equipment/$equipmentId'))
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> createEquipment(
    Map<String, dynamic> data,
  ) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/equipment'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> updateEquipment(
    String equipmentId,
    Map<String, dynamic> data,
  ) async {
    final response = await _request(
      () => http
          .patch(
            Uri.parse('$baseUrl/v1/equipment/$equipmentId'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<void> deleteEquipment(String equipmentId) async {
    final response = await _request(
      () => http
          .delete(Uri.parse('$baseUrl/v1/equipment/$equipmentId'))
          .timeout(const Duration(seconds: 20)),
    );
    await _json(response);
  }

  Future<Map<String, dynamic>> addEquipmentMedia(
    String equipmentId,
    String mediaId, {
    String mediaType = 'other',
  }) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/equipment/$equipmentId/media'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'media_id': mediaId, 'media_type': mediaType}),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> uploadEquipmentDocument({
    required String equipmentId,
    required XFile file,
    String documentType = 'other',
    String? displayName,
  }) async {
    final bytes = await file.readAsBytes();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/v1/equipment/$equipmentId/documents'),
    );
    request.fields['document_type'] = documentType;
    if (displayName != null) request.fields['display_name'] = displayName;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
        contentType: _documentType(file.path, file.mimeType),
      ),
    );
    final streamed = await _request(
      () => request.send().timeout(const Duration(seconds: 30)),
    );
    return _json(await http.Response.fromStream(streamed));
  }

  MediaType _documentType(String path, String? declared) {
    if (declared != null) return MediaType.parse(declared);
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return MediaType('application', 'pdf');
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    return MediaType('image', 'jpeg');
  }

  Future<Map<String, dynamic>> analyzeDocument(
    String documentId, {
    String text = '',
  }) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/documents/$documentId/analyze'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 60)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> applyDocument(
    String documentId,
    Map<String, dynamic> values,
  ) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/documents/$documentId/apply'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(values),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<List<Map<String, dynamic>>> listDocuments(String equipmentId) async {
    final response = await _request(
      () => http
          .get(Uri.parse('$baseUrl/v1/equipment/$equipmentId/documents'))
          .timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(response.body) as List;
    return body
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> deleteDocument(String documentId) async {
    final response = await _request(
      () => http
          .delete(Uri.parse('$baseUrl/v1/documents/$documentId'))
          .timeout(const Duration(seconds: 20)),
    );
    await _json(response);
  }

  Future<List<Map<String, dynamic>>> listWarranties(String equipmentId) async {
    final response = await _request(
      () => http
          .get(Uri.parse('$baseUrl/v1/equipment/$equipmentId/warranties'))
          .timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(response.body) as List;
    return body
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> createWarranty(
    String equipmentId,
    Map<String, dynamic> values,
  ) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/equipment/$equipmentId/warranties'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(values),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<void> deleteWarranty(String warrantyId) async {
    final response = await _request(
      () => http
          .delete(Uri.parse('$baseUrl/v1/warranties/$warrantyId'))
          .timeout(const Duration(seconds: 20)),
    );
    await _json(response);
  }

  Future<List<Map<String, dynamic>>> listMaintenance(String equipmentId) async {
    final response = await _request(
      () => http
          .get(Uri.parse('$baseUrl/v1/equipment/$equipmentId/maintenance'))
          .timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(response.body) as List;
    return body
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> createMaintenance(
    String equipmentId,
    Map<String, dynamic> values,
  ) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/equipment/$equipmentId/maintenance'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(values),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<void> createLead(Map<String, dynamic> lead) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/leads'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(lead),
          )
          .timeout(const Duration(seconds: 20)),
    );
    await _json(response);
  }

  Future<Map<String, dynamic>> serviceCatalog() async {
    final response = await _request(
      () => http.get(Uri.parse('$baseUrl/v1/service-categories')).timeout(const Duration(seconds: 12)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> supportConfig() async {
    final response = await _request(
      () => http.get(Uri.parse('$baseUrl/v1/support/config')).timeout(const Duration(seconds: 10)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> commerceSearch({
    required String mode,
    required String itemType,
    required String genericName,
    String? purchaseSearchQuery,
    String? postalCode,
    String? city,
    bool safetyStop = false,
  }) async {
    final response = await _request(
      () => http.post(
        Uri.parse('$baseUrl/v1/commerce/search'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'mode': mode,
          'item_type': itemType,
          'generic_name': genericName,
          'purchase_search_query': purchaseSearchQuery,
          'postal_code': postalCode,
          'city': city,
          'safety_stop': safetyStop,
        }),
      ).timeout(const Duration(seconds: 12)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> serviceAvailability(String postalCode) async {
    final response = await _request(
      () => http.get(Uri.parse('$baseUrl/v1/service-availability?postal_code=${Uri.encodeQueryComponent(postalCode)}')).timeout(const Duration(seconds: 12)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> createRepairRequest(Map<String, dynamic> payload) async {
    final actor = await CommunityIdentity.id();
    final key = 'repair-${DateTime.now().microsecondsSinceEpoch}';
    final response = await _request(
      () => http.post(Uri.parse('$baseUrl/v1/repair-requests'), headers: {'content-type': 'application/json', 'X-Client-Id': actor, 'Idempotency-Key': key}, body: jsonEncode(payload)).timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<List<Map<String, dynamic>>> repairRequests() async {
    final actor = await CommunityIdentity.id();
    final response = await _request(
      () => http.get(Uri.parse('$baseUrl/v1/repair-requests'), headers: {'X-Client-Id': actor}).timeout(const Duration(seconds: 12)),
    );
    final body = await _json(response);
    return (body['requests'] as List? ?? []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Map<String, dynamic>> repairRequest(String id) async {
    final actor = await CommunityIdentity.id();
    final response = await _request(
      () => http.get(Uri.parse('$baseUrl/v1/repair-requests/$id'), headers: {'X-Client-Id': actor}).timeout(const Duration(seconds: 12)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> cancelRepairRequest(String id) async {
    final actor = await CommunityIdentity.id();
    final response = await _request(
      () => http.post(Uri.parse('$baseUrl/v1/repair-requests/$id/cancel'), headers: {'X-Client-Id': actor}).timeout(const Duration(seconds: 12)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> createRepair(Map<String, dynamic> repair) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/repairs'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(repair),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> updateRepair(
    String repairId,
    Map<String, dynamic> patch,
  ) async {
    final response = await _request(
      () => http
          .patch(
            Uri.parse('$baseUrl/v1/repairs/$repairId'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(patch),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> shareRepair(
    String repairId, {
    required bool includeBefore,
    required bool includeAfter,
  }) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/repairs/$repairId/share'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'consent': true,
              'include_before': includeBefore,
              'include_after': includeAfter,
            }),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<List<Map<String, dynamic>>> communityPosts({
    required String actorKey,
    String query = '',
    String category = 'all',
    int offset = 0,
    int limit = 20,
    bool saved = false,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/v1/community/posts?q=${Uri.encodeQueryComponent(query)}&category=${Uri.encodeQueryComponent(category)}&offset=$offset&limit=$limit&saved=$saved',
    );
    final response = await _request(
      () => http
          .get(uri, headers: {'X-Client-Id': actorKey})
          .timeout(const Duration(seconds: 20)),
    );
    final body = await _json(response);
    return (body['posts'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> createCommunityPost(
    Map<String, dynamic> data,
    String actorKey,
  ) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/community/posts'),
            headers: {
              'content-type': 'application/json',
              'X-Client-Id': actorKey,
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> publishCommunityPost(
    String postId,
    String actorKey, {
    String? beforeMediaId,
    String? afterMediaId,
    List<String> additionalMediaIds = const [],
  }) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/community/posts/$postId/publish'),
            headers: {
              'content-type': 'application/json',
              'X-Client-Id': actorKey,
            },
            body: jsonEncode({
              'before_media_id': beforeMediaId,
              'after_media_id': afterMediaId,
              'additional_media_ids': additionalMediaIds,
            }),
          )
          .timeout(const Duration(seconds: 30)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> getCommunityPost(
    String postId,
    String actorKey,
  ) async {
    final response = await _request(
      () => http
          .get(
            Uri.parse('$baseUrl/v1/community/posts/$postId'),
            headers: {'X-Client-Id': actorKey},
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> addCommunityComment(
    String postId,
    String actorKey,
    String content, {
    String? parentCommentId,
  }) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/community/posts/$postId/comments'),
            headers: {
              'content-type': 'application/json',
              'X-Client-Id': actorKey,
            },
            body: jsonEncode({
              'content': content,
              'parent_comment_id': parentCommentId,
            }),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> communityAction(
    String postId,
    String actorKey,
    String action, {
    bool enabled = true,
  }) async {
    final response = await _request(
      () => (enabled ? http.post : http.delete)(
        Uri.parse('$baseUrl/v1/community/posts/$postId/$action'),
        headers: {'X-Client-Id': actorKey},
      ).timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }

  Future<Map<String, dynamic>> reportCommunity(
    String actorKey,
    String targetType,
    String targetId,
    String reason, {
    String? note,
  }) async {
    final response = await _request(
      () => http
          .post(
            Uri.parse('$baseUrl/v1/community/reports'),
            headers: {
              'content-type': 'application/json',
              'X-Client-Id': actorKey,
            },
            body: jsonEncode({
              'target_type': targetType,
              'target_id': targetId,
              'reason': reason,
              'note': note,
            }),
          )
          .timeout(const Duration(seconds: 20)),
    );
    return _json(response);
  }
}
