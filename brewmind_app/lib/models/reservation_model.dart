class ReservationModel {
  final String reservationID;
  final String userID;
  final String date; // "2026-03-10"
  final String time; // "14:00"
  final int tableNumber;
  final int partySize;
  final String status; // pending | confirmed | cancelled

  ReservationModel({
    required this.reservationID,
    required this.userID,
    required this.date,
    required this.time,
    required this.tableNumber,
    required this.partySize,
    required this.status,
  });

  factory ReservationModel.fromMap(Map<String, dynamic> map, String id) {
    return ReservationModel(
      reservationID: id,
      userID: map['userID'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      tableNumber: map['tableNumber'] ?? 1,
      partySize: map['partySize'] ?? 1,
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'date': date,
      'time': time,
      'tableNumber': tableNumber,
      'partySize': partySize,
      'status': status,
    };
  }
}
