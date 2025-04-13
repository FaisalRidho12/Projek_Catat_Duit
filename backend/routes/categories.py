from flask import Blueprint, jsonify
from db import get_connection

categories = Blueprint('categories', __name__)

@categories.route('/categories', methods=['GET'])
def get_categories():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM categories")
    result = cursor.fetchall()
    conn.close()
    return jsonify(result)
