import ballerina/http;
import ballerina/sql;

# Request body to be used when creating and updating a consumer
public type ConsumerRequest record {
    # Name of the consumer
    string name;
    # Address of the consumer
    string address;
    # Email address of the consumer
    string email;
};

# Response for a successful consumer creation
public type ConsumerCreated record {|
    *http:Created;
    *http:Links;
    # Details of the created consumer
    Consumer body;
|};

# Response for a successful consumer fetch
public type ConsumerView record {|
    *http:Links;
    # Details of the requested consumer
    Consumer body;
|};

# Error response for when the requested consumer cannot be found
public type ConsumerNotFound record {|
    *http:NotFound;
|};

# Response for a successful consumer deletion
public type ConsumerDeleted record {|
    *http:Ok;
    # Details of the deleted consumer
    Consumer body;
|};

# Response for a successful consumer update
public type ConsumerUpdated record {|
    *http:Ok;
    *http:Links;
    # Updated details of the consumer
    Consumer body;
|};

# Represents an unexpected error
public type ConsumerInternalError record {|
   *http:InternalServerError;
   # Error payload
    record {| 
        string message;
    |} body;
|}; 

@http:ServiceConfig { cors: { allowOrigins: ["*"] } }
service /consumer on new http:Listener(8080) {

    # Resource function to create a new consumer
    #
    # + request - Details of the consumer to be created.
    # + return - `ConsumerCreated` if the request was sucessful, or a `ConsumerInternalError` if the request was unsuccessful
    isolated resource function post .(@http:Payload ConsumerRequest request) returns ConsumerCreated|ConsumerInternalError {
        do {
            Consumer generatedConsumer = check createConsumer(request.name, request.address, request.email);
            return <ConsumerCreated>{ 
                headers: {
                    location: "/consumer/" + generatedConsumer.id.toString()
                },
                body: generatedConsumer,
                links: getLinks(generatedConsumer.id)
            };
        } on fail error e {
            return <ConsumerInternalError>{ body: { message: e.toString() }};
        }
    }

    # Resource function to fetch the details of a consumer
    #
    # + id - The ID of the requested consumer
    # + return - `ConsumerView` if the details are successfully fetched.
    #            `ConsumerNotFound` if a consumer with the provided ID was not found.
    #            `ConsumerInternalError` if the request was not successful
    isolated resource function get [int id]() returns ConsumerView|ConsumerNotFound|ConsumerInternalError {
        do {
            Consumer consumer = check getConsumer(id);
            return <ConsumerView>{ 
                body: consumer,
                links: getLinks(consumer.id)
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <ConsumerNotFound>{};
            }
            return <ConsumerInternalError>{ body: { message: e.toString() }};
        }       
    }

    # Resource function to delete a consumer
    #
    # + id - The ID of the consumer to be deleted
    # + return - `ConsumerDeleted` if the consumer was successfully deleted.
    #            `ConsumerNotFound` if a consumer with the provided ID was not found.
    #            `ConsumerInternalError` if the request was not successful
    isolated resource function delete [int id]() returns ConsumerDeleted|ConsumerNotFound|ConsumerInternalError {
        do {
            Consumer consumer = check deleteConsumer(id);
            return <ConsumerDeleted>{ body: consumer};
        } on fail error e {
            if e is sql:NoRowsError {
                return <ConsumerNotFound>{};
            }
            return <ConsumerInternalError>{ body: { message: e.toString() }};
        }       
    }

    # Resource function to update the details of the consumer
    #
    # + id - The ID of the consumer to be updated  
    # + request - Details of the consumer to be update.
    # + return - `ConsumerUpdated` if the consumer was successfully updated.
    #            `ConsumerInternalError` if the request was not successful
    isolated resource function put [int id](@http:Payload ConsumerRequest request) returns ConsumerUpdated|ConsumerInternalError {
        do {
            Consumer updatedConsumer = check updateConsumer(id, request.name, request.address, request.email);
            return <ConsumerUpdated>{ 
                body: updatedConsumer,
                links: getLinks(updatedConsumer.id)
            };
        } on fail error e {
            return <ConsumerInternalError>{ body: { message: e.toString() }};
        }       
    }
        
}

# Returns the links to a given resource to be used in the HTTP header
#
# + consumerId - The ID of the consumer
# + return - An array of links
isolated function getLinks(int consumerId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/consumer/" + consumerId.toString(),
            methods: [http:GET]
        },
        {
            rel: "update",
            href: "/consumer/" + consumerId.toString(),
            methods: [http:PUT]
        },
        {
            rel: "delete",
            href: "/consumer/" + consumerId.toString(),
            methods: [http:DELETE]
        }
    ];
}
