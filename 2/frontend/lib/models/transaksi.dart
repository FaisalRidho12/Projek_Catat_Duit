class Transaksi {
  final int id;
  final String jenis;
  final int jumlah;
  final String keterangan;
  final String tanggal;

  Transaksi({
    required this.id,
    required this.jenis,
    required this.jumlah,
    required this.keterangan,
    required this.tanggal,
  });

  factory Transaksi.fromJson(Map<String, dynamic> json) {
    return Transaksi(
      id: json['id'],
      jenis: json['jenis'],
      jumlah: json['jumlah'],
      keterangan: json['keterangan'],
      tanggal: json['tanggal'],
    );
  }
}
