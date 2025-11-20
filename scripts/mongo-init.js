// MongoDB initialization script
db = db.getSiblingDB('streamingapp');

// Create the database and collections
db.createCollection('users');
db.createCollection('videos');

// Create indexes
db.users.createIndex({ "email": 1 }, { unique: true });
db.videos.createIndex({ "title": 1 });
db.videos.createIndex({ "genre": 1 });
db.videos.createIndex({ "uploadedBy": 1 });

// Create an admin user
db.users.insertOne({
  email: "admin@aetheria.com",
  password: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LrZIiPKNOKAY6FZUK", // password: admin123
  role: "admin",
  firstName: "Admin",
  lastName: "User",
  createdAt: new Date(),
  updatedAt: new Date()
});

// Create a test user
db.users.insertOne({
  email: "user@aetheria.com", 
  password: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LrZIiPKNOKAY6FZUK", // password: admin123
  role: "user",
  firstName: "Test",
  lastName: "User", 
  createdAt: new Date(),
  updatedAt: new Date()
});

print('MongoDB initialized successfully with test users');
print('Admin user: admin@aetheria.com / admin123');
print('Test user: user@aetheria.com / admin123');