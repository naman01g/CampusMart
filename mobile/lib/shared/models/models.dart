import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingType { sell, exchange, free }

enum ListingStatus { active, reserved, sold, removed }

enum UserRole { student, admin }

enum ReportStatus { pending, reviewed, resolved, dismissed }

enum ReportTargetType { product, user }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profileImage;
  final String collegeId;
  final String course;
  final String branch;
  final int year;
  final bool isVerified;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> fcmTokens;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImage,
    required this.collegeId,
    required this.course,
    required this.branch,
    required this.year,
    required this.isVerified,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.fcmTokens = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profileImage: data['profileImage'],
      collegeId: data['collegeId'] ?? '',
      course: data['course'] ?? '',
      branch: data['branch'] ?? '',
      year: data['year'] ?? 1,
      isVerified: data['isVerified'] ?? false,
      role: UserRole.values.byName(data['role'] ?? 'student'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'collegeId': collegeId,
      'course': course,
      'branch': branch,
      'year': year,
      'isVerified': isVerified,
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'fcmTokens': fcmTokens,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? profileImage,
    String? collegeId,
    String? course,
    String? branch,
    int? year,
    bool? isVerified,
    UserRole? role,
    List<String>? fcmTokens,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      collegeId: collegeId ?? this.collegeId,
      course: course ?? this.course,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }
}

class ProductModel {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final ListingType listingType;
  final String category;
  final double price;
  final double? originalPrice;
  final bool isNegotiable;
  final String condition;
  final List<String> images;
  final String location;
  final ListingStatus status;
  final int views;
  final int favoritesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.listingType,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.isNegotiable,
    required this.condition,
    required this.images,
    required this.location,
    required this.status,
    required this.views,
    required this.favoritesCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      listingType: ListingType.values.byName(
        data['listingType']?.toLowerCase() ?? 'sell',
      ),
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      originalPrice: (data['originalPrice'] as num?)?.toDouble(),
      isNegotiable: data['isNegotiable'] ?? false,
      condition: data['condition'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      location: data['location'] ?? '',
      status: ListingStatus.values.byName(
        data['status']?.toLowerCase() ?? 'active',
      ),
      views: data['views'] ?? 0,
      favoritesCount: data['favoritesCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'listingType': listingType.name.toUpperCase(),
      'category': category,
      'price': price,
      'originalPrice': originalPrice,
      'isNegotiable': isNegotiable,
      'condition': condition,
      'images': images,
      'location': location,
      'status': status.name.toUpperCase(),
      'views': views,
      'favoritesCount': favoritesCount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get formattedTimeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }
}

class ChatModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final String? productTitle;
  final String? productImage;
  final String lastMessage;
  final DateTime lastMessageAt;
  final DateTime? createdAt;

  ChatModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    this.productTitle,
    this.productImage,
    required this.lastMessage,
    required this.lastMessageAt,
    this.createdAt,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      productId: data['productId'] ?? '',
      productTitle: data['productTitle'],
      productImage: data['productImage'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt:
          (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}

class FavoriteModel {
  final String id;
  final String userId;
  final String productId;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
  });

  factory FavoriteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoriteModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ReportModel {
  final String id;
  final String reportedBy;
  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.reportedBy,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reportedBy: data['reportedBy'] ?? '',
      targetType: ReportTargetType.values.byName(
        data['targetType'] ?? 'product',
      ),
      targetId: data['targetId'] ?? '',
      reason: data['reason'] ?? '',
      description: data['description'],
      status: ReportStatus.values.byName(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class NotificationModel {
  final String id;
  final String recipientId;
  final String senderId;
  final String type;
  final String chatId;
  final String productId;
  final String productTitle;
  final String senderName;
  final String recipientRole;
  final String messagePreview;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.type,
    required this.chatId,
    required this.productId,
    required this.productTitle,
    required this.senderName,
    required this.recipientRole,
    required this.messagePreview,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
      type: data['type'] ?? '',
      chatId: data['chatId'] ?? '',
      productId: data['productId'] ?? '',
      productTitle: data['productTitle'] ?? '',
      senderName: data['senderName'] ?? '',
      recipientRole: data['recipientRole'] ?? '',
      messagePreview: data['messagePreview'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'type': type,
      'chatId': chatId,
      'productId': productId,
      'productTitle': productTitle,
      'senderName': senderName,
      'recipientRole': recipientRole,
      'messagePreview': messagePreview,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}

class ReviewModel {
  final String id;
  final String reviewerId;
  final String revieweeId;
  final String productId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.productId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      reviewerId: data['reviewerId'] ?? '',
      revieweeId: data['revieweeId'] ?? '',
      productId: data['productId'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

const List<String> categories = [
  'Books',
  'Electronics',
  'Accessories',
  'Furniture',
  'Clothing',
  'Bags',
  'Sports',
  'Study Equipment',
  'Chargers & Cables',
  'Cycles',
  'Gaming',
  'Hostel Items',
  'Other',
];

const List<String> conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];
