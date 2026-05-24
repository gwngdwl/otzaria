import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/tools/calendar/utils/calendar_cubit.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('CalendarCubit Jewish month navigation', () {
    test('next month handles Adar I -> Adar II and no year rollover to Nissan',
        () {
      // Create a JewishDate for a known leap year at Adar I (month 12)
      final jewish = JewishDate();
      // 5784 is a leap year in the 19-year cycle
      jewish.setJewishDate(5784, 12, 15); // Middle of Adar I

      expect(jewish.isJewishLeapYear(), isTrue);
      expect(jewish.getJewishMonth(), 12);

      final next = computeNextJewishMonth(jewish);
      expect(next.getJewishYear(), 5784);
      expect(next.getJewishMonth(), 13,
          reason: 'Should move to Adar II same year');

      final afterAdarII = computeNextJewishMonth(next);
      expect(afterAdarII.getJewishYear(), 5784,
          reason: 'After Adar II go to Nissan in same Jewish year');
      expect(afterAdarII.getJewishMonth(), 1);
    });

    test('previous month handles Nissan -> last Adar in same year', () {
      // Nissan of a leap year
      final nissan = JewishDate();
      nissan.setJewishDate(5784, 1, 7);
      expect(nissan.isJewishLeapYear(), isTrue);
      expect(nissan.getJewishMonth(), 1);

      final prev = computePreviousJewishMonth(nissan);
      expect(prev.getJewishYear(), 5784,
          reason: 'Nissan -> Adar stays in same Jewish year');
      expect(prev.getJewishMonth(), 13,
          reason: '5784 is leap; previous month is Adar II');
    });

    test('previous month handles Adar II -> Adar I within leap year', () {
      final adarII = JewishDate();
      adarII.setJewishDate(5784, 13, 3);
      expect(adarII.isJewishLeapYear(), isTrue);
      final prev = computePreviousJewishMonth(adarII);
      expect(prev.getJewishMonth(), 12);
      expect(prev.getJewishYear(), 5784);
    });
  });

  group('Calendar day transition', () {
    test('sunset moves the calendar day before midnight', () {
      final jerusalem = tz.getLocation('Asia/Jerusalem');

      final beforeSunset = resolveCalendarDayForTransition(
        now: tz.TZDateTime(jerusalem, 2026, 4, 20, 18),
        city: 'ירושלים',
        transition: CalendarDayTransition.sunset,
      );
      expect(beforeSunset, DateTime(2026, 4, 20));

      final afterSunset = resolveCalendarDayForTransition(
        now: tz.TZDateTime(jerusalem, 2026, 4, 20, 20, 30),
        city: 'ירושלים',
        transition: CalendarDayTransition.sunset,
      );
      expect(afterSunset, DateTime(2026, 4, 21));
    });

    test('sunset uses the selected city date, not the computer timezone date',
        () {
      final newYork = tz.getLocation('America/New_York');

      final beforeNewYorkSunset = resolveCalendarDayForTransition(
        now: tz.TZDateTime(newYork, 2026, 4, 20, 18),
        city: 'ניו יורק',
        transition: CalendarDayTransition.sunset,
      );

      expect(beforeNewYorkSunset, DateTime(2026, 4, 20));
    });

    test('midnight preserves the civil date until midnight', () {
      final jerusalem = tz.getLocation('Asia/Jerusalem');

      final lateEvening = resolveCalendarDayForTransition(
        now: tz.TZDateTime(jerusalem, 2026, 4, 20, 23, 30),
        city: 'ירושלים',
        transition: CalendarDayTransition.midnight,
      );
      expect(lateEvening, DateTime(2026, 4, 20));
    });

    test('rabbeinu tam waits longer than regular sunset', () {
      final jerusalem = tz.getLocation('Asia/Jerusalem');

      final afterSunsetBeforeRabbeinuTam = resolveCalendarDayForTransition(
        now: tz.TZDateTime(jerusalem, 2026, 4, 20, 19, 45),
        city: 'ירושלים',
        transition: CalendarDayTransition.rabbeinuTam,
      );
      expect(afterSunsetBeforeRabbeinuTam, DateTime(2026, 4, 20));

      final afterRabbeinuTam = resolveCalendarDayForTransition(
        now: tz.TZDateTime(jerusalem, 2026, 4, 20, 21, 30),
        city: 'ירושלים',
        transition: CalendarDayTransition.rabbeinuTam,
      );
      expect(afterRabbeinuTam, DateTime(2026, 4, 21));
    });
  });

  group('Calendar header Ohr prefix', () {
    test('shows Ohr prefix before 90 minute alos on the current day', () {
      final jerusalem = tz.getLocation('Asia/Jerusalem');
      final date = DateTime(2026, 4, 20);
      final state = _buildCalendarState(date);

      final shouldShow = shouldShowOhrPrefixForCalendarHeader(
        state: state,
        now: tz.TZDateTime(jerusalem, 2026, 4, 20, 3),
      );

      expect(shouldShow, isTrue);
    });

    test('does not show Ohr prefix after 90 minute alos', () {
      final jerusalem = tz.getLocation('Asia/Jerusalem');
      final date = DateTime(2026, 4, 20);
      final state = _buildCalendarState(date);

      final shouldShow = shouldShowOhrPrefixForCalendarHeader(
        state: state,
        now: tz.TZDateTime(jerusalem, 2026, 4, 20, 5),
      );

      expect(shouldShow, isFalse);
    });

    test('does not show Ohr prefix when selected date is not current day', () {
      final jerusalem = tz.getLocation('Asia/Jerusalem');
      final selected = DateTime(2026, 4, 19);
      final today = DateTime(2026, 4, 20);
      final state = _buildCalendarState(selected, today: today);

      final shouldShow = shouldShowOhrPrefixForCalendarHeader(
        state: state,
        now: tz.TZDateTime(jerusalem, 2026, 4, 20, 3),
      );

      expect(shouldShow, isFalse);
    });

    test('next refresh is scheduled for alos when it is the next boundary', () {
      final jerusalem = tz.getLocation('Asia/Jerusalem');

      final nextRefresh = nextCalendarTodayRefreshTime(
        now: tz.TZDateTime(jerusalem, 2026, 4, 20, 3),
        city: 'ירושלים',
        transition: CalendarDayTransition.sunset,
      );

      final refreshInJerusalem = tz.TZDateTime.from(nextRefresh, jerusalem);
      expect(refreshInJerusalem.year, 2026);
      expect(refreshInJerusalem.month, 4);
      expect(refreshInJerusalem.day, 20);
      expect(refreshInJerusalem.hour, 4);
    });
  });
}

CalendarState _buildCalendarState(DateTime selectedDate, {DateTime? today}) {
  final selectedJewishDate = JewishDate.fromDateTime(selectedDate);
  final todayDate = today ?? selectedDate;
  final todayJewishDate = JewishDate.fromDateTime(todayDate);

  return CalendarState(
    selectedJewishDate: selectedJewishDate,
    selectedGregorianDate: selectedDate,
    selectedCity: 'ירושלים',
    dailyTimes: const {},
    currentJewishDate: todayJewishDate,
    currentGregorianDate: todayDate,
    todayGregorianDate: todayDate,
    calendarType: CalendarType.combined,
    calendarView: CalendarView.month,
    dayTransition: CalendarDayTransition.sunset,
    inIsrael: true,
  );
}
