/// Central location for DinoAir backend REST endpoints.
class ApiEndpoints {
  const ApiEndpoints._();

  // Health & system
  static const String health = '/health';
  static const String metrics = '/metrics';

  // Notes
  static const String notes = '/api/v1/notes';
  static String note(String id) => '$notes/$id';

  // Projects
  static const String projects = '/api/v1/projects';
  static String project(String id) => '$projects/$id';

  // File search
  static const String fileSearch = '/api/v1/file-search';
  static const String fileSearchDirectories = '$fileSearch/directories';

  // AI tools
  static const String aiChat = '/api/v1/ai/chat';
  static const String translator = '/api/v1/translator';
}
