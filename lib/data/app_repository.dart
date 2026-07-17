import '../domain/models.dart';

abstract interface class AppRepository {
  Future<AppState> load();
  Future<void> save(AppState state);
  Future<void> replace(AppState state);
}
