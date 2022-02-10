import ballerina/http;
import ballerina/sql;

service on new http:Listener(8082) {

    isolated resource function post .(@http:Payload Order orderRequest) returns http:Created|error {
        int generatedOrderId = check createOrder(orderRequest);
        return <http:Created>{ 
            body:{
                message: "New order created",
                "orderId": generatedOrderId
            } 
        };
    }

    isolated resource function get [int id]() returns Order|http:NotFound|error {
        Order|error _order = getOrder(id);
        if _order is sql:NoRowsError {
            return <http:NotFound>{ body: {message: "Cannot find order with provided ID"} };
        }
        if _order is error {
            return _order;
        }
        return _order;
    }

    isolated resource function post orderItem(@http:Payload CreateOrderItemRequest orderItemRequest) returns http:Created|error {
        int generatedOrderItemId = check createOrderItem(orderItemRequest.orderItem, orderItemRequest.orderId);
        return <http:Created>{ 
            body: {
                message: "New order item created",
                "orderItemId": generatedOrderItemId
            } 
        };
    }

    isolated resource function delete [int id]() returns http:Ok|error {
        _ = check removeOrder(id);
        return <http:Ok> { 
            body: {
                message: "Order removed"
            } 
        };
    }

    isolated resource function delete orderItem/[int id]() returns http:Ok|error {
        _ = check removeOrderItem(id);
        return <http:Ok> { 
            body: {
                message: "Order item removed"
            } 
        };
    }

    isolated resource function get [int id]/confirm(string couponCode) returns http:Ok|error {
        _ = check confirmOrder(id, couponCode);
        return <http:Ok> { 
            body: {
                message: "Order has been confirmed"
            } 
        };
        
    }
}
