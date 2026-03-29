import 'package:flutter/material.dart';

enum SpendingCategory {
  groceries('Groceries', Icons.shopping_cart),
  dining('Dining', Icons.restaurant),
  travel('Travel', Icons.flight),
  gas('Gas', Icons.local_gas_station),
  online('Online Shopping', Icons.language),
  drugstores('Drugstores', Icons.local_pharmacy),
  streaming('Streaming', Icons.play_circle_fill),
  transit('Transit', Icons.directions_bus),
  office('Office Supply', Icons.work),
  phone('Phone Services', Icons.phone_android),
  general('General Purchases', Icons.credit_card),
  entertainment('Entertainment', Icons.theater_comedy),
  rent('Rent', Icons.home),
  costco('Costco', Icons.store),
  amazon('Amazon', Icons.add_shopping_cart),
  wholeFoods('Whole Foods', Icons.eco),
  target('Target', Icons.gps_fixed),
  walmart('Walmart', Icons.storefront),
  paypal('PayPal/Venmo', Icons.attach_money),
  airfare('Airfare', Icons.flight_takeoff),
  hotels('Hotels', Icons.hotel),
  restaurants('Restaurants', Icons.dinner_dining),
  fastFood('Fast Food', Icons.fastfood),
  coffee('Coffee Shops', Icons.coffee);

  const SpendingCategory(this.displayName, this.icon);

  final String displayName;
  final IconData icon;

  static List<SpendingCategory> get quickCategories => [
        groceries,
        dining,
        gas,
        travel,
        online,
        streaming,
        coffee,
        transit,
        entertainment,
        rent,
        general,
      ];

  List<SpendingCategory> get relatedCategories {
    switch (this) {
      case coffee:
        return [dining, restaurants];
      case fastFood:
        return [dining, restaurants];
      case restaurants:
        return [dining];
      case airfare:
        return [travel];
      case hotels:
        return [travel];
      case wholeFoods:
        return [groceries];
      case costco:
        return [groceries];
      case amazon:
        return [online];
      case target:
        return [general];
      case walmart:
        return [groceries, general];
      case transit:
        return [travel];
      case streaming:
        return [entertainment];
      default:
        return [];
    }
  }
}
