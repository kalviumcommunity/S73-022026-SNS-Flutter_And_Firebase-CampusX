import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/services/club_service.dart';
import '../../../core/services/event_service.dart';
import '../../../models/club_model.dart';
import '../../../models/event_model.dart';

/// Calendar view mode
enum CalendarView { day, week, month }

/// Provider for all events in the calendar
final calendarEventsProvider = StreamProvider<List<EventModel>>((ref) {
  final eventService = EventService();
  return eventService.getAllEvents();
});

/// Provider for clubs (for color-coding)
final calendarClubsProvider = StreamProvider<List<ClubModel>>((ref) {
  final clubService = ClubService();
  return clubService.getActiveClubs();
});

/// Calendar screen with day/week/month views
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  CalendarView _viewMode = CalendarView.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<EventModel>> _eventsByDate = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  /// Get events for a specific day
  List<EventModel> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _eventsByDate[key] ?? [];
  }

  /// Build events map from event list
  void _buildEventsMap(List<EventModel> events) {
    _eventsByDate.clear();
    for (final event in events) {
      final key = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      if (_eventsByDate.containsKey(key)) {
        _eventsByDate[key]!.add(event);
      } else {
        _eventsByDate[key] = [event];
      }
    }
  }

  /// Get color for club
  Color _getClubColor(String clubId, List<ClubModel> clubs) {
    final clubIndex = clubs.indexWhere((club) => club.id == clubId);
    if (clubIndex == -1) return Colors.blue;

    // Generate consistent colors for clubs
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];

    return colors[clubIndex % colors.length];
  }

  /// Add event to device calendar
  Future<void> _addToDeviceCalendar(EventModel event) async {
    try {
      final calendarEvent = Event(
        title: event.title,
        description: event.description,
        location: event.location,
        startDate: event.date,
        endDate: event.date.add(const Duration(hours: 2)), // Default 2-hour duration
        allDay: false,
      );

      final result = await Add2Calendar.addEvent2Cal(calendarEvent);
      
      if (mounted && result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event added to calendar successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to calendar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider);
    final clubsAsync = ref.watch(calendarClubsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black38,
              ),
            ],
          ),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFF06B6D4),
              ],
            ),
          ),
        ),
        actions: [
          // View mode toggle
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.view_module),
            tooltip: 'Change view',
            onSelected: (view) {
              setState(() {
                _viewMode = view;
                if (view == CalendarView.day) {
                  _calendarFormat = CalendarFormat.week;
                } else if (view == CalendarView.week) {
                  _calendarFormat = CalendarFormat.twoWeeks;
                } else {
                  _calendarFormat = CalendarFormat.month;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: CalendarView.day,
                child: Row(
                  children: [
                    Icon(_viewMode == CalendarView.day ? Icons.check : null),
                    const SizedBox(width: 8),
                    const Text('Day View'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: CalendarView.week,
                child: Row(
                  children: [
                    Icon(_viewMode == CalendarView.week ? Icons.check : null),
                    const SizedBox(width: 8),
                    const Text('Week View'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: CalendarView.month,
                child: Row(
                  children: [
                    Icon(_viewMode == CalendarView.month ? Icons.check : null),
                    const SizedBox(width: 8),
                    const Text('Month View'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading events: $error'),
            ],
          ),
        ),
        data: (events) {
          _buildEventsMap(events);

          return clubsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const Center(child: Text('Error loading clubs')),
            data: (clubs) {
              return Column(
                children: [
                  // Calendar widget
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: TableCalendar<EventModel>(
                      firstDay: DateTime.utc(2024, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarFormat: _calendarFormat,
                      eventLoader: _getEventsForDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        weekendTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonShowsNext: false,
                        formatButtonDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          if (events.isEmpty) return const SizedBox();

                          // Show multiple color markers for different clubs
                          return Positioned(
                            bottom: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: events.take(3).map((event) {
                                final clubColor = _getClubColor(event.clubId, clubs);
                                return Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: clubColor,
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // View mode indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _viewMode == CalendarView.day
                              ? Icons.view_day
                              : _viewMode == CalendarView.week
                                  ? Icons.view_week
                                  : Icons.view_module,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDay != null
                              ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!)
                              : 'Select a date',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Events list for selected day
                  Expanded(
                    child: _selectedDay == null
                        ? const Center(child: Text('Select a date to view events'))
                        : _buildEventsList(
                            _getEventsForDay(_selectedDay!),
                            clubs,
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Build list of events for selected day
  Widget _buildEventsList(List<EventModel> events, List<ClubModel> clubs) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 60,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No events on this day',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      );
    }

    // Sort events by time
    events.sort((a, b) => a.date.compareTo(b.date));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final club = clubs.firstWhere(
          (c) => c.id == event.clubId,
          orElse: () => ClubModel(
            id: '',
            name: 'Unknown Club',
            description: '',
            createdBy: '',
            adminIds: const [],
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
          ),
        );
        final clubColor = _getClubColor(event.clubId, clubs);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            onTap: () => context.push('/event-detail/${event.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Club color indicator
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: clubColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Event details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('h:mm a').format(event.date),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: clubColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            club.name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: clubColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Add to calendar button
                  IconButton(
                    icon: const Icon(Icons.add_to_photos),
                    tooltip: 'Add to device calendar',
                    onPressed: () => _addToDeviceCalendar(event),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
