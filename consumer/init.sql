CREATE DATABASE IF NOT EXISTS Consumer;

CREATE TABLE IF NOT EXISTS Consumer.Consumers (
    id      INTEGER         AUTO_INCREMENT PRIMARY KEY,
    name    VARCHAR(255)    NOT NULL,
    address VARCHAR(255)    NOT NULL,
    email   VARCHAR(255)    NOT NULL
);
