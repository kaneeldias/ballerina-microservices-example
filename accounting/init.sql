CREATE DATABASE IF NOT EXISTS Accounting;

CREATE TABLE IF NOT EXISTS Accounting.bills (
    id          INTEGER         AUTO_INCREMENT PRIMARY KEY,
    orderId     INTEGER         NOT NULL,
    orderAmount DECIMAL(10,2)   NOT NULL,
    deliveryFee DECIMAL(10,2)   NOT NULL,
    discount    DECIMAL(10,2)   NOT NULL,
    finalAmount DECIMAL(10,2)   NOT NULL
);
