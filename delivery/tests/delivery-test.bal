import ballerina/test;
import ballerina/log;
import ballerina/http;

type DeliveryScheduledRecord record {|
    *Delivery;
    *http:Links;
|};

http:Client deliveryClient = check new("http://localhost:8084/delivery/");

@test:Config {
    groups: ["delivery"]
}
function scheduleDeliveryTest() returns error? {
    http:Request scheduleDeliveryRequest = new;
    ScheduleDeliveryRequest requestPayload = {
        orderId: 1,
        pickUpAddress: "test pickup address",
        deliveryAddress: "test delivery address"
    };
    scheduleDeliveryRequest.setJsonPayload(requestPayload.toJson());
    http:Response response = check deliveryClient->post("schedule", scheduleDeliveryRequest);
    test:assertEquals(response.statusCode, 201);

    log:printInfo((check response.getJsonPayload()).toJsonString());
    DeliveryScheduledRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData.'order.id, requestPayload.orderId);
    test:assertEquals(returnData.pickUpAddress, requestPayload.pickUpAddress);
    test:assertEquals(returnData.deliveryAddress, requestPayload.deliveryAddress);
}