import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/club_service.dart';
import '../../../models/club_model.dart';
import '../../../models/event_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/event_provider.dart';

/// Provider for clubs where user is admin
final userAdminClubsForEventProvider = StreamProvider<List<ClubModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final clubService = ClubService();
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return clubService.getClubsByAdmin(user.uid);
});

/// Screen for creating a new event (club_admin only)
class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();

  String? _selectedClubId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operationState = ref.watch(eventOperationsProvider);
    final currentUser = ref.watch(authProvider).user;
    final adminClubsAsync = ref.watch(userAdminClubsForEventProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        elevation: 0,
      ),
      body: operationState.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creating event...'),
                ],
              ),
            )
          : adminClubsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                  ],
                ),
              ),
              data: (clubs) {
                if (clubs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60),
                        const SizedBox(height: 16),
                        const Text(
                          'You are not assigned as admin to any club',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please contact the college admin',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-select first club if not already selected
                if (_selectedClubId == null && clubs.isNotEmpty) {
                  _selectedClubId = clubs.first.id;
                }

                return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      'Event Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in the information below to create a new event',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        hintText: 'Enter event title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an event title';
                        }
                        if (value.trim().length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter event description',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.trim().length < 10) {
                          return 'Description must be at least 10 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Club Selection (automatic or dropdown)
                    if (clubs.length == 1)
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Club',
                          prefixIcon: Icon(Icons.group),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          clubs.first.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedClubId,
                        decoration: const InputDecoration(
                          labelText: 'Select Club',
                          prefixIcon: Icon(Icons.group),
                          border: OutlineInputBorder(),
                          helperText: 'Choose which club is organizing this event',
                        ),
                        items: clubs.map((club) {
                          return DropdownMenuItem<String>(
                            value: club.id,
                            child: Text(club.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedClubId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a club';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),

                    // Date Picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Event Date',
                          hintText: 'Select event date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: const OutlineInputBorder(),
                          errorText: _selectedDate == null && _formKey.currentState?.validate() == false
                              ? 'Please select a date'
                              : null,
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Tap to select date'
                              : DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Theme.of(context).hintColor
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Picker
                    InkWell(
                      onTap: () => _selectTime(context),
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Event Time',
                          hintText: 'Select event time',
                          prefixIcon: const Icon(Icons.access_time),
                          border: const OutlineInputBorder(),
                          errorText: _selectedTime == null && _formKey.currentState?.validate() == false
                              ? 'Please select a time'
                              : null,
                        ),
                        child: Text(
                          _selectedTime == null
                              ? 'Tap to select time'
                              : _selectedTime!.format(context),
                          style: TextStyle(
                            color: _selectedTime == null
                                ? Theme.of(context).hintColor
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location Field
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'Enter event location',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Capacity Field
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'Capacity',
                        hintText: 'Enter maximum attendees',
                        prefixIcon: Icon(Icons.people),
                        border: OutlineInputBorder(),
                        suffixText: 'people',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter capacity';
                        }
                        final capacity = int.tryParse(value);
                        if (capacity == null || capacity <= 0) {
                          return 'Please enter a valid number greater than 0';
                        }
                        if (capacity > 10000) {
                          return 'Capacity cannot exceed 10,000';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (operationState.error != null)
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  operationState.error!,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Create Button
                    FilledButton.icon(
                      onPressed: operationState.isLoading
                          ? null
                          : () => _handleCreateEvent(context, currentUser?.uid),
                      icon: const Icon(Icons.check),
                      label: const Text('Create Event'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cancel Button
                    OutlinedButton.icon(
                      onPressed: operationState.isLoading
                          ? null
                          : () => context.pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
              },
            ),
    );
  }

  /// Show date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  /// Show time picker dialog
  Future<void> _selectTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  /// Handle event creation
  Future<void> _handleCreateEvent(BuildContext context, String? userId) async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check date and time
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check user ID
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Combine date and time
    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (_selectedClubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a club'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create event model
    final event = EventModel(
      id: '', // Will be generated by Firestore
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      clubId: _selectedClubId!,
      createdBy: userId,
      date: eventDateTime,
      location: _locationController.text.trim(),
      capacity: int.parse(_capacityController.text.trim()),
      createdAt: DateTime.now(),
    );

    // Create event using provider
    final eventId = await ref
        .read(eventOperationsProvider.notifier)
        .createEvent(event, userId!);

    if (context.mounted) {
      if (eventId != null) {
        // Flag to track if user clicked View button
        bool viewClicked = false;
        
        // Show success message with 5-second duration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Event created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View',
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                // Mark that view was clicked
                viewClicked = true;
                // Pop the create event screen first
                context.pop();
                // Then navigate to the newly created event detail page
                context.push('/event-detail/$eventId');
              },
            ),
          ),
        );
        
        // Auto-dismiss and navigate back after 5 seconds only if View wasn't clicked
        Future.delayed(const Duration(seconds: 5), () {
          if (context.mounted && !viewClicked) {
            context.pop();
          }
        });
      } else {
        // Show error message
        final operationState = ref.read(eventOperationsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(operationState.error ?? 'Failed to create event'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
