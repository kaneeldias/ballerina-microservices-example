CREATE DATABASE IF NOT EXISTS Orders;

CREATE TABLE IF NOT EXISTS Orders.Orders (
    id              INTEGER AUTO_INCREMENT PRIMARY KEY,
    consumerId      INTEGER NOT NULL,
    restaurantId    INTEGER NOT NULL,
);

CREATE TABLE IF NOT EXISTS Orders.OrderItems (
    id              INTEGER AUTO_INCREMENT PRIMARY KEY,
    menuItemId      INTEGER NOT NULL,
    quantity        INTEGER NOT NULL,
    orderId         INTEGER NOT NULL,
    FOREIGN KEY (orderId) REFERENCES Order.Orders(id) ON DELETE CASCADE,
    CONSTRAINT chk_quantity CHECK (quantity > 0)
);