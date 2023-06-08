# Front-end build stage
FROM node:14-alpine as frontend-build

WORKDIR /app

# Copy package.json and package-lock.json to the container
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy the entire front-end code to the container
COPY . .

# Build the front-end code
RUN npm run build

# Install serve to serve the static files
RUN npm install -g serve

# Back-end base stage
FROM python:3.9-alpine as backend-base

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache postgresql-dev gcc musl-dev

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Back-end development stage
FROM backend-base as backend-dev

# Copy the entire back-end code to the container
COPY . .

# Set environment variables for development
ENV DJANGO_SETTINGS_MODULE=myproject.settings.development

# Run the back-end server with live reload using Django's built-in development server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

# Back-end production stage
FROM backend-base as backend-prod

# Copy the entire back-end code to the container
COPY . .

# Set environment variables for production
ENV DJANGO_SETTINGS_MODULE=myproject.settings.production

# Collect static files
RUN python manage.py collectstatic --noinput

# Run the back-end server using gunicorn (adjust the command according to your project structure)
CMD ["gunicorn", "myproject.wsgi:application", "--bind", "0.0.0.0:8000"]

# Final stage
FROM frontend-build as final

# Copy the front-end build to the final stage
COPY --from=frontend-build /app/build /app/build

# Copy the back-end code to the final stage
COPY --from=backend-prod /app /app

# Expose the port used by your application (adjust if necessary)
EXPOSE 8000

# Set environment variables if needed

# Start the back-end server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

# Final stage
FROM frontend-build as final

# Copy the front-end build to the final stage
COPY --from=frontend-build /app/build /app/build

# Copy the back-end code to the final stage
COPY --from=backend-prod /app /app

# Expose the port used by your application (adjust if necessary)
EXPOSE 8000

# Serve the static files
CMD ["serve", "-s", "build", "-l", "8000"]