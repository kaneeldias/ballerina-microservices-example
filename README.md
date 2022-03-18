# Microservices example in Ballerina

## Overview
This example is based on the [FTGO application](https://github.com/microservices-patterns/ftgo-application), a sample of an online food delivery application, connecting consumers and restaurants.

![Architectute](/assets/architecture.png)

The example has five different services
* Consumer
* Restaurant
* Order
* Accounting
* Delivery

These four services are interacted with by three types of users
* Consumers
* Restaurants
* Couriers

## Consumer service
The consumer service represents a customer who places orders through the application.

The data structure of a consumer is as follows
```ballerina
public type Consumer record {|
    int id;
    string name;
    string address;
    string email;
|};
```

This service provides four basic endpoints:
### 1. Create consumer
> Endpoint: `/`  
> Method: `POST`  
> Request payload: `ConsumerRequest`  

Creates a new consumer using the provided details.

### 2. Get consumer
> Endpoint: `/<consumerId>`  
> Method: `GET`  

Retrieves the details of the consumer with the given ID. 

### 3. Delete consumer
> Endpoint: `/<consumerId>`  
> Method: `DELETE`  

Deleted the consumer with the given ID. Returns a 404 Not Found error if a consumer with the given ID is not found. 

### 4. Update consumer
> Endpoint: `/<consumerId>`  
> Method: `POST`  
> Request payload: `ConsumerRequest`  

Updates the details of the consumer with the given ID using the provided details.

These four endpoints showcases the basic CRUD functionalities and how it can be achieved with Ballerina.

### Data storage and retrieval
The consumer service has it's own MySQL database for storing relevant consumer data. Since this service does not access data outside of it's own module, there is no requirement to make any REST API calls to access the other microservices.

### Order validation
This service also provides the endpoint `<consumerId>/validate` to validate an order placed by a consumer. This method is currently a dummy method, and does not perform any functional business logic. 

## Restaurant service
The restaurant service represents a restaurant, with its menu, menu items and prices. A restaurant can contain multiple menus; and a menu can contain multiple menu items.

The basic data structure of a restaurant and its associated data types are as follows.
```ballerina
type Restaurant record {|
    int id;
    string name;
    string address;
    Menu[] menus;
|};

type Menu record {|
    int id;
    string name;
    MenuItem[] items;
|};

type MenuItem record {|
    int id;
    string name;
    decimal price;
|};
```

This service provides endpoints to perform basic CRUD functionalities with restaurants, menus and menu items through 12 different endpoints.

### Data storage and retrieval
The restaurant service has it's own MySQL database for storing relevant restaurant data. Since this service does not access data outside of it's own module, there is no requirement to make any REST API calls to access the other microservices.

## Order service
The order service handles orders placed by a consumer for a restaurant. 

## Accounting service
The accounting service calulates the fee to be charged from the consumer and manages the accounting process.

## Delivery Service
The delivery service is responsible for the management of couriers and managing the delivery of orders from the restaurant to the consumer.