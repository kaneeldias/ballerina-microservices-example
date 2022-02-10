import ballerina/http;

service on new http:Listener(8083) {

    isolated resource function post .(@http:Payload CreateBillRequest request) returns http:Created|error {
        int generatedBillId = check createBill(request._order.id, request.amount, request._order.consumer, request._order.restaurant, request.couponCode);
        return <http:Created>{ 
            body:{
                message: "New bill created",
                "bidlID": generatedBillId
            } 
        };
    }

}
