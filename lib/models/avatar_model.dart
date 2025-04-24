import 'package:flutter/material.dart';

class AvatarCategory {
  final String name;
  final List<PredefinedAvatar> avatars;

  AvatarCategory({
    required this.name,
    required this.avatars,
  });
}

class PredefinedAvatar {
  final String id;
  final String url;
  final String name;
  final String category;

  PredefinedAvatar({
    required this.id,
    required this.url,
    required this.name,
    required this.category,
  });
}

// Predefined avatar categories and images
class AvatarData {
  static List<AvatarCategory> categories = [
    AvatarCategory(
      name: 'Superheroes',
      avatars: [
        PredefinedAvatar(
          id: 'superhero_1',
          url: 'https://i.imgur.com/Oc3UZdE.jpg',
          name: 'Iron Man',
          category: 'Superheroes',
        ),
        PredefinedAvatar(
          id: 'superhero_2',
          url: 'https://i.imgur.com/aSbkB6F.jpg',
          name: 'Batman',
          category: 'Superheroes',
        ),
        PredefinedAvatar(
          id: 'superhero_3',
          url: 'https://i.imgur.com/1iNoMRz.jpg',
          name: 'Spider-Man',
          category: 'Superheroes',
        ),
        PredefinedAvatar(
          id: 'superhero_4',
          url: 'https://i.imgur.com/Wd11PV4.jpg',
          name: 'Captain America',
          category: 'Superheroes',
        ),
      ],
    ),
    AvatarCategory(
      name: 'Sports',
      avatars: [
        PredefinedAvatar(
          id: 'sports_1',
          url: 'https://i.imgur.com/JVrZUXB.jpg',
          name: 'Messi',
          category: 'Sports',
        ),
        PredefinedAvatar(
          id: 'sports_2',
          url: 'https://i.imgur.com/aCkuSHO.jpg',
          name: 'Ronaldo',
          category: 'Sports',
        ),
        PredefinedAvatar(
          id: 'sports_3',
          url: 'https://i.imgur.com/Yd7K9sm.jpg',
          name: 'LeBron James',
          category: 'Sports',
        ),
        PredefinedAvatar(
          id: 'sports_4',
          url: 'https://i.imgur.com/Ij8Vc4N.jpg',
          name: 'Stephen Curry',
          category: 'Sports',
        ),
      ],
    ),
    AvatarCategory(
      name: 'Movies',
      avatars: [
        PredefinedAvatar(
          id: 'movie_1',
          url: 'https://i.imgur.com/1iNoMRz.jpg',
          name: 'Darth Vader',
          category: 'Movies',
        ),
        PredefinedAvatar(
          id: 'movie_2',
          url: 'https://i.imgur.com/aSbkB6F.jpg',
          name: 'Harry Potter',
          category: 'Movies',
        ),
        PredefinedAvatar(
          id: 'movie_3',
          url: 'https://i.imgur.com/Oc3UZdE.jpg',
          name: 'James Bond',
          category: 'Movies',
        ),
        PredefinedAvatar(
          id: 'movie_4',
          url: 'https://i.imgur.com/Wd11PV4.jpg',
          name: 'Jack Sparrow',
          category: 'Movies',
        ),
      ],
    ),
    AvatarCategory(
      name: 'Animals',
      avatars: [
        PredefinedAvatar(
          id: 'animal_1',
          url: 'https://i.imgur.com/JVrZUXB.jpg',
          name: 'Lion',
          category: 'Animals',
        ),
        PredefinedAvatar(
          id: 'animal_2',
          url: 'https://i.imgur.com/aCkuSHO.jpg',
          name: 'Tiger',
          category: 'Animals',
        ),
        PredefinedAvatar(
          id: 'animal_3',
          url: 'https://i.imgur.com/Yd7K9sm.jpg',
          name: 'Wolf',
          category: 'Animals',
        ),
        PredefinedAvatar(
          id: 'animal_4',
          url: 'https://i.imgur.com/Ij8Vc4N.jpg',
          name: 'Eagle',
          category: 'Animals',
        ),
      ],
    ),
  ];

  // Get all avatars as a flat list
  static List<PredefinedAvatar> get allAvatars {
    List<PredefinedAvatar> all = [];
    for (var category in categories) {
      all.addAll(category.avatars);
    }
    return all;
  }

  // Find avatar by ID
  static PredefinedAvatar? findAvatarById(String id) {
    for (var avatar in allAvatars) {
      if (avatar.id == id) {
        return avatar;
      }
    }
    return null;
  }
}
