import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Notice model stays the same
class Notice {
  final String id;
  final String title;
  final String author;
  final DateTime date;
  final String details;
  final List<String> tags;
  final IconData icon;

  Notice({
    required this.id,
    required this.title,
    required this.author,
    required this.date,
    required this.details,
    required this.tags,
    required this.icon,
  });

  factory Notice.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Notice(
      id: doc.id,
      title: data['title'] as String,
      author: data['author'] as String,
      date: (data['date'] as Timestamp).toDate(),
      details: data['details'] as String,
      tags: List<String>.from(data['tags'] as List),
      icon: Icons.campaign, // or map a field -> icon
    );
  }
}

