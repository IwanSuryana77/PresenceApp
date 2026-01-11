import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Colors
const biruModern = Color(0xFF2563EB); // Blue untuk tombol dan header
const whiteBg = Color(0xFFF7F8FC);

class EventData {
  final DateTime date;
  final String acara;
  final String id; // ID dokumen Firestore
  EventData(this.date, this.acara, {this.id = ""});
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<EventData>> _events = {};

  // --- Firestore reference ---
  final CollectionReference eventCollection =
      FirebaseFirestore.instance.collection('calendar_events');

  @override
  void initState() {
    super.initState();
    _loadEventsFromFirestore();
  }

  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  // --- Load from Firestore, group by date ---
  Future<void> _loadEventsFromFirestore() async {
    final snapshot = await eventCollection.get();
    final Map<DateTime, List<EventData>> eventMap = {};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['date'] != null && data['acara'] != null) {
        DateTime d = (data['date'] as Timestamp).toDate();
        DateTime groupKey = _normalizeDate(d);
        eventMap.putIfAbsent(groupKey, () => []);
        eventMap[groupKey]!.add(
          EventData(groupKey, data['acara'], id: doc.id),
        );
      }
    }
    setState(() {
      _events = eventMap;
    });
  }

  // Save to Firebase!
  Future<void> _addEventToFirestore(DateTime date, String acara) async {
    await eventCollection.add({
      'date': date,
      'acara': acara,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _loadEventsFromFirestore();
  }

  // Event for selected day
  List<EventData> get _eventForSelectedDay {
    final day = _normalizeDate(_selectedDay ?? _focusedDay);
    return _events[day] ?? [];
  }

  Future<void> _pickYearMonth(BuildContext context) async {
    // Show year/month picker dialog (customized)
    int startYear = 2020;
    int endYear = 2040;
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
            style: TextStyle(color: biruModern),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) => SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tahun dropdown
                  DropdownButton<int>(
                    value: pickedYear,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: biruModern),
                    dropdownColor: Colors.white,
                    onChanged: (val) {
                      if (val != null) setDialogState(() { pickedYear = val; });
                    },
                    items: [
                      for (int y = startYear; y <= endYear; y++)
                        DropdownMenuItem(value: y, child: Text("$y")),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bulan picker
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    children: List.generate(12, (i) {
                      final m = i + 1;
                      final isActive = pickedMonth == m;
                      return GestureDetector(
                        onTap: () => setDialogState(() { pickedMonth = m; }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isActive ? biruModern : Colors.white,
                            border: Border.all(color: biruModern.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 13),
                          child: Text(
                            DateFormat('MMMM', 'id_ID').format(DateTime(2000, m)),
                            style: TextStyle(
                              color: isActive ? Colors.white : biruModern,
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
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: biruModern,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(pickedYear, pickedMonth, 1);
                  _selectedDay = DateTime(pickedYear, pickedMonth, 1);
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Pilih'),
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
        title: const Text("Tambah Acara", style: TextStyle(color: biruModern)),
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
              backgroundColor: biruModern,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              var value = ctrl.text.trim();
              if (value.isEmpty) return;
              final tanggal = _normalizeDate(_selectedDay ?? _focusedDay);
              await _addEventToFirestore(tanggal, value);
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
      backgroundColor: whiteBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              // ==== Header Kalender ====
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    // App bar custom: back, month/year, "Hari ini"
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: biruModern, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: "Kembali ke Home",
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickYearMonth(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${DateFormat('MMM yyyy').format(_focusedDay)}",
                                  style: const TextStyle(
                                    color: biruModern,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 19,
                                  ),
                                ),
                                const Icon(Icons.expand_more, color: biruModern, size: 22),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            final now = DateTime.now();
                            _focusedDay = DateTime(now.year, now.month, now.day);
                            _selectedDay = _focusedDay;
                          }),
                          child: const Text(
                            "Hari Ini",
                            style: TextStyle(
                              color: biruModern,
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // TableCalendar
                    TableCalendar<EventData>(
                      locale: 'id_ID',
                      firstDay: DateTime.utc(2005, 1, 1),
                      lastDay: DateTime.utc(2050, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                      calendarFormat: CalendarFormat.month,
                      eventLoader: (date) => _events[_normalizeDate(date)] ?? [],
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Color(0xFF93C5FD),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: biruModern,
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
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                        weekendStyle: const TextStyle(
                          color: Color(0xFFEF3A3A),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _showMonthEventsPage,
                        child: const Text(
                          "Lihat Acara Bulan Ini",
                          style: TextStyle(
                            color: biruModern,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ==== Card Catatan Hari Terpilih ====
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                  padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & divider
                      const Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Text(
                          "catatan",
                          style: TextStyle(
                            color: biruModern,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Divider(color: biruModern, thickness: 1.3, endIndent: 30),
                      const SizedBox(height: 9),
                      // Center icon + text
                      Expanded(
                        child: _eventForSelectedDay.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.event_busy, size: 42, color: Colors.redAccent),
                                  const SizedBox(height: 6),
                                  const Text(
                                    "Tidak ada acara",
                                    style: TextStyle(
                                      color: biruModern,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Acara pada tanggal yang dipilih akan terlihat di sini.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13.3,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _eventForSelectedDay.length,
                                itemBuilder: (ctx, i) {
                                  final event = _eventForSelectedDay[i];
                                  return Card(
                                    elevation: 0,
                                    color: Colors.white,
                                    margin: const EdgeInsets.symmetric(vertical: 7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      side: BorderSide(
                                        color: biruModern.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: const Icon(Icons.event, color: biruModern, size: 28),
                                      title: Text(
                                        event.acara,
                                        style: const TextStyle(
                                          color: biruModern,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      subtitle: Text(
                                        DateFormat('dd MMM yyyy').format(event.date),
                                        style: TextStyle(
                                          color: biruModern.withOpacity(0.77),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 7),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: biruModern,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _showAddEventDialog,
                          child: const Text("Tambah"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==== Halaman Daftar Acara Bulan Ini ====
class MonthEventsPage extends StatelessWidget {
  final Map<DateTime, List<EventData>> events;
  final DateTime month;
  const MonthEventsPage({super.key, required this.events, required this.month});

  @override
  Widget build(BuildContext context) {
    const biruModern = Color(0xFF2563EB);
    final eventsInMonth = <EventData>[];
    events.forEach((dt, list) {
      if (dt.year == month.year && dt.month == month.month) {
        eventsInMonth.addAll(list);
      }
    });

    return Scaffold(
      backgroundColor: whiteBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: biruModern),
        title: Text(
          "Acara Bulan ${DateFormat('MMM yyyy').format(month)}",
          style: const TextStyle(
            color: biruModern,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: eventsInMonth.isEmpty
            ? const Center(
                child: Text(
                  "Belum ada acara bulan ini.",
                  style: TextStyle(
                    color: biruModern,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              )
            : ListView.separated(
                itemCount: eventsInMonth.length,
                separatorBuilder: (_, __) => Divider(
                  height: 22,
                  color: biruModern.withOpacity(0.16),
                ),
                itemBuilder: (ctx, i) {
                  final ev = eventsInMonth[i];
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: biruModern.withOpacity(0.18),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.event_note, color: biruModern),
                      title: Text(
                        ev.acara,
                        style: const TextStyle(
                          color: biruModern,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy').format(ev.date),
                        style: TextStyle(
                          color: biruModern.withOpacity(0.62),
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