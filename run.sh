#!/bin/bash

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

export FLASK_APP=./app/app.py
export FLASK_DEBUG=1
flask run $@
