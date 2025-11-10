import 'package:flutter/material.dart';

final List<Map<String, dynamic>> services = [
  {
    "icon": Icons.credit_card_rounded,
    "name": "My Cards",
    "gradient": [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    "lightColor": Color(0xFFEEF2FF),
  },
  {
    "icon": Icons.trending_up_rounded,
    "name": "Analytics",
    "gradient": [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    "lightColor": Color(0xFFFAF5FF),
  },
  {
    "icon": Icons.category_outlined,
    "name": "Category",
    "gradient": [Color(0xFFEC4899), Color(0xFFF43F5E)],
    "lightColor": Color(0xFFFDF2F8),
  },
  {
    "icon": Icons.pie_chart_rounded,
    "name": "Budget",
    "gradient": [Color(0xFF14B8A6), Color(0xFF10B981)],
    "lightColor": Color(0xFFF0FDFA),
  },
];

final List<String> category = ["All", "Shopping", "Food", "Transport", "Bills"];

final List<Map<String, dynamic>> transactions = [
  {
    "title": "Shopping Mall",
    "subtitle": "Fashion & Accessories",
    "amount": -1250,
    "date": "Yesterday",
    "time": "07:30 PM",
    "icon": Icons.shopping_bag_rounded,
    "gradient": [Color(0xFFEC4899), Color(0xFFF43F5E)],
  },
  {
    "title": "Grocery Store",
    "subtitle": "Fresh Vegetables & Fruits",
    "amount": -850,
    "date": "Today",
    "time": "02:15 PM",
    "icon": Icons.local_grocery_store_rounded,
    "gradient": [Color(0xFF10B981), Color(0xFF14B8A6)],
  },
  {
    "title": "Restaurant",
    "subtitle": "Family Dinner",
    "amount": -2100,
    "date": "Today",
    "time": "09:00 PM",
    "icon": Icons.restaurant_rounded,
    "gradient": [Color(0xFFF59E0B), Color(0xFFF97316)],
  },
];
