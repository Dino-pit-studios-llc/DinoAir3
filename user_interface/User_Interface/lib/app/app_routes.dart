/// Centralized route definitions for the DinoAir Flutter application.
class AppRoutes {
  static const home = '/';

  // Productivity
  static const notes = '/notes';
  static const noteCreate = '/notes/create';
  static const noteDetail = '/notes/:id';
  static String noteDetailPath(String noteId) => '/notes/$noteId';
  static String noteEditPath(String noteId) => '/notes/edit/$noteId';

  static const projects = '/projects';
  static const projectCreate = '/projects/create';
  static const projectDetail = '/projects/:id';
  static String projectDetailPath(String projectId) => '/projects/$projectId';
  static String projectEditPath(String projectId) => '/projects/edit/$projectId';

  static const calendar = '/calendar';
  static const calendarCreate = '/calendar/new';
  static const calendarDetail = '/calendar/:id';
  static String calendarDetailPath(String eventId) => '/calendar/$eventId';
  static String calendarEditPath(String eventId) => '/calendar/$eventId/edit';

  static const fileSearch = '/file-search';
  static const fileSearchDirectories = '/file-search/directories';

  // AI tools
  static const aiChat = '/ai-chat';
  static const translator = '/translator';

  // Crypto suite
  static const cryptoDashboard = '/crypto';
  static const cryptoMarket = '/crypto/market';
  static const cryptoWatchlist = '/crypto/watchlist';
  static const cryptoPortfolio = '/crypto/portfolio';
  static const coinDetail = '/crypto/coin/:id';

  // System
  static const settings = '/settings';
  static const health = '/health';

  static String coinDetailPath(String coinId) => '/crypto/coin/$coinId';

  /// Convenience helper to determine if a location belongs to a route bucket.
  static bool isInRoute(String location, String target) {
    if (location == target) return true;
    if (target == AppRoutes.cryptoDashboard) {
      return location.startsWith('/crypto');
    }
    return location.startsWith('$target/');
  }
}
