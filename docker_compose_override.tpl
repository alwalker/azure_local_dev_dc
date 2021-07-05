version: '3'
services:
  database:
    build:
      context: ./
      dockerfile: Dockerfile.mssql
    ports:
      - "9000:1433"
    environment: 
      ACCEPT_EULA: y
      SA_PASSWORD: "${db_password}"