import '../models/event_model.dart';
import '../../domain/entities/event_category.dart';

abstract class EventLocalDataSource {
  Future<List<EventModel>> getEvents();
  Future<List<EventModel>> getEventsByCategory(EventCategory category);
  Future<EventModel?> getEventById(String id);
  Future<void> cacheEvents(List<EventModel> events);
  Future<void> cacheEvent(EventModel event);
  Future<void> deleteEvent(String id);
}
