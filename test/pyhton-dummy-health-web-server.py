#!/usr/bin/env python3
from flask import Flask
import os

app = Flask(__name__)
status_filename = os.environ.get('STATUS_FILE') or "status.txt"
app.url_map.strict_slashes = False

run_help = """

Run this file like this:

        export FLASK_APP=pyhton-dummy-health-web-server.py
        export STATUS_FILE=status.txt
        flask run --host=0.0.0.0 --reload
        or flask run --host=0.0.0.0 --port=6000

or:

        export STATUS_FILE=status.txt ;  python3 pyhton-dummy-health-web-server.py

To flip the response to fail:

        echo "FAIL" > status.txt

flip back to ok

        echo "OK" > status.txt

"""

client_help = """<pre>

Hello and welcome to simple health web server
access /health to get default health status of ALLOK
access /ok to always get ok status
access /fail to always get fail status

ok status will retun string ALLOK and http status 200
fail status will retun string FAIL and http status 500

</pre>
"""


@app.route("/", methods=['GET'])
def root():
    print('SASD service accessed')
    return client_help, 200


@app.route("/health/<display>/", methods=['GET'])
@app.route("/health/", methods=['GET'])
def health(display=None):
    print('health service accessed')

    status = None
    if os.path.exists(status_filename):
        with open(status_filename, 'r') as file:
            status = file.read()

    if status is not None:
        print('status from file: <%s>' % status.strip())
        if status.strip() == "OK":
            if display is not None:
                msg = "Stauts: ALLOK\nService1: OK\nService2: OK\n"
            else:
                msg = "ALLOK\n"

            return msg, 200
        elif status.strip() == "DOM":
            if display is not None:
                msg = "DOM: Service Maintenance\n"
            else:
                msg = "DOM\n"

            return msg, 503

        else:
            if display is not None:
                msg = "Stauts: FAIL:\nService1: FAIL (msg1)\nService2: OK\n"
            else:
                msg = "INTERNAL ERROR\n"
            return msg, 500
    else:
        if display is not None:
            msg = "Stauts: ALLOK\nService1: OK\nService2: OK\n"
        else:
            msg = "ALLOK\n"

        return msg, 200


@app.route("/ok/<display>/", methods=['GET'])
@app.route("/ok/", methods=['GET'])
def ok(display=None):
    print('ok service accessed')

    if display is not None:
        msg = "Stauts: ALLOK\nService1: OK\nService2: OK\n"
    else:
        msg = "ALLOK\n"

    return msg, 200


@app.route("/fail/<display>/", methods=['GET'])
@app.route("/fail/", methods=['GET'])
def fail(display=None):
    print('fail service accessed')

    if display is not None:
        msg = "Stauts: FAIL:\nService1: FAIL (msg1)\nService2: OK\n"
    else:
        msg = "INTERNAL ERROR\n"

    return msg, 500


if __name__ == '__main__':
    app.run(debug=False)


@app.route("/dom", methods=['GET'])
def dom():
    print('dom service accessed')

    msg = "Down fOr Maintenance\n"
    return msg, 200


if __name__ == '__main__':
    app.run(debug=False)
