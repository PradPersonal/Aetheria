const express = require('express');
const router = express.Router();
const {
  streamVideo,
  getVideosByGenre,
  getFeaturedVideos,
  getVideoDetails
} = require('../controllers/streaming.controller');

// Example base route
router.get('/', (req, res) => {
  res.json({ message: 'Streaming service API root' });
});

// Stream video
router.get('/stream', streamVideo);

// Get videos by genre
router.get('/videos', getVideosByGenre);

// Get featured videos
router.get('/videos/featured', getFeaturedVideos);

// Get video details
router.get('/videos/:videoId', getVideoDetails);

module.exports = router;