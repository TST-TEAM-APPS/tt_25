import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:party_planner/BLOC/Bloc_treker/state_treker.dart';
import 'package:party_planner/Models/event_model.dart';

import '../../Repo/event_repo.dart';
import 'event_treker.dart';

class TrekerBloc extends Bloc<TrekerEvent, TrekerState> {
  final EventRepository eventRepository;

  TrekerBloc(this.eventRepository) : super(TrekerState.initial()) {
    on<LoadEvent>(_onLoadEvent);
    on<AddEvent>(_onAddEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<DeleteEvent>(_onDeleteEvent);
    on<FilledEvent>(_onFillEventByDate);
    on<FilledByDateAndTagEvent>(_onFillEventByDateAndTag);
    on<FilledByTagEvent>(_onFillEventByTag);
    add(LoadEvent());
  }


  Future<void> _onFillEventByDate(FilledEvent event,
      Emitter<TrekerState> emit) async {
    final currentEventsByDate =
    _filterEventsByDate(date: event.date, events: state.event);
    emit(
      state.copyWith(
        currentEventByDate: currentEventsByDate,
        currentDateTime: event.date,
      ),
    );
  }

  List<Event> _filterEventsByDate({
    required DateTime date,
    required List<Event> events,
  }) {
    return events.where((events) {
      return events.dueDate.year == date.year &&
          events.dueDate.month == date.month &&
          events.dueDate.day == date.day;
    }).toList();
  }

  Future<void> _onFillEventByDateAndTag(FilledByDateAndTagEvent event,
      Emitter<TrekerState> emit) async {
    final currentEventsByDateAndTag =
    _filterEventsByDateAndTag(date: event.date, eventsByDateAndTag: state.event,tag: event.tag);
    emit(
      state.copyWith(
        currentEventByDate: currentEventsByDateAndTag,
        currentDateTime: event.date,
        currentTag: event.tag
      ),
    );
  }

  List<Event> _filterEventsByDateAndTag({
    required DateTime date,
    required List<Event> eventsByDateAndTag,
    required String tag,
  }) {
    return eventsByDateAndTag.where((eventsByDateAndTag) {
      return eventsByDateAndTag.dueDate.year == date.year &&
          eventsByDateAndTag.dueDate.month == date.month &&
          eventsByDateAndTag.dueDate.day == date.day &&
          eventsByDateAndTag.tag == tag;
    }).toList();
  }



  Future<void> _onFillEventByTag(FilledByTagEvent event,
      Emitter<TrekerState> emit) async {
    final currentEventsByTag =
    _filterEventsByTag(tag: event.tag, eventsByTag: state.event);
    emit(
      state.copyWith(
        currentEventByTag: currentEventsByTag,
        currentTag: event.tag,
      ),
    );
  }

  List<Event> _filterEventsByTag({
    required String tag,
    required List<Event> eventsByTag,
  }) {
    return eventsByTag.where((eventsByTag) {
      return eventsByTag.tag == tag;
    }).toList();
  }



  Future<void> _onLoadEvent(LoadEvent event,
      Emitter<TrekerState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final events = await eventRepository.getEvents();
      if (state.currentEventByDate.isEmpty || state.currentEventByDate.length != events.length) {
        emit(
          state.copyWith(
            event: events,
            isLoading: false,
            currentEventByTag: events,
            currentEventByDate: events,
          ),
        );
      } else {

        List<Event> currentEventsByDate = state.currentEventByDate;
        for (int i = 0; i< currentEventsByDate.length; i++) {
          if (currentEventsByDate[i] != events[i]) {
            currentEventsByDate[i] = events[i];
          }
        }

        List<Event> currentEventsByTag = state.currentEventByDate;
        for (int i = 0; i< currentEventsByTag.length; i++) {
          if (currentEventsByTag[i] != events[i]) {
            currentEventsByTag[i] = events[i];
          }
        }
        emit(state.copyWith(
          event: events,
          currentEventByTag: currentEventsByDate,
          currentEventByDate: currentEventsByTag,
          isLoading: false,
        ));
      }

      add(FilledEvent(state.currentDateTime ?? DateTime.now()));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAddEvent(AddEvent event, Emitter<TrekerState> emit) async {
    try {
      await eventRepository.insertEvent(event.event);
      final events = await eventRepository.getEvents();
      emit(state.copyWith(currentEventByTag: events, event: events, currentEventByDate: events));
      add(FilledEvent(state.currentDateTime ?? DateTime.now()));
      add(FilledByTagEvent(state.currentTag!));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateEvent(UpdateEvent event,
      Emitter<TrekerState> emit) async {
    try {
      await eventRepository.updateEvent(event.event);
      final events = await eventRepository.getEvents();
      emit(state.copyWith(event: events));
      add(LoadEvent());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }


  Future<void> _onDeleteEvent(DeleteEvent event,
      Emitter<TrekerState> emit) async {
    await eventRepository.deleteEvent(event.event.id!);
    add(LoadEvent());
  }
}
