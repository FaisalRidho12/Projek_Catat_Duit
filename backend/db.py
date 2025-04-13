import mysql.connector

def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",  # ganti sesuai phpMyAdmin kamu
        password="",  # kosongkan jika tidak ada password
        database="finance"
    )
