from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from datetime import date

app = Flask(__name__)
CORS(app)

def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",  # default user
        password="",  # kosong jika pakai XAMPP
        database="keuangan"
    )

@app.route("/transaksi", methods=["GET"])
def get_transaksi():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM transaksi ORDER BY tanggal DESC")
    hasil = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(hasil)

@app.route("/transaksi", methods=["POST"])
def tambah_transaksi():
    data = request.json
    print("DATA MASUK:", data) 
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO transaksi (jenis, jumlah, keterangan, tanggal) VALUES (%s, %s, %s, %s)",
        (data['jenis'], data['jumlah'], data['keterangan'], date.today())
    )
    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({"message": "Transaksi berhasil ditambahkan"}), 201

@app.route("/dashboard", methods=["GET"])
def dashboard():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    today = date.today()

    cursor.execute("SELECT SUM(jumlah) as pemasukan FROM transaksi WHERE jenis='pemasukan' AND tanggal=%s", (today,))
    pemasukan = cursor.fetchone()['pemasukan'] or 0

    cursor.execute("SELECT SUM(jumlah) as pengeluaran FROM transaksi WHERE jenis='pengeluaran' AND tanggal=%s", (today,))
    pengeluaran = cursor.fetchone()['pengeluaran'] or 0

    cursor.execute("SELECT SUM(CASE WHEN jenis='pemasukan' THEN jumlah ELSE -jumlah END) as saldo FROM transaksi")
    saldo = cursor.fetchone()['saldo'] or 0

    cursor.execute("SELECT * FROM transaksi WHERE tanggal=%s ORDER BY id DESC", (today,))
    riwayat = cursor.fetchall()

    cursor.close()
    conn.close()

    return jsonify({
        "saldo": saldo,
        "pemasukan_hari_ini": pemasukan,
        "pengeluaran_hari_ini": pengeluaran,
        "riwayat_hari_ini": riwayat
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)