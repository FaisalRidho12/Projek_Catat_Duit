from flask import Flask
from flask_cors import CORS
from routes.transactions import transactions
from routes.categories import categories

app = Flask(__name__)
CORS(app)

app.register_blueprint(transactions)
app.register_blueprint(categories)

if __name__ == '__main__':
    app.run(debug=True)
