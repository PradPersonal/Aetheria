const mongoose = require('mongoose');
const { User } = require('../models/user.model');

const setupDatabase = async () => {
  try {
    const uri = process.env.MONGO_URI || 'mongodb://localhost:27017/streamingapp';
    console.log('Connecting to MongoDB...');

    await mongoose.connect(uri);

    // Ensure connection is fully open
    await mongoose.connection.asPromise();

    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const collections = await db.listCollections().toArray();
    const hasUsersCollection = collections.some(col => col.name === 'users');

    if (!hasUsersCollection) {
      console.log('Creating users collection...');
      await db.createCollection('users');
      console.log('Users collection created');
    } else {
      console.log('Users collection already exists');
    }

    await User.collection.createIndex({ email: 1 }, { unique: true });
    console.log('Email index created');

    console.log('Database setup completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('Database setup error:', error);
    process.exit(1);
  }
};

setupDatabase();