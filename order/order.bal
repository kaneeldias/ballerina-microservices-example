import ballerina/sql;
import ballerinax/mysql;
import ballerina/http;
import ballerina/time;

configurable string USER = ?;   
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;
configurable string CONSUMER_ENDPOINT = ?;
configurable string RESTAURANT_ENDPOINT = ?;
configurable string MENU_ITEM_ENDPOINT = ?;
configurable string ACCOUNTING_ENDPOINT = ?;

final mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT, database=DATABASE);
final http:Client consumerEndpoint = check new(CONSUMER_ENDPOINT);
final http:Client restaurantEndpoint = check new(RESTAURANT_ENDPOINT);
final http:Client menuItemEndpoint = check new(MENU_ITEM_ENDPOINT);
final http:Client accountingEndpoint = check new(ACCOUNTING_ENDPOINT);

enum OrderState {
    APPROVAL_PENDING,
    APPROVED,
    REJECTED,
    CANCEL_PENDING,
    CANCELLED,
    REVISION_PENDING
}

type Order record {|
    int id;
    Consumer consumer;
    Restaurant restaurant;
    OrderItem[] orderItems;
    string deliveryAddress;
    time:Civil deliveryTime;
    OrderState status;
|};

type OrderItem record {|
    int id;
    MenuItem menuItem;
    int quantity;
|};

type Consumer record {|
    int id;
    string name;
    string address;
|};

type Restaurant record {|
    int id;
    string name;
    string address?;
|};

type MenuItem record {|
    int id;
    string name;
    decimal price;
|};

type OrderTableRow record {|
    int id;
    int consumerId;
    int restaurantId;
    string deliveryAddress;
    time:Civil deliveryTime;
    OrderState status;
|};

type OrderItemTableRow record {|
    int id;
    int menuItemId;
    int quantity;
|};

isolated function createOrder(int consumerId, int restaurantId, string deliveryAddress, time:Civil deliveryTime) returns Order|error {
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO Orders (consumerId, restaurantId, deliveryAddress, deliveryTime, status) 
        VALUES (${consumerId}, ${restaurantId}, ${deliveryAddress}, ${deliveryTime}, ${APPROVAL_PENDING})
    `);
    int|string? generatedOrderId = result.lastInsertId;
    if generatedOrderId is string? {
        return error("Unable to retrieve generated ID of order.");
    }
    return <Order>{
        id: generatedOrderId,
        consumer: check getConsumerDetails(consumerId),
        restaurant: check getRestaurantDetails(restaurantId),
        orderItems: [],
        deliveryAddress: deliveryAddress,
        deliveryTime: deliveryTime,
        status: APPROVAL_PENDING
    };
}

isolated function createOrderItem(int menuItemId, int quantity, int orderId) returns OrderItem|error {
    Order 'order = check getOrder(orderId);
    match 'order.status {
        APPROVED => {
            _ =  check changeOrderStatus(orderId, APPROVAL_PENDING);
        }
        APPROVAL_PENDING => {}
        _ => {
            return error("Cannot modify order");
        }
    }

    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO OrderItems (menuItemId, quantity, orderId) 
        VALUES (${menuItemId}, ${quantity}, ${orderId})
    `);
    int|string? generatedOrderItemId = result.lastInsertId;
    if generatedOrderItemId is string? {
        return error("Unable to retrieve generated ID of order item.");
    }
    return <OrderItem>{
        id: generatedOrderItemId,
        menuItem: check getMenuItemDetails(menuItemId),
        quantity: quantity
    };
}

isolated function getOrder(int id) returns Order|error {
    OrderTableRow result = check dbClient->queryRow(`
        SELECT id, consumerId, restaurantId, deliveryAddress, deliveryTime, status
        FROM Orders WHERE id = ${id}
    `);
    return <Order>{
        id: id,
        consumer: check getConsumerDetails(result.consumerId),
        restaurant: check getRestaurantDetails(result.restaurantId),
        orderItems: check getOrderItems(id),
        deliveryAddress: result.deliveryAddress,
        deliveryTime: result.deliveryTime,
        status: result.status
    };
}

isolated function getOrderItem(int id) returns OrderItem|error {
    OrderItemTableRow result = check dbClient->queryRow(`
        SELECT id, menuItemId, quantity
        FROM OrderItems WHERE id = ${id}
    `);
    return <OrderItem>{
        id: result.id,
        menuItem: check getMenuItemDetails(result.menuItemId),
        quantity: result.quantity
    };
}

isolated function getParentOrder(int id) returns Order|error {
    int orderId = check dbClient->queryRow(`SELECT orderId FROM OrderItems WHERE id=${id}`);
    return check getOrder(orderId);
}

isolated function removeOrder(int id) returns Order|error {
    Order 'order = check getOrder(id);
    _ = check dbClient->execute(`DELETE FROM Orders WHERE id = ${id}`);
    return 'order;
}

isolated function removeOrderItem(int id) returns OrderItem|error {
    Order 'order = check getParentOrder(id);
    match 'order.status {
        APPROVED => {
            _ =  check changeOrderStatus('order.id, APPROVAL_PENDING);
        }
        APPROVAL_PENDING => {}
        _ => {
            return error("Cannot modify order");
        }
    }

    OrderItem orderItem = check getOrderItem(id);
    _ = check dbClient->execute(`DELETE FROM OrderItems WHERE id = ${id}`);
    return orderItem;
}

isolated function getOrderItems(int orderId) returns OrderItem[]|error {
    OrderItem[] orderItems = [];
    stream<OrderItemTableRow, error?> resultStream = dbClient->query(`
        SELECT id, menuItemId, quantity 
        FROM OrderItems WHERE orderId = ${orderId}
    `);
    check from OrderItemTableRow orderItem in resultStream
        do {
            orderItems.push({
                id: orderItem.id,
                menuItem: check getMenuItemDetails(orderItem.menuItemId),
                quantity: orderItem.quantity
            });
        };
    return orderItems;
}

isolated function changeOrderStatus(int orderId, OrderState newStatus) returns Order|error {
    _ = check dbClient->execute(`UPDATE Orders SET status=${newStatus} WHERE id = ${orderId}`);
    Order 'order = check getOrder(orderId);
    return 'order;
}

isolated function confirmOrder(int orderId) returns Order|error {
    Order 'order = check changeOrderStatus(orderId, APPROVAL_PENDING);

    decimal orderTotal = 0;
    foreach OrderItem orderItem in 'order.orderItems {
        orderTotal += orderItem.menuItem.price;
    }

    http:Request request = new;
    request.setJsonPayload({
        orderId: orderId,
        amount: orderTotal
    });
    _ = check consumerEndpoint->post('order.consumer.id.toString() + "/validate", request, targetType = json);

    return 'order;
}


isolated function getConsumerDetails(int consumerId) returns Consumer|error {
    Consumer consumer = check consumerEndpoint->get(consumerId.toString());
    return {
        id: consumerId,
        name: <string>consumer.name,
        address: <string>consumer.address
    };
}

isolated function getRestaurantDetails(int restaurantId) returns Restaurant|error {
    Restaurant restaurant = check restaurantEndpoint->get(restaurantId.toString());
    return {
        id: restaurantId,
        name: <string>restaurant.name,
        address: <string>restaurant.address
    };
}

isolated function getMenuItemDetails(int menuItemId) returns MenuItem|error {
    MenuItem menuItem = check menuItemEndpoint->get(menuItemId.toString());
    return {
        id: menuItemId,
        name: <string>menuItem.name,
        price: <decimal>menuItem.price
    };
}
