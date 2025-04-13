from flask import Blueprint, request, jsonify
from db import get_connection
from datetime import date

transactions = Blueprint('transactions', __name__)

@transactions.route('/transactions', methods=['GET'])
def get_all():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT t.*, c.name AS category_name, c.type FROM transactions t JOIN categories c ON t.category_id = c.id ORDER BY date DESC")
    result = cursor.fetchall()
    conn.close()
    return jsonify(result)

@transactions.route('/transactions/today', methods=['GET'])
def get_today():
    today = date.today()
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT t.*, c.name AS category_name, c.type FROM transactions t JOIN categories c ON t.category_id = c.id WHERE date = %s", (today,))
    result = cursor.fetchall()
    conn.close()
    return jsonify(result)

@transactions.route('/transactions', methods=['POST'])
def add_transaction():
    data = request.json
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO transactions (amount, description, date, category_id) VALUES (%s, %s, %s, %s)",
                   (data['amount'], data['description'], data['date'], data['category_id']))
    conn.commit()
    conn.close()
    return jsonify({"message": "Transaction added"}), 201
