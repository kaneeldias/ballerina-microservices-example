import ballerinax/mysql;
import ballerina/sql;

public type Consumer record {|
    int id;
    string name;
    string address;
    string email;
|};

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;

final mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT, database=DATABASE);

isolated function createConsumer(string name, string address, string email) returns Consumer|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO Consumers (name, address, email) VALUES (${name}, ${address}, ${email})`);
    int|string? generatedConsumerId = result.lastInsertId;
    if generatedConsumerId is string? {
        return error("Unable to retrieve generated ID of consumer.");
    }
    
    return <Consumer>{
        id: generatedConsumerId,
        name: name,
        address: address,
        email: email
    };
}

isolated function getConsumer(int consumerId) returns Consumer|error {
    return check dbClient->queryRow(`SELECT id, name, address, email FROM Consumers WHERE id = ${consumerId}`);
}

isolated function deleteConsumer(int consumerId) returns Consumer|error {
    Consumer consumer = check getConsumer(consumerId);
    _ = check dbClient->execute(`DELETE FROM Consumers WHERE id = ${consumerId}`);
    return consumer;
}

isolated function updateConsumer(int id, string name, string address, string email) returns Consumer|error {
    _ = check dbClient->execute(`UPDATE Consumers SET name=${name}, address=${address}, email=${email} WHERE id = ${id}`);
    return <Consumer>{
        id: id,
        name: name,
        address: address,
        email: email
    };
}
