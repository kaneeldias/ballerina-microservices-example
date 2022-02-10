# Microservices Example in Ballerina

## Overview
This example is based on the [FTGO application](https://github.com/microservices-patterns/ftgo-application), a sample of an online food delivery application, connecting consumers and restaurants.

![Architectute](/assets/architecture.png)

The example has four different services
* Consumer
* Restaurant
* Order
* Accounting

## Consumer Service
The consumer service represents a customer who places orders through the application.

## Restaurant Service
The restaurant service represents a restaurant, with its menu, menu items and prices.

## Order Service
The order service handles orders placed by a consumer for a restaurant

## Accounting Service
The accounting service calulates the fee to be charged from the consumer and manages the accounting process.