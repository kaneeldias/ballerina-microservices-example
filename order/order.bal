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
configurable string MENU_ITEM_ENDPOINT = ?;

final mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT, database=DATABASE);
final http:Client consumerEndpoint = check new(CONSUMER_ENDPOINT);
final http:Client restaurantEndpoint = check new(RESTAURANT_ENDPOINT);
final http:Client menuItemEndpoint = check new(MENU_ITEM_ENDPOINT);

public type Order record {|
    int id?;
    Consumer consumer;
    Restaurant restaurant;
    OrderItem[] orderItems?;
|};

public type OrderItem record {|
    int id?;
    MenuItem menuItem;
    int quantity;
|};

public type Consumer record {
    int id;
    string name?;
    string address?;
};

public type Restaurant record {
    int id;
    string name?;
    string address?;
};

public type MenuItem record {|
    int id;
    string name?;
    decimal price?;
|};

public type CreateOrderItemRequest record {|
    OrderItem orderItem;
    int orderId;
|};


public isolated function createOrder(Order _order) returns int|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO Orders (consumerId, restaurantId) VALUES (${_order.consumer.id}, ${_order.restaurant.id})`);
    int|string? generatedOrderId = result.lastInsertId;
    if generatedOrderId is string? {
        return error("Unable to retrieve generated ID of order.");
    }
    return generatedOrderId;
}

public isolated function createOrderItem(OrderItem orderItem, int orderId) returns int|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO OrderItems (menuItemId, quantity, orderId) VALUES (${orderItem.menuItem.id}, ${orderItem.quantity}, ${orderId})`);
    int|string? generatedOrderItemId = result.lastInsertId;
    if generatedOrderItemId is string? {
        return error("Unable to retrieve generated ID of order item.");
    }
    return generatedOrderItemId;
}


public isolated function getOrder(int id) returns Order|error {
    Order result = check dbClient->queryRow(`SELECT id, consumerId AS 'consumer.id', restaurantId AS 'restaurant.id' FROM Orders WHERE id = ${id}`);
    return {
        id: id,
        consumer: check getConsumerDetails(result.consumer.id),
        restaurant: check getRestaurantDetails(result.restaurant.id),
        orderItems: check getOrderItems(id)
    };
}

public isolated function removeOrder(int id) returns error? {
    _ = check dbClient->execute(`DELETE FROM Orders WHERE id = ${id}`);
}

public isolated function removeOrderItem(int id) returns error? {
    _ = check dbClient->execute(`DELETE FROM OrderItems WHERE id = ${id}`);
}

public isolated function getOrderItems(int orderId) returns OrderItem[]|error {
    OrderItem[] orderItems = [];
    stream<OrderItem, error?> resultStream = dbClient->query(`SELECT id, menuItemId AS 'menuItem.id', quantity FROM OrderItems WHERE orderId = ${orderId}`);
    check from OrderItem orderItem in resultStream
        do {
            orderItems.push({
                id: orderId,
                menuItem: check getMenuItemDetails(orderItem.menuItem.id),
                quantity: orderItem.quantity
            });
        };
    return orderItems;
}

public isolated function getConsumerDetails(int consumerId) returns Consumer|error {
    Consumer consumer = check consumerEndpoint->get(consumerId.toString());
    return {
        id: consumerId,
        name: <string>consumer.name,
        address: <string>consumer.address
    };
}

public isolated function getRestaurantDetails(int restaurantId) returns Restaurant|error {
    Restaurant restaurant = check restaurantEndpoint->get(restaurantId.toString());
    return {
        id: restaurantId,
        name: <string>restaurant.name,
        address: <string>restaurant.address
    };
}

public isolated function getMenuItemDetails(int menuItemId) returns MenuItem|error {
    MenuItem menuItem = check menuItemEndpoint->get(menuItemId.toString());
    return {
        id: menuItemId,
        name: <string>menuItem.name,
        price: <decimal>menuItem.price
    };
}