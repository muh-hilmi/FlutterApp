import 'dart:convert';
import '../models/event_model.dart';
import '../../domain/entities/event_category.dart';
import '../../core/storage/cache_storage_service.dart';
import 'event_local_datasource.dart';

/// Event local datasource using persistent SharedPreferences storage
/// Survives app restart and device reboots
class EventLocalDataSourceImpl implements EventLocalDataSource {
  final CacheStorageService _cacheStorage;

  EventLocalDataSourceImpl(this._cacheStorage);

  @override
  Future<List<EventModel>> getEvents() async {
    try {
      final cachedJsonList = await _cacheStorage.getEvents();

      if (cachedJsonList.isEmpty) {
        // Return mock data as fallback
        return _getMockEvents();
      }

      // Parse JSON strings back to EventModel objects
      final events = cachedJsonList.map((jsonString) {
        final json = Map<String, dynamic>.from(
          Map.from(jsonDecode(jsonString)),
        );
        return EventModel.fromJson(json);
      }).toList();

      return events;
    } catch (e) {
      // Return mock data on error
      return _getMockEvents();
    }
  }

  @override
  Future<List<EventModel>> getEventsByCategory(EventCategory category) async {
    final events = await getEvents();
    return events.where((event) => event.category == category).toList();
  }

  @override
  Future<EventModel?> getEventById(String id) async {
    final events = await getEvents();
    try {
      return events.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheEvents(List<EventModel> events) async {
    try {
      // Convert EventModel objects to JSON strings for storage
      final jsonStringList = events.map((event) {
        return jsonEncode(event.toJson());
      }).toList();

      await _cacheStorage.saveEvents(jsonStringList);
    } catch (e) {
      // Silent fail - cache is optional
    }
  }

  @override
  Future<void> cacheEvent(EventModel event) async {
    try {
      final currentEvents = await getEvents();
      final index = currentEvents.indexWhere((e) => e.id == event.id);

      if (index != -1) {
        currentEvents[index] = event;
      } else {
        currentEvents.add(event);
      }

      await cacheEvents(currentEvents);
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      final currentEvents = await getEvents();
      currentEvents.removeWhere((event) => event.id == id);
      await cacheEvents(currentEvents);
    } catch (e) {
      // Silent fail
    }
  }

  // Mock data fallback
  List<EventModel> _getMockEvents() {
    const hosts = [
      EventHostModel(
        id: '1',
        name: 'Anya',
        avatar: 'https://doodleipsum.com/100x100/avatar',
        bio: 'Coffee enthusiast, always down for new spots ☕',
        rating: 4.9,
        eventsHosted: 8,
      ),
      EventHostModel(
        id: '2',
        name: 'Rian',
        avatar: 'https://doodleipsum.com/100x100/avatar',
        bio: 'Weekend warrior, futsal addict ⚽',
        isVerified: true,
        rating: 4.7,
        eventsHosted: 15,
      ),
      EventHostModel(
        id: '3',
        name: 'Sari',
        avatar: 'https://doodleipsum.com/100x100/avatar',
        bio: 'Foodie yang selalu tau tempat makan enak 🍜',
        rating: 4.8,
        eventsHosted: 12,
      ),
    ];

    return [
      EventModel(
        id: '1',
        title: 'Ngopi Santai di Menteng',
        description: 'Yuk ngopi bareng sambil ngobrol random! Tempatnya cozy, Wi-Fi kenceng, perfect buat weekend chill. Gw treat kopi pertama hehe ☕',
        category: EventCategory.social,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
        location: const EventLocationModel(
          name: 'Kafe Filosofi Kopi',
          address: 'Jl. Melawai IX No.15, Kebayoran Baru',
          latitude: -6.2431,
          longitude: 106.8031,
        ),
        host: hosts[0],
        imageUrls: const ['https://doodleipsum.com/600x400/food'],
        maxAttendees: 6,
        attendeeIds: const ['user_1', 'user_2'],
        isFree: true,
      ),
      EventModel(
        id: '2',
        title: 'Futsal Sore - Butuh 2 Orang Lagi',
        description: 'Ada yang cancel mendadak! Butuh 2 orang lagi buat main futsal. Level casual aja, yang penting fun. Abis main bisa makan bareng 🍕',
        category: EventCategory.sports,
        startTime: DateTime.now().add(const Duration(hours: 5)),
        endTime: DateTime.now().add(const Duration(hours: 7)),
        location: const EventLocationModel(
          name: 'Futsal Bintaro',
          address: 'Jl. Bintaro Utama 3A, Bintaro',
          latitude: -6.2684,
          longitude: 106.7345,
        ),
        host: hosts[1],
        imageUrls: const ['https://doodleipsum.com/600x400/abstract'],
        maxAttendees: 8,
        attendeeIds: const ['user_3', 'user_4', 'user_5', 'user_6', 'user_7', 'user_8'],
        price: 35000,
        isFree: false,
      ),
      EventModel(
        id: '3',
        title: 'Hunting Kuliner Pecenongan',
        description: 'Mau cobain street food terenak di Jakarta? Join gw keliling Pecenongan! Gw udah riset tempat-tempat yang wajib dicoba. Perut kosong wajib! 🍜',
        category: EventCategory.food,
        startTime: DateTime.now().add(const Duration(days: 1, hours: 18)),
        endTime: DateTime.now().add(const Duration(days: 1, hours: 21)),
        location: const EventLocationModel(
          name: 'Pecenongan Street',
          address: 'Jl. Pecenongan, Jakarta Pusat',
          latitude: -6.1620,
          longitude: 106.8237,
        ),
        host: hosts[2],
        imageUrls: const ['https://doodleipsum.com/600x400/food'],
        maxAttendees: 4,
        attendeeIds: const ['user_9'],
        price: 100000,
        isFree: false,
      ),
    ];
  }
}
