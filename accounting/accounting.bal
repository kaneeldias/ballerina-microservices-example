import ballerina/sql;
import ballerinax/mysql;
import ballerina/http;

configurable string USER = ?;   
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;
configurable string CONSUMER_ENDPOINT = ?;

final mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT, database=DATABASE);
final http:Client consumerEndpoint = check new(CONSUMER_ENDPOINT);

public type Bill record {|
    int id?;
    int orderId;
    decimal orderAmount;
    decimal deliverFee;
    decimal discount;
    decimal finalAmount;
|};

public type CreateBillRequest record {|
    Order _order;
    decimal amount;
    string couponCode;
|};

public type Order record {
    int id;
    Consumer consumer;
    Restaurant restaurant;
};

public type Consumer record {
    int id;
    string address;
};

public type Restaurant record {
    int id;
    string address;
};

public isolated function createBill(int orderId, decimal amount, Consumer consumer, Restaurant restaurant, string couponCode) returns int|error {
    decimal deliveryFee = calculateDeliveryFee(consumer.address, restaurant.address);
    decimal discount = applyCoupon(amount, couponCode);
    decimal finalAmount = amount + deliveryFee - discount;

    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO bills (orderId, orderAmount, deliveryFee, discount, finalAmount) 
        VALUES (${orderId}, ${amount}, ${deliveryFee}, ${discount}, ${finalAmount})
    `);

    int|string? generatedBillId = result.lastInsertId;
    if generatedBillId is string? {
        return error("Unable to retrieve generated ID of bill");
    }

    chargeConsumer(consumer, amount);
    return generatedBillId;
}

public isolated function calculateDeliveryFee(string consumerAddress, string restaurantAddress) returns decimal {
    // Implement calculation logic
    return 10;
}

public isolated function applyCoupon(decimal amount, string couponCode) returns decimal {
    // Implement logic
    return 20;
}

public isolated function chargeConsumer(Consumer consumer, decimal amount) {
    // Implement logic
}
