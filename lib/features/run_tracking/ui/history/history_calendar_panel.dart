import 'package:flutter/material.dart';
import 'package:runlini/features/run_tracking/service/run_history_calendar_summary_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/common/run_panel.dart';
import 'package:runlini/features/run_tracking/ui/history/history_calendar_chrome.dart';
import 'package:runlini/features/run_tracking/ui/history/history_day_progress_cell.dart';

class HistoryCalendarPanel extends StatefulWidget {
  const HistoryCalendarPanel({
    super.key,
    required this.sessions,
    required this.displaySettings,
    required this.distanceGoals,
    this.selectedDate,
    this.onSelectedDate,
    this.onClearSelectedDate,
    this.now,
    this.calculator = const RunHistoryCalendarSummaryCalculator(),
  });

  final List<RunSession> sessions;
  final RunDisplaySettings displaySettings;
  final RunDistanceGoalSettings distanceGoals;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onSelectedDate;
  final VoidCallback? onClearSelectedDate;
  final DateTime? now;
  final RunHistoryCalendarSummaryCalculator calculator;

  @override
  State<HistoryCalendarPanel> createState() => _HistoryCalendarPanelState();
}

class _HistoryCalendarPanelState extends State<HistoryCalendarPanel> {
  static const _calendarAnimationDuration = Duration(milliseconds: 220);
  static const _calendarAnimationCurve = Curves.easeOutCubic;
  static const _minimumSwipeVelocity = 250.0;
  static const _minimumSwipeDistance = 72.0;

  late DateTime _focusedMonth;
  late DateTime _focusedWeekAnchor;
  bool _isExpanded = false;
  int _slideDirection = 0;
  double _dragDistanceX = 0;

  @override
  void initState() {
    super.initState();
    final anchor = _localDate(
      widget.selectedDate ?? widget.now ?? DateTime.now(),
    );
    _focusedWeekAnchor = anchor;
    _focusedMonth = DateTime(anchor.year, anchor.month);
  }

  @override
  void didUpdateWidget(covariant HistoryCalendarPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedDate = widget.selectedDate;
    if (selectedDate == null ||
        _sameDay(selectedDate, oldWidget.selectedDate)) {
      return;
    }
    final anchor = _localDate(selectedDate);
    _focusedWeekAnchor = anchor;
    _focusedMonth = DateTime(anchor.year, anchor.month);
  }

  @override
  Widget build(BuildContext context) {
    final summaries = widget.calculator.calculate(sessions: widget.sessions);
    final dayGoalM =
        widget.distanceGoals.monthlyGoalM / _daysInMonth(_focusedMonth);
    final visibleDates = _isExpanded
        ? _monthGridDates(_focusedMonth)
        : _weekDates(_focusedWeekAnchor);
    return RunPanel(
      key: const Key('history-calendar-panel'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HistoryCalendarHeader(
            focusedMonth: _focusedMonth,
            isExpanded: _isExpanded,
            dayGoalM: dayGoalM,
            displaySettings: widget.displaySettings,
            onPreviousMonth: () => _moveMonth(-1),
            onNextMonth: () => _moveMonth(1),
            onViewModeChanged: (bool isExpanded) {
              if (_isExpanded == isExpanded) {
                return;
              }
              setState(() {
                _slideDirection = 0;
                _isExpanded = isExpanded;
              });
            },
          ),
          const SizedBox(height: 14),
          const HistoryWeekdayHeader(),
          const SizedBox(height: 8),
          GestureDetector(
            key: const Key('history-calendar-swipe-area'),
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _dragDistanceX = 0,
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              _dragDistanceX += details.primaryDelta ?? 0;
            },
            onHorizontalDragEnd: _handleHorizontalDragEnd,
            child: AnimatedSize(
              duration: _calendarAnimationDuration,
              curve: _calendarAnimationCurve,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: _calendarAnimationDuration,
                switchInCurve: _calendarAnimationCurve,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final horizontalOffset = _slideDirection == 0
                      ? 0.0
                      : 0.08 * _slideDirection;
                  final offset = Tween<Offset>(
                    begin: Offset(horizontalOffset, 0.02),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: GridView.count(
                  key: ValueKey<String>(
                    '${_isExpanded ? 'month' : 'week'}-${_focusedMonth.year}-'
                    '${_focusedMonth.month}-${_dateKey(_focusedWeekAnchor)}',
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.68,
                  children: [
                    for (final date in visibleDates)
                      HistoryDayProgressCell(
                        key: Key('history-calendar-day-${_dateKey(date)}'),
                        date: date,
                        summary: summaries[widget.calculator.localDate(date)],
                        dayGoalM: dayGoalM,
                        displaySettings: widget.displaySettings,
                        isSelected: _sameDay(date, widget.selectedDate),
                        isToday: _sameDay(date, widget.now ?? DateTime.now()),
                        isOutsideMonth: !_sameMonth(date, _focusedMonth),
                        onTap: () => _selectDate(date),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.selectedDate != null) ...[
            const SizedBox(height: 12),
            HistoryCalendarClearButton(onPressed: widget.onClearSelectedDate),
          ],
        ],
      ),
    );
  }

  void _moveMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
      );
      _focusedWeekAnchor = _weekAnchorForMonth(_focusedMonth);
      _slideDirection = offset.sign;
    });
  }

  void _selectDate(DateTime date) {
    final anchor = _localDate(date);
    setState(() {
      _focusedWeekAnchor = anchor;
      if (!_sameMonth(date, _focusedMonth)) {
        _focusedMonth = DateTime(date.year, date.month);
      }
      _slideDirection = 0;
    });
    widget.onSelectedDate?.call(widget.calculator.localDate(date));
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < _minimumSwipeVelocity) {
      if (_dragDistanceX.abs() < _minimumSwipeDistance) {
        return;
      }
      _moveBySwipe(_dragDistanceX < 0 ? 1 : -1);
      return;
    }
    _moveBySwipe(velocity < 0 ? 1 : -1);
  }

  void _moveBySwipe(int offset) {
    setState(() {
      if (_isExpanded) {
        _focusedMonth = DateTime(
          _focusedMonth.year,
          _focusedMonth.month + offset,
        );
        _focusedWeekAnchor = _weekAnchorForMonth(_focusedMonth);
      } else {
        _focusedWeekAnchor = _focusedWeekAnchor.add(Duration(days: offset * 7));
        _focusedMonth = DateTime(
          _focusedWeekAnchor.year,
          _focusedWeekAnchor.month,
        );
      }
      _slideDirection = offset.sign;
    });
  }
}

DateTime _localDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime _weekAnchorForMonth(DateTime month) {
  return DateTime(month.year, month.month);
}

List<DateTime> _weekDates(DateTime anchorDate) {
  final start = DateTime(
    anchorDate.year,
    anchorDate.month,
    anchorDate.day,
  ).subtract(Duration(days: anchorDate.weekday - DateTime.monday));
  return List<DateTime>.generate(
    7,
    (int index) => start.add(Duration(days: index)),
  );
}

List<DateTime> _monthGridDates(DateTime focusedMonth) {
  final firstDay = DateTime(focusedMonth.year, focusedMonth.month);
  final gridStart = firstDay.subtract(
    Duration(days: firstDay.weekday - DateTime.monday),
  );
  final daysInGrid = _daysInMonth(focusedMonth) + firstDay.weekday - 1;
  final gridRows = (daysInGrid / 7).ceil();
  return List<DateTime>.generate(
    gridRows * 7,
    (int index) => gridStart.add(Duration(days: index)),
  );
}

int _daysInMonth(DateTime month) {
  return DateTime(month.year, month.month + 1, 0).day;
}

bool _sameDay(DateTime left, DateTime? right) {
  return right != null &&
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

bool _sameMonth(DateTime left, DateTime right) {
  return left.year == right.year && left.month == right.month;
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
