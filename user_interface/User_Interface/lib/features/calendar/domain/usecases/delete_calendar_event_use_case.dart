import '../calendar_event_repository.dart';

class DeleteCalendarEventUseCase {
  final CalendarEventRepository repository;

  DeleteCalendarEventUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteEvent(id);
  }
}
