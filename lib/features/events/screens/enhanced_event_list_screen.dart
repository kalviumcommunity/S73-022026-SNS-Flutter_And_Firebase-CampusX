import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/event_model.dart';
import '../../../core/models/filter_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/event_filter_provider.dart';
import '../../clubs/providers/club_provider.dart';

/// Enhanced event list screen with search and filters
class EnhancedEventListScreen extends ConsumerStatefulWidget {
  const EnhancedEventListScreen({super.key});

  @override
  ConsumerState<EnhancedEventListScreen> createState() => _EnhancedEventListScreenState();
}

class _EnhancedEventListScreenState extends ConsumerState<EnhancedEventListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(eventFiltersProvider);
    _searchController.text = currentFilters.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(eventFiltersProvider.notifier).setSearchQuery(query);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _EventFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(filteredEventsProvider);
    final filters = ref.watch(eventFiltersProvider);
    final currentUser = ref.watch(currentUserProvider);

    final canCreateEvent = currentUser?.role == 'club_admin' ||
        currentUser?.role == 'college_admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Events',
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
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFF06B6D4),
              ],
            ),
          ),
        ),
        actions: [
          if (canCreateEvent)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/create-event'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search events...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  label: Text(filters.hasActiveFilters ? '${_countActiveFilters(filters)}' : ''),
                  isLabelVisible: filters.hasActiveFilters,
                  child: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showFilterSheet,
                    style: IconButton.styleFrom(
                      backgroundColor: filters.hasActiveFilters
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Filter Chips
          if (filters.hasActiveFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (filters.timeFilter != EventTimeFilter.all)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_getTimeFilterLabel(filters.timeFilter)),
                        onDeleted: () {
                          ref.read(eventFiltersProvider.notifier).setTimeFilter(EventTimeFilter.all);
                        },
                      ),
                    ),
                  if (filters.registrationFilter != EventRegistrationFilter.all)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_getRegistrationFilterLabel(filters.registrationFilter)),
                        onDeleted: () {
                          ref.read(eventFiltersProvider.notifier).setRegistrationFilter(EventRegistrationFilter.all);
                        },
                      ),
                    ),
                  if (filters.clubId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: const Text('Club Filter'),
                        onDeleted: () {
                          ref.read(eventFiltersProvider.notifier).setClubFilter(null);
                        },
                      ),
                    ),
                  if (filters.startDate != null || filters.endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: const Text('Date Range'),
                        onDeleted: () {
                          ref.read(eventFiltersProvider.notifier).clearDateRange();
                        },
                      ),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                    onPressed: () {
                      ref.read(eventFiltersProvider.notifier).reset();
                      _searchController.clear();
                    },
                  ),
                ],
              ),
            ),

          // Events List
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          filters.hasActiveFilters ? 'No events match your filters' : 'No events available',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          filters.hasActiveFilters
                              ? 'Try adjusting your filters'
                              : 'Check back later for upcoming events',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _EventCard(
                      event: event,
                      onTap: () => context.push('/event-detail/${event.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading events',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _countActiveFilters(EventFilters filters) {
    int count = 0;
    if (filters.timeFilter != EventTimeFilter.all) count++;
    if (filters.registrationFilter != EventRegistrationFilter.all) count++;
    if (filters.clubId != null) count++;
    if (filters.startDate != null || filters.endDate != null) count++;
    return count;
  }

  String _getTimeFilterLabel(EventTimeFilter filter) {
    switch (filter) {
      case EventTimeFilter.upcoming:
        return 'Upcoming';
      case EventTimeFilter.past:
        return 'Past';
      case EventTimeFilter.all:
        return 'All';
    }
  }

  String _getRegistrationFilterLabel(EventRegistrationFilter filter) {
    switch (filter) {
      case EventRegistrationFilter.registered:
        return 'Registered';
      case EventRegistrationFilter.notRegistered:
        return 'Not Registered';
      case EventRegistrationFilter.waitlisted:
        return 'Waitlisted';
      case EventRegistrationFilter.all:
        return 'All';
    }
  }
}

/// Filter bottom sheet
class _EventFilterSheet extends ConsumerStatefulWidget {
  const _EventFilterSheet();

  @override
  ConsumerState<_EventFilterSheet> createState() => _EventFilterSheetState();
}

class _EventFilterSheetState extends ConsumerState<_EventFilterSheet> {
  late EventTimeFilter _timeFilter;
  late EventRegistrationFilter _registrationFilter;
  String? _selectedClubId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(eventFiltersProvider);
    _timeFilter = filters.timeFilter;
    _registrationFilter = filters.registrationFilter;
    _selectedClubId = filters.clubId;
    _startDate = filters.startDate;
    _endDate = filters.endDate;
  }

  void _applyFilters() {
    final notifier = ref.read(eventFiltersProvider.notifier);
    notifier.state = EventFilters(
      timeFilter: _timeFilter,
      registrationFilter: _registrationFilter,
      clubId: _selectedClubId,
      startDate: _startDate,
      endDate: _endDate,
      searchQuery: ref.read(eventFiltersProvider).searchQuery,
    );
    Navigator.pop(context);
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(activeClubsStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Time Filter
                    Text(
                      'Time',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<EventTimeFilter>(
                      segments: const [
                        ButtonSegment(
                          value: EventTimeFilter.all,
                          label: Text('All'),
                        ),
                        ButtonSegment(
                          value: EventTimeFilter.upcoming,
                          label: Text('Upcoming'),
                        ),
                        ButtonSegment(
                          value: EventTimeFilter.past,
                          label: Text('Past'),
                        ),
                      ],
                      selected: {_timeFilter},
                      onSelectionChanged: (Set<EventTimeFilter> newSelection) {
                        setState(() => _timeFilter = newSelection.first);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Registration Filter
                    Text(
                      'Registration Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: EventRegistrationFilter.values.map((filter) {
                        return ChoiceChip(
                          label: Text(_getRegistrationLabel(filter)),
                          selected: _registrationFilter == filter,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _registrationFilter = filter);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Club Filter
                    Text(
                      'Club',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    clubsAsync.when(
                      data: (clubs) {
                        return DropdownButtonFormField<String>(
                          value: _selectedClubId,
                          decoration: const InputDecoration(
                            labelText: 'Select Club',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Clubs'),
                            ),
                            ...clubs.map((club) {
                              return DropdownMenuItem(
                                value: club.id,
                                child: Text(club.name),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedClubId = value);
                          },
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Error loading clubs'),
                    ),
                    const SizedBox(height: 24),

                    // Date Range
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _startDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                  : 'Start Date',
                            ),
                            onPressed: _selectStartDate,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _endDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                  : 'End Date',
                            ),
                            onPressed: _selectEndDate,
                          ),
                        ),
                      ],
                    ),
                    if (_startDate != null || _endDate != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                        child: const Text('Clear Date Range'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getRegistrationLabel(EventRegistrationFilter filter) {
    switch (filter) {
      case EventRegistrationFilter.all:
        return 'All';
      case EventRegistrationFilter.registered:
        return 'Registered';
      case EventRegistrationFilter.notRegistered:
        return 'Not Registered';
      case EventRegistrationFilter.waitlisted:
        return 'Waitlisted';
    }
  }
}

/// Event card widget
class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = event.date.isAfter(DateTime.now());
    final theme = Theme.of(context);
    final daysUntil = event.date.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isUpcoming
                    ? [
                        theme.colorScheme.surfaceContainerHighest,
                        theme.colorScheme.surface,
                      ]
                    : [
                        theme.colorScheme.surfaceContainerLow,
                        theme.colorScheme.surfaceContainerLowest,
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUpcoming
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Decorative corner element
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUpcoming
                          ? theme.colorScheme.primary.withValues(alpha: 0.05)
                          : theme.colorScheme.outline.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Status Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isUpcoming
                                    ? [Colors.green.shade400, Colors.green.shade600]
                                    : [Colors.grey.shade400, Colors.grey.shade500],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isUpcoming ? Colors.green : Colors.grey)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUpcoming ? Icons.upcoming_rounded : Icons.history_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isUpcoming ? 'Upcoming' : 'Past',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Description
                      Text(
                        event.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      
                      // Event Details Row
                      Row(
                        children: [
                          // Date Info
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(event.date),
                                          style: theme.textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                        if (isUpcoming && daysUntil >= 0)
                                          Text(
                                            daysUntil == 0
                                                ? 'Today!'
                                                : daysUntil == 1
                                                    ? 'Tomorrow'
                                                    : 'In $daysUntil days',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.onPrimaryContainer
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Location Info
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 18,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSecondaryContainer,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Capacity Bar
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 0.5, // This would need actual registration data
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Capacity: ${event.capacity}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
