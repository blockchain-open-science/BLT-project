from flask import Flask, request, render_template, send_file
from util import *

app = Flask(__name__)

@app.route('/')
def route_index():
    return render_template('index.html')

@app.route('/publisher')
def route_publisher():
    return render_template('publisher.html')

@app.route('/logger')
def route_logger():
    return render_template('logger.html')

@app.route('/logger/get_records')
def route_logger_get_records():
    return get_records(request.values)

@app.route('/logger/add_record', methods=['POST'])
def route_logger_add_record():
    return add_record(request.values)

@app.route('/logger/tutorial')
def route_logger_tutorial():
    return send_file('tutorial.txt')
