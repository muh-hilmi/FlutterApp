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

class EventLocalDataSourceImpl implements EventLocalDataSource {
  // Mock data for now - in real implementation this would use a local database
  final List<EventModel> _cachedEvents = [];

  @override
  Future<List<EventModel>> getEvents() async {
    // Return mock data for now
    return _getMockEvents();
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
    _cachedEvents.clear();
    _cachedEvents.addAll(events);
  }

  @override
  Future<void> cacheEvent(EventModel event) async {
    final index = _cachedEvents.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _cachedEvents[index] = event;
    } else {
      _cachedEvents.add(event);
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    _cachedEvents.removeWhere((event) => event.id == id);
  }

  List<EventModel> _getMockEvents() {
    // Mock hosts
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
        // tags: const ['Coffee', 'Chill', 'Weekend'],
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
        // tags: const ['Futsal', 'Sports', 'After Work'],
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
        // tags: const ['Street Food', 'Jakarta', 'Adventure'],
      ),
    ];
  }
}