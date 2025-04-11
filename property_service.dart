import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyService {
  // Method to get a single property with its image
  Future<Map<String, dynamic>> getPropertyWithImage(String propertyId) async {
    try {
      // Get the main property document
      final propertyDoc = await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .get();

      // Get the image document
      final imageDoc = await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .collection('images')
          .doc('propertyImage')
          .get();

      if (propertyDoc.exists && imageDoc.exists) {
        final propertyData = propertyDoc.data()!;
        final imageData = imageDoc.data()!;
        
        // Combine the data
        return {
          ...propertyData,
          'imageBase64': imageData['imageBase64'],
        };
      }
      
      throw Exception('Property or image not found');
    } catch (e) {
      throw Exception('Error fetching property: $e');
    }
  }

  // Method to get all properties with their images
  Future<List<Map<String, dynamic>>> getAllProperties() async {
    try {
      final QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .where('approvalStatus', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> properties = [];

      for (var doc in propertySnapshot.docs) {
        final propertyId = doc.id;
        final propertyData = await getPropertyWithImage(propertyId);
        properties.add(propertyData);
      }

      return properties;
    } catch (e) {
      throw Exception('Error fetching properties: $e');
    }
  }
} 