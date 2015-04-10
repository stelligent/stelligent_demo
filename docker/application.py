from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'nando-automation-demo via docker'

if __name__ == '__main__':
    app.run()
