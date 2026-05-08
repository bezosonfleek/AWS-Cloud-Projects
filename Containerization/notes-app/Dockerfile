FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app.py .

# Non-root user for security
RUN useradd -m appuser
USER appuser

EXPOSE 5000

CMD ["python", "app.py"]