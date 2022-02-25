import ballerina/sql;
import ballerinax/mysql;
import ballerina/time;
import ballerina/http;

enum DeliveryState {
    READY_FOR_PICKUP = "READY_FOR_PICKUP",
    PICKED_UP = "PICKED_UP",
    DELIVERED = "DELIVERED"
}

type Delivery record {|
    int id;
    Order 'order;
    Courier courier;
    string pickUpAddress;
    time:Civil? pickUpTime;
    string deliveryAddress;
    time:Civil? deliveryTime;
    DeliveryState status;
|};

# Represents an order
type Order record {
    # The ID of the order
    int id;
    # The items contained within the order
    OrderItem[] orderItems;
};

# Represents and order item
type OrderItem record {
    # The ID of the order item
    int id;
    # The menu item relevant to the order item
    MenuItem menuItem;
    # The quantity of menu items requested in the order item
    int quantity;
};

# Represents a menu item
type MenuItem record {|
    # The ID of the menu item
    int id;
    # The name of the menu item
    string name;
    # The price of the menu item
    decimal price;
|};

configurable string USER = ?;   
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;
configurable string ORDER_ENDPOINT = ?;

final mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT, database=DATABASE);
final http:Client orderEndpoint = check new(ORDER_ENDPOINT);

isolated function scheduleDelivery(int orderId, string pickUpAddress, string deliveryAddress) returns Delivery|error {
    Courier availableCourier = check getAvailableCourier(pickUpAddress);
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO Deliveries (orderId, courierId, pickUpAddress, deliveryAddress, status) 
        VALUES (${orderId}, ${availableCourier.id}, ${pickUpAddress}, ${deliveryAddress}, ${READY_FOR_PICKUP})
    `);
    int|string? generatedDeliveryId = result.lastInsertId;
    if generatedDeliveryId is string? {
        return error("Unable to retrieve generated ID of delivery.");
    }

    return <Delivery>{
        id: generatedDeliveryId,
        'order: check getOrderDetails(orderId),
        courier: availableCourier,
        pickUpAddress: pickUpAddress,
        pickUpTime: (),
        deliveryAddress: deliveryAddress,
        deliveryTime: (),
        status: READY_FOR_PICKUP
    };
}

isolated function getDelivery(int id) returns Delivery|error {
    record {|
        int id;
        int orderId;
        int courierId;
        string pickUpAddress;
        time:Civil pickUpTime;
        string deliveryAddress;
        time:Civil deliveryTime;
        string status;
    |} deliveryRow = check dbClient->queryRow(`
        SELECT id, orderId, courierId, pickUpAddress, pickUpTime, deliveryAddress, deliveryTime, status 
        FROM Deliveries 
        WHERE id=${id}
    `);

    return <Delivery>{
        id: deliveryRow.id,
        'order: check getOrderDetails(deliveryRow.orderId),
        courier: check getCourier(deliveryRow.courierId),
        pickUpAddress: deliveryRow.pickUpAddress,
        pickUpTime: deliveryRow.pickUpTime,
        deliveryAddress: deliveryRow.deliveryAddress,
        deliveryTime: deliveryRow.deliveryTime,
        status: <DeliveryState>deliveryRow.status
    };
}

isolated function updateDelivery(int id, DeliveryState newStatus) returns Delivery|error {
    _ = check dbClient->execute(`UPDATE Deliveries SET status=${newStatus} WHERE id=${id}`);

     if newStatus is PICKED_UP {
        _  = check dbClient->execute(`UPDATE Deliveries SET pickUpTime=${time:utcNow()} WHERE id=${id}`);
    }

    if newStatus is DELIVERED {
        _  = check dbClient->execute(`UPDATE Deliveries SET deliveryTime=${time:utcNow()} WHERE id=${id}`);
    }

    Delivery delivery = check getDelivery(id);
    _ = check orderEndpoint->put(delivery.'order.id.toString() + "/updateStatus/" + newStatus.toString(), message = (), targetType = json);
    return delivery;
}

# Retrieves the details of an order
#
# + orderId - The ID of the order for which the detailes are required
# + return - The details of the order if the retrieval was successful. An error if unsuccessful
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