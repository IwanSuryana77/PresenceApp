import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

const persibBlue = Color(0xFF0033A0);
const softBackground = Color(0xFFF7F8FC);

class EventData {
  final DateTime date;
  final String acara;
  EventData(this.date, this.acara);
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<EventData>> _events = {};

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<EventData> get _eventForSelectedDay {
    final day = _normalizeDate(_selectedDay ?? _focusedDay);
    return _events[day] ?? [];
  }

  Future<void> _pickYearMonth(BuildContext context) async {
    int startYear = 2005;
    int endYear = 2050;
    int currYear = _focusedDay.year;
    int currMonth = _focusedDay.month;

    int pickedYear = currYear;
    int pickedMonth = currMonth;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            "Pilih Bulan & Tahun",
            style: TextStyle(color: persibBlue),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) => SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pilih Tahun
                  DropdownButton<int>(
                    value: pickedYear,
                    icon: const Icon(Icons.arrow_drop_down),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: persibBlue,
                    ),
                    dropdownColor: Colors.white,
                    onChanged: (val) {
                      if (val == null) return;
                      setDialogState(() {
                        pickedYear = val;
                      });
                    },
                    items: [
                      for (int y = startYear; y <= endYear; y++)
                        DropdownMenuItem(value: y, child: Text("$y")),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Pilih Bulan
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(12, (i) {
                      final m = i + 1;
                      final isActive = pickedMonth == m;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            pickedMonth = m;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isActive ? persibBlue : Colors.white,
                            border: Border.all(
                              color: persibBlue.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 13,
                          ),
                          child: Text(
                            DateFormat('MMM').format(DateTime(2000, m)),
                            style: TextStyle(
                              color: isActive ? Colors.white : persibBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: persibBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pilih'),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(pickedYear, pickedMonth, 1);
                  _selectedDay = DateTime(pickedYear, pickedMonth, 1);
                });
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddEventDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Acara", style: TextStyle(color: persibBlue)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Masukkan nama acara'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: persibBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              var value = ctrl.text.trim();
              if (value.isEmpty) return;
              setState(() {
                final tanggal = _normalizeDate(_selectedDay ?? _focusedDay);
                _events.putIfAbsent(tanggal, () => []);
                _events[tanggal]!.add(EventData(tanggal, value));
                // TODO: Simpan ke database di sini!
              });
              Navigator.of(context).pop();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showMonthEventsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonthEventsPage(events: _events, month: _focusedDay),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header Kalender
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.only(
                    top: 7,
                    bottom: 14,
                    left: 9,
                    right: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 18,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Kembali + Hari ini
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: persibBlue,
                              size: 32,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: "Kembali ke Home",
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() {
                              final now = DateTime.now();
                              _focusedDay = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              _selectedDay = _focusedDay;
                            }),
                            child: const Text(
                              "Hari ini",
                              style: TextStyle(
                                color: persibBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Judul Bulan di Tengah (klik untuk pick bulan/tahun)
                      GestureDetector(
                        onTap: () => _pickYearMonth(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('MMM yyyy').format(_focusedDay),
                              style: const TextStyle(
                                color: persibBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                            const Icon(
                              Icons.expand_more,
                              color: persibBlue,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                      // Kalender
                      TableCalendar<EventData>(
                        locale: 'en_US',
                        firstDay: DateTime.utc(2005, 1, 1),
                        lastDay: DateTime.utc(2050, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(day, _selectedDay),
                        calendarFormat: CalendarFormat.month,
                        eventLoader: (date) =>
                            _events[_normalizeDate(date)] ?? [],
                        startingDayOfWeek: StartingDayOfWeek.sunday,
                        calendarStyle: const CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Color(0xFFADC9F5),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: persibBlue,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          defaultTextStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          weekendTextStyle: TextStyle(
                            color: Color(0xFFEF3A3A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        headerVisible: false,
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDay = _normalizeDate(selected);
                            _focusedDay = _normalizeDate(focused);
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showMonthEventsPage,
                          child: const Text(
                            "Lihat Acara Bulan Ini ➔",
                            style: TextStyle(
                              color: persibBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Catatan / Acara
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: persibBlue, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 18,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Title dan divider
                        Row(
                          children: const [
                            Text(
                              "catatan",
                              style: TextStyle(
                                color: persibBlue,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                height: 0,
                                thickness: 2,
                                color: persibBlue,
                                indent: 12,
                                endIndent: 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 19),
                        // Icon Calendar
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 60,
                          color: Color(0xFFEF7D8A),
                        ),
                        const SizedBox(height: 13),
                        // Daftar acara
                        _eventForSelectedDay.isEmpty
                            ? const Column(
                                children: [
                                  Text(
                                    "Tidak ada acara",
                                    style: TextStyle(
                                      color: persibBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "Acara pada tanggal yang dipilih akan terlihat disini",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: persibBlue,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Divider(height: 30),
                                ],
                              )
                            : Column(
                                children: [
                                  ..._eventForSelectedDay.map(
                                    (ev) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            ev.acara,
                                            style: const TextStyle(
                                              color: persibBlue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy',
                                            ).format(ev.date),
                                            style: TextStyle(
                                              color: persibBlue.withValues(
                                                alpha: 0.7,
                                              ),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 30),
                                ],
                              ),
                        // Tombol tambah acara
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: persibBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            onPressed: _showAddEventDialog,
                            child: const Text("tambah"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MonthEventsPage extends StatelessWidget {
  final Map<DateTime, List<EventData>> events;
  final DateTime month;
  const MonthEventsPage({super.key, required this.events, required this.month});

  @override
  Widget build(BuildContext context) {
    const persibBlue = Color(0xFF0033A0);
    final eventsInMonth = <EventData>[];
    events.forEach((dt, list) {
      if (dt.year == month.year && dt.month == month.month) {
        eventsInMonth.addAll(list);
      }
    });

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: persibBlue),
        title: Text(
          "Acara Bulan ${DateFormat('MMM yyyy').format(month)}",
          style: const TextStyle(
            color: persibBlue,
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: eventsInMonth.isEmpty
            ? const Center(
                child: Text(
                  "Belum ada acara bulan ini.",
                  style: TextStyle(
                    color: persibBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              )
            : ListView.separated(
                itemCount: eventsInMonth.length,
                separatorBuilder: (_, __) => Divider(
                  height: 22,
                  color: persibBlue.withValues(alpha: 0.18),
                ),
                itemBuilder: (ctx, i) {
                  final ev = eventsInMonth[i];
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                      side: BorderSide(
                        color: persibBlue.withValues(alpha: 0.20),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.event, color: persibBlue),
                      title: Text(
                        ev.acara,
                        style: const TextStyle(
                          color: persibBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy').format(ev.date),
                        style: TextStyle(
                          color: persibBlue.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
