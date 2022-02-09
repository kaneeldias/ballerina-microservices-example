import ballerinax/mysql;
import ballerina/sql;

public type Consumer record {|
    int id?;
    string name;
    string address;
|};

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;

final mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT, database=DATABASE);

isolated function createConsumer(Consumer consumer) returns Consumer|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO Consumers (name, address) VALUES (${consumer.name}, ${consumer.address})`);
    int|string? generatedConsumerId = result.lastInsertId;
    if generatedConsumerId is string? {
        return error("Unable to retrieve ID of restaurant.");
    }
    consumer.id = generatedConsumerId;
    return consumer;
}

isolated function getConsumer(int consumerId) returns Consumer|error {
    return check dbClient->queryRow(`SELECT id, name, address FROM Consumers WHERE id = ${consumerId}`);
}

isolated function deleteConsumer(int consumerId) returns error? {
    _ = check dbClient->execute(`DELETE FROM Consumers WHERE id = ${consumerId}`);
}

isolated function updateConsumer(Consumer consumer, int id) returns Consumer|error {
    _ = check dbClient->execute(`UPDATE Consumers SET name=${consumer.name}, address=${consumer.address} WHERE id = ${id}`);
    consumer.id = id;
    return consumer;
}
