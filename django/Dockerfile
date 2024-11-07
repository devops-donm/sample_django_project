# Use an official lightweight image with bash and Python support
FROM python:3.12-slim

# Set the working directory
WORKDIR /app

# Copy requirements.txt into the container
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code into the container (optional based on your app structure)
COPY . .

EXPOSE 8000

RUN python manage.py migrate

CMD ["gunicorn","--bind","0.0.0.0:8000","--workers","3","core.wsgi:application"]
