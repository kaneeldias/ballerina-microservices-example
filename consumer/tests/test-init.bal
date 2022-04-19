import ballerina/test;
import ballerinax/mysql;

configurable string user = ?;   
configurable string password = ?;
configurable string host = ?;
configurable int port = ?;
configurable string database = ?;

@test:BeforeSuite
function databaseInit() returns error? {
    mysql:Client dbClient = check new(host = host, port = port, user = user, password = password, database = database);

    _ = check dbClient->execute(`CREATE DATABASE IF NOT EXISTS Consumer;`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Consumer.Consumers (
            id      INTEGER         AUTO_INCREMENT PRIMARY KEY,
            name    VARCHAR(255)    NOT NULL,
            address VARCHAR(255)    NOT NULL,
            email   VARCHAR(255)    NOT NULL
        );
    `);
}
