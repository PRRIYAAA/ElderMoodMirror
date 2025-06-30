from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/sum', methods=['POST'])
def calculate_sum():
    data = request.get_json()
    num1 = data.get('num1', 0)
    num2 = data.get('num2', 0)
    total = num1 + num2
    return jsonify({'sum': total})

if __name__ == '__main__':
    app.run(debug=True)