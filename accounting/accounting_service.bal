import ballerina/http;
import ballerina/sql;

type ChargeRequest record {|
    int consumerId;
    int orderId;
    decimal orderAmount;
|};

type ConsumerCharged record {|
    *http:Ok;
    record {|
        *Bill;
        *http:Links;
    |} body;
|};

type BillView record {|
    *http:Ok;
    record {|
        *Bill;
        *http:Links;
    |} body;
|};

type BillNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Bill cannot be found." 
    };
|};

# Represents an unexpected error
type InternalError record {|
   *http:InternalServerError;
    # Error payload
    record {| 
        string message;
    |} body;
|}; 

service on new http:Listener(8083) {

    isolated resource function post charge(@http:Payload ChargeRequest request) returns ConsumerCharged|InternalError|error {
        do {
            Bill generatedBill = check createBill(request.consumerId, request.orderId, request.orderAmount);
            check chargeConsumer(request.consumerId, request.orderAmount);

            return <ConsumerCharged>{ 
                body:{
                    ...generatedBill,
                    links: getLinks(generatedBill.id)
                } 
            };
        } on fail error e {
            return <InternalError>{ body: { message: e.message() }};
        }
    }

    isolated resource function get bill/[int id]() returns BillView|BillNotFound|InternalError {
        do {
            Bill bill = check getBill(id);
            return <BillView>{ 
                body:{
                    ...bill,
                    links: getLinks(id)
                } 
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <BillNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }
    }

}

# Obtain the HTTP links related to a given bill
#
# + billId - The ID of the bill
# + return - An array of links
isolated function getLinks(int billId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/bill/" + billId.toString(),
            methods: [http:GET]
        }
    ];
}

