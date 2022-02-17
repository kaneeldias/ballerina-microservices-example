import ballerina/http;
import ballerina/sql;

type CreateRestaurantRequest record {|
    string name;
    string address;
    CreateRestaurantRequestMenu[] menus;
|};

type CreateRestaurantRequestMenu record {|
    string name;
    CreateMenuRequestMenuItem[] items;
|};

type CreateMenuRequestMenuItem record {|
    string name;
    decimal price;
|};

type UpdateRestaurantRequest record {|
    string name;
    string address;
|};

type UpdateMenuRequest record {|
    string name;
|};

type UpdateMenuItemRequest record {|
    string name;
    decimal price;
|};

type RestaurantCreated record {|
    *http:Created;
    record {|
        *Restaurant;
        *http:Links;
    |} body;
|};

type MenuCreated record {|
    *http:Created;
    record {|
        *Menu;
        *http:Links;
    |} body;
|};

type MenuItemCreated record {|
    *http:Created;
    record {|
        *MenuItem;
        *http:Links;
    |} body;
|};

type RestaurantNotFound record {|
    *http:NotFound;
    readonly record {} body = { 
        "message": "Restaurant cannot be found." 
    };
|};

type MenuNotFound record {|
    *http:NotFound;
    readonly record {} body = { 
        "message": "Menu cannot be found." 
    };
|};

type MenuItemNotFound record {|
    readonly record {} body = { 
        "message": "Menu cannot be found." 
    };
    *http:NotFound;
|};

type CreateMenuRequest record {|
    string name;
    CreateMenuRequestMenuItem[] menuItems;
|};

type CreateMenuItemRequest record {|
    string name;
    decimal price;
|};

type RestaurantView record {|
    *http:Ok;
    record {|
        *Restaurant;
        *http:Links;
    |} body;
|};

type MenuView record {|
    *http:Ok;
    record {|
        *Menu;
        *http:Links;
    |} body;
|};

type MenuItemView record {|
    *http:Ok;
    record {|
        *MenuItem;
        *http:Links;
    |} body;
|};

type RestaurantDeleted record {|
    *http:Ok;
    Restaurant body;
|};

type MenuDeleted record {|
    *http:Ok;
    Menu body;
|};

type MenuItemDeleted record {|
    *http:Ok;
    MenuItem body;
|};

type RestaurantUpdated record {|
    *http:Ok;
    record {|
        *Restaurant;
        *http:Links;
    |} body;
|};

type MenuUpdated record {|
    *http:Ok;
    record {|
        *Menu;
        *http:Links;
    |} body;
|};

type MenuItemUpdated record {|
    *http:Ok;
    record {|
        *MenuItem;
        *http:Links;
    |} body;
|};

public type RestaurantInternalError record {|
   *http:InternalServerError;
    record {| 
        string message;
    |} body;
|}; 


service on new http:Listener(8081) {

    isolated resource function post restaurant(@http:Payload CreateRestaurantRequest request) returns RestaurantCreated|RestaurantInternalError {
        do {
            transaction {
                Restaurant generatedRestaurant = check createRestaurant(request.name, request.address);

                foreach CreateRestaurantRequestMenu menu in request.menus {
                    Menu generatedMenu = check createMenu(menu.name, generatedRestaurant.id);

                    foreach CreateMenuRequestMenuItem menuItem in menu.items {
                        MenuItem generatedMenuItem = check createMenuItem(menuItem.name, menuItem.price, generatedMenu.id);
                        generatedMenu.items.push(generatedMenuItem);
                    }

                    generatedRestaurant.menus.push(generatedMenu);
                }

                check commit;

                return <RestaurantCreated>{ 
                    headers: {
                        location: "/restaurant/" + generatedRestaurant.id.toString()
                    },
                    body: {
                        ...generatedRestaurant,
                        links: getRestaurantLinks(generatedRestaurant.id)
                    }
                };
            }
        } on fail error e {
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }
    }

    isolated resource function post restaurant/[int restaurantId]/menu(@http:Payload CreateMenuRequest request) returns MenuCreated|RestaurantInternalError {
        do {
            transaction {
                Menu generatedMenu = check createMenu(request.name, restaurantId);

                foreach CreateMenuRequestMenuItem menuItem in request.menuItems {
                    MenuItem generatedMenuItem = check createMenuItem(menuItem.name, menuItem.price, generatedMenu.id);
                    generatedMenu.items.push(generatedMenuItem);
                }

                check commit;

                return <MenuCreated>{ 
                    headers: {
                        location: "/menu/" + generatedMenu.id.toString()
                    },
                    body: {
                        ...generatedMenu,
                        links: getMenuLinks(generatedMenu.id, restaurantId)
                    }
                };
            }
        } on fail error e {
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }
    }

    isolated resource function post restaurant/[int restaurantId]/menu/[int menuId]/item(@http:Payload CreateMenuItemRequest request) returns MenuItemCreated|RestaurantInternalError {
        do {
            MenuItem generatedMenuItem = check createMenuItem(request.name, request.price, menuId);
            return <MenuItemCreated>{ 
                headers: {
                    location: "/restaurant/" + restaurantId.toString() + "/menu/" + menuId.toString() + "/menuItem/" + generatedMenuItem.id.toString()
                },
                body: {
                    ...generatedMenuItem,
                    links: getMenuItemLinks(generatedMenuItem.id, menuId, restaurantId)
                }
            };
        } on fail error e {
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }
    }

    isolated resource function get restaurant/[int restaurantId]() returns RestaurantView|RestaurantNotFound|RestaurantInternalError {
        do {
            Restaurant restaurant = check getRestaurant(restaurantId);
            return <RestaurantView>{ 
                body: {
                    ...restaurant,
                    links: getRestaurantLinks(restaurant.id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <RestaurantNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        } 
    }

    isolated resource function get restaurant/[int restaurantId]/menu/[int menuId]() returns MenuView|MenuNotFound|RestaurantInternalError {
        do {
            Menu menu = check getMenu(menuId);
            return <MenuView>{ 
                body: {
                    ...menu,
                    links: getMenuLinks(menu.id, restaurantId)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        } 
    }

    isolated resource function get restaurant/[int restaurantId]/menu/[int menuId]/item/[int menuItemId]() returns MenuItemView|MenuItemNotFound|RestaurantInternalError {
        do {
            MenuItem menuItem = check getMenuItem(menuItemId);
            return <MenuItemView>{ 
                body: {
                    ...menuItem,
                    links: getMenuItemLinks(menuItem.id, menuId, restaurantId)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuItemNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        } 
    }

    isolated resource function delete restaurant/[int restaurantId]() returns RestaurantDeleted|RestaurantNotFound|RestaurantInternalError {
        do {
            Restaurant restaurant = check deleteRestaurant(restaurantId);
            return <RestaurantDeleted>{ body: restaurant};
        } on fail error e {
            if e is sql:NoRowsError {
                return <RestaurantNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }   
    }

    isolated resource function delete restaurant/[int restaurantId]/menu/[int menuId]() returns MenuDeleted|MenuNotFound|RestaurantInternalError {
        do {
            Menu menu = check deleteMenu(menuId);
            return <MenuDeleted>{ body: menu};
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }
    }

    isolated resource function delete restaurant/[int restaurantId]/menu/[int menuId]/menuItem/[int menuItemId]() returns MenuItemDeleted|MenuItemNotFound|RestaurantInternalError {
         do {
            MenuItem menuitem = check deleteMenuItem(menuItemId);
            return <MenuItemDeleted>{ body: menuitem};
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuItemNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }
    }

    isolated resource function put restaurant/[int restaurantId](@http:Payload UpdateRestaurantRequest request) returns RestaurantUpdated|RestaurantNotFound|RestaurantInternalError {
        do {
            Restaurant updatedRestaurant = check updateRestaurant(restaurantId, request.name, request.address);
            return <RestaurantUpdated>{ 
                body: { 
                    ...updatedRestaurant,
                    links: getRestaurantLinks(updatedRestaurant.id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <RestaurantNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }       
    }

    isolated resource function put restaurant/[int restaurantId]/menu/[int menuId](@http:Payload UpdateMenuRequest request) returns MenuUpdated|MenuNotFound|RestaurantInternalError {
        do {
            Menu updatedMenu = check updateMenu(menuId, request.name);
            return <MenuUpdated>{ 
                body: {
                    ...updatedMenu,
                    links: getMenuLinks(updatedMenu.id, restaurantId)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <RestaurantNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }  
    }

    isolated resource function put restaurant/[int restaurantId]/menu/[int menuId]/item/[int menuItemId](@http:Payload UpdateMenuItemRequest request) returns MenuItemUpdated|MenuItemNotFound|RestaurantInternalError {
        do {
            MenuItem updatedMenuItem = check updateMenuItem(menuItemId, request.name, request.price);
            return <MenuItemUpdated>{ 
                body: {
                    ...updatedMenuItem,
                    links: getMenuItemLinks(updatedMenuItem.id, menuId, restaurantId)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuItemNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }  
    }

}

isolated function getRestaurantLinks(int restaurantId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/restaurant/" + restaurantId.toString(),
            methods: [http:GET]
        },
        {
            rel: "update",
            href: "/restaurant/" + restaurantId.toString(),
            methods: [http:PUT]
        },
        {
            rel: "delete",
            href: "/restaurant/" + restaurantId.toString(),
            methods: [http:DELETE]
        }
    ];
}

isolated function getMenuLinks(int menuId, int parentRestaurantId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + menuId.toString(),
            methods: [http:GET]
        },
        {
            rel: "update",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + menuId.toString(),
            methods: [http:PUT]
        },
        {
            rel: "delete",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + menuId.toString(),
            methods: [http:DELETE]
        },
        {
            rel: "parent restaurant",
            href: "/restaurant/" + parentRestaurantId.toString(),
            methods: [http:GET]
        }
    ];
}

isolated function getMenuItemLinks(int menuItemId, int parentMenuId, int parentRestaurantId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + parentMenuId.toString() + "/item/" + menuItemId.toString(),
            methods: [http:GET]
        },
        {
            rel: "update",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + parentMenuId.toString() + "/item/" + menuItemId.toString(),
            methods: [http:PUT]
        },
        {
            rel: "delete",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + parentMenuId.toString() + "/item/" + menuItemId.toString(),
            methods: [http:DELETE]
        },
        {
            rel: "parent menu",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + parentMenuId.toString(),
            methods: [http:GET]
        },
        {
            rel: "parent restaurant",
            href: "/restaurant/" + parentRestaurantId.toString(),
            methods: [http:GET]
        }
    ];
}
