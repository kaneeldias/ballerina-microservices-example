import ballerina/sql;
import ballerinax/mysql;
import ballerina/http;

configurable string USER = ?;   
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;
configurable string CONSUMER_ENDPOINT = ?;
configurable string RESTAURANT_ENDPOINT = ?;
configurable string ORDER_ENDPOINT = ?;

final mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT, database=DATABASE);
final http:Client consumerEndpoint = check new(CONSUMER_ENDPOINT);
final http:Client restaurantEndpoint = check new(RESTAURANT_ENDPOINT);
final http:Client orderEndpoint = check new(ORDER_ENDPOINT);


// Consider read only records
type Bill record {|
    int id;
    Consumer consumer;
    Order 'order;
    decimal orderAmount;
|};

type Consumer record {
    int id;
    string name;
    string email;
};

type Order record {
    int id;
    OrderItem[] orderItems;
};

type OrderItem record {
    int id;
    MenuItem menuItem;
    int quantity;
};

type MenuItem record {
    int id;
    string name;
    decimal price;
};

type BillTableRow record {|
    int id;
    int consumerId;
    int orderId;
    decimal orderAmount;
|};

public isolated function createBill(int consumerId, int orderId, decimal orderAmount) returns Bill|error {
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO bills (consumerId, orderId, orderAmount) 
        VALUES (${consumerId}, ${orderId}, ${orderAmount})
    `);

    int|string? generatedBillId = result.lastInsertId;
    if generatedBillId is string? {
        return error("Unable to retrieve generated ID of bill");
    }

    return <Bill>{
        id: generatedBillId,
        consumer: check getConsumerDetails(consumerId),
        'order: check getOrderDetails(orderId),
        orderAmount: orderAmount
    };
}

public isolated function getBill(int id) returns Bill|error {
    BillTableRow result = check dbClient->queryRow(`
        SELECT id, consumerId, orderId, orderAmount
        FROM Bills WHERE id = ${id}
    `);
    return <Bill>{
        id: id,
        consumer: check getConsumerDetails(result.consumerId),
        'order: check getOrderDetails(result.orderId),
        orderAmount: result.orderAmount
    };
}

public isolated function chargeConsumer(int consumerId, decimal orderAmount) returns error? {
    // Implement logic
    return;
}

# Retrieves the details of a consumer
#
# + consumerId - The ID of the consumer for which the detailes are required
# + return - The details of the customer if the retrieval was successful. An error if unsuccessful
isolated function getConsumerDetails(int consumerId) returns Consumer|error {
    Consumer consumer = check consumerEndpoint->get(consumerId.toString());
    return <Consumer>{
        id: consumerId,
        name: consumer.name,
        email: consumer.email
    };
}

isolated function getOrderDetails(int orderId) returns Order|error {
    Order 'order = check orderEndpoint->get(orderId.toString());
    OrderItem[] orderItems = [];

    foreach OrderItem orderItem in 'order.orderItems {
        orderItems.push(<OrderItem>{
            id: orderItem.id,
            menuItem: {
                id: orderItem.menuItem.id,
                name: orderItem.menuItem.name,
                price: orderItem.menuItem.price
            },
            quantity: orderItem.quantity
        });
    }

    return <Order>{
        id: orderId,
        orderItems: orderItems
    };
}
