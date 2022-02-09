import ballerinax/mysql;

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;

public function main() returns error? {

    mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT);

    _ = check dbClient->execute(`DROP DATABASE IF EXISTS Orders;`);

    _ = check dbClient->execute(`CREATE DATABASE IF NOT EXISTS Orders;`);

    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Orders.Orders (
            id              INTEGER AUTO_INCREMENT PRIMARY KEY,
            consumerId      INTEGER NOT NULL,
            restaurantId    INTEGER NOT NULL
        );
    `);

    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Orders.OrderItems (
            id              INTEGER AUTO_INCREMENT PRIMARY KEY,
            menuItemId      INTEGER NOT NULL,
            quantity        INTEGER NOT NULL,
            orderId         INTEGER NOT NULL,
            FOREIGN KEY (orderId) REFERENCES Orders.Orders(id) ON DELETE CASCADE,
            CONSTRAINT chk_quantity CHECK (quantity > 0)
        );
    `);

}
