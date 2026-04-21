FROM python:3.13-slim

WORKDIR /app

COPY ./app.py .

RUN pip install flask flask-cors gunicorn

EXPOSE 5001

CMD ["gunicorn", "--bind", "0.0.0.0:5001", "app:app"]