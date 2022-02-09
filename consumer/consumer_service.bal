import ballerina/http;
import ballerina/sql;

public type UpdateConsumerRequest record {|
    string name;
    string address;
|};

service on new http:Listener(8080) {

    isolated resource function post .(@http:Payload Consumer consumer) returns http:Created|error {
        Consumer generatedConsumer = check createConsumer(consumer);
        return <http:Created>{ body: {message: "New consumer created", consumer: generatedConsumer} };
    }

    isolated resource function get [int id]() returns Consumer|http:NotFound|error {
        Consumer|error consumer = getConsumer(id);
        if consumer is sql:NoRowsError {
            return <http:NotFound>{ body: {message: "Cannot find consumer with provided ID"} };
        }
        return consumer;
    }

    isolated resource function delete [int id]() returns http:Ok|error {
        _ = check deleteConsumer(id);
        return <http:Ok>{ body: {message: "Consumer deleted", id: id} };
    }

    isolated resource function put [int id](@http:Payload Consumer consumer) returns http:Ok|error {
        Consumer generatedConsumer = check updateConsumer(consumer, id);
        return <http:Ok>{ body: {message: "Consumer updated", consumer: generatedConsumer} };
    }
        
}
