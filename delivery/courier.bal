import ballerina/sql;

type Courier record {|
    int id;
    string name;
|};

isolated function createCourier(string name) returns Courier|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO Couriers (name) VALUES (${name})`);
    int|string? generatedCourierId = result.lastInsertId;
    if generatedCourierId is string? {
        return error("Unable to retrieve generated ID of courier.");
    }

    return <Courier>{
        id: generatedCourierId,
        name: name
    };
}

isolated function getCourier(int id) returns Courier|error {
    return check dbClient->queryRow(`SELECT id, name FROM Couriers WHERE id=${id}`);
}

isolated function getAvailableCourier(string pickUpAddres) returns Courier|error {
    return check dbClient->queryRow(`SELECT id, name FROM Couriers ORDER BY RAND() LIMIT 1;`);
}