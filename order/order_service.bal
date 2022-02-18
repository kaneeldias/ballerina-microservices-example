import ballerina/http;
import ballerina/sql;
import ballerina/time;

type CreateOrderRequest record {|
    int consumerId;
    int restaurantId;
    string deliveryAddress;
    time:Civil deliveryTime;
    CreateOrderRequestItem[] orderItems; 
|};

type CreateOrderRequestItem record {|
    int menuItemId;
    int quantity;
|};

type CreateOrderItemRequest record {|
    int orderId;
    int menuItemId;
    int quantity;
|};

type OrderCreated record {|
    *http:Created;
    record {|
        *Order;
        *http:Links;
    |} body;
|};

type OrderItemCreated record {|
    *http:Created;
    record {|
        *OrderItem;
        *http:Links;
    |} body;
|};

# Error response for when the requested order cannot be found
type OrderNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Order cannot be found." 
    };
|};

# Error response for when the requested order item cannot be found
type OrderItemNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Order item cannot be found." 
    };
|};
# Response for a successful order retrieval
type OrderView record {|
    *http:Ok;
    # Details of the retrieved order along with the HTTP links to manage it
    record {|
        *Order;
        *http:Links;
    |} body;
|};

type OrderDeleted record {|
    *http:Ok;
    # Details of the deleted order
    Order body;
|};

type OrderItemDeleted record {|
    *http:Ok;
    # Details of the deleted order item
    OrderItem body;
|};

type OrderConfirmed record {|
    *http:Ok;
    # Details of the confirmed order
    Order body;
|};

# Represents an unexpected error
type InternalError record {|
   *http:InternalServerError;
    # Error payload
    record {| 
        string message;
    |} body;
|}; 


service /'order on new http:Listener(8082) {

    isolated resource function post .(@http:Payload CreateOrderRequest request) returns OrderCreated|InternalError {
        do {
            transaction {
                Order generatedOrder = check createOrder(request.consumerId, request.restaurantId, request.deliveryAddress, request.deliveryTime);

                foreach CreateOrderRequestItem orderItem in request.orderItems {
                    OrderItem generatedOrderItem = check createOrderItem(orderItem.menuItemId, orderItem.quantity, generatedOrder.id);
                    generatedOrder.orderItems.push(generatedOrderItem);
                }

                check commit;

                return <OrderCreated>{ 
                    headers: {
                        location: "/order/" + generatedOrder.id.toString()
                    },
                    body: {
                        ...generatedOrder,
                        links: getOrderLinks(generatedOrder.id)
                    }
                };
            }
        } on fail error e {
            return <InternalError>{ body: { message: e.toString() }};
        }
    }

    isolated resource function get [int id]() returns OrderView|OrderNotFound|InternalError {
        do {
            Order 'order = check getOrder(id);
            return <OrderView>{ 
                body: {
                    ...'order,
                    links: getOrderLinks(id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <OrderNotFound>{};
            }
            return <InternalError>{ body: { message: e.toString() }};
        } 
    }

    isolated resource function post [int orderId]/item(@http:Payload CreateOrderItemRequest request) returns OrderItemCreated|InternalError {
        do {
            OrderItem generatedOrderItem = check createOrderItem(request.menuItemId, request.quantity, request.orderId);
            return <OrderItemCreated>{ 
                body: {
                    ...generatedOrderItem,
                    links: getOrderItemLinks(generatedOrderItem.id, orderId)
                } 
            };
        } on fail error e {
            return <InternalError>{ body: { message: e.toString() }};
        } 
    }

    isolated resource function delete [int id]() returns OrderDeleted|OrderNotFound|InternalError {
        do {
            Order 'order = check removeOrder(id);
            return <OrderDeleted> { body: 'order };
        } on fail error e {
            if e is sql:NoRowsError {
                return <OrderNotFound>{};
            }
            return <InternalError>{ body: { message: e.toString() }};
        } 
    }

    isolated resource function delete orderItem/[int id]() returns OrderItemDeleted|OrderItemNotFound|InternalError {
        do {
            OrderItem orderItem = check removeOrderItem(id);
            return <OrderItemDeleted> { body: orderItem };
        } on fail error e {
            if e is sql:NoRowsError {
                return <OrderItemNotFound>{};
            }
            return <InternalError>{ body: { message: e.toString() }};
        } 
    }

    isolated resource function get [int id]/confirm() returns OrderConfirmed|OrderNotFound|InternalError {
        do {
            Order 'order = check confirmOrder(id);
            return <OrderConfirmed> { body: 'order };
        } on fail error e {
            if e is sql:NoRowsError {
                return <OrderNotFound>{};
            }
            return <InternalError>{ body: { message: e.toString() }};
        }
    }
}

isolated function getOrderLinks(int orderId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/order/" + orderId.toString(),
            methods: [http:GET]
        },
        {
            rel: "update",
            href: "/order/" + orderId.toString(),
            methods: [http:PUT]
        },
        {
            rel: "delete",
            href: "/order/" + orderId.toString(),
            methods: [http:DELETE]
        }
    ];
}

isolated function getOrderItemLinks(int orderItemId, int parentOrderId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/order/" + parentOrderId.toString() + "/item/" + orderItemId.toString(),
            methods: [http:GET]
        },
        {
            rel: "update",
            href: "/order/" + parentOrderId.toString() + "/item/" + orderItemId.toString(),
            methods: [http:PUT]
        },
        {
            rel: "delete",
            href: "/order/" + parentOrderId.toString() + "/item/" + orderItemId.toString(),
            methods: [http:DELETE]
        },
        {
            rel: "parent order",
            href: "/order/" + parentOrderId.toString(),
            methods: [http:GET]
        }
    ];
}