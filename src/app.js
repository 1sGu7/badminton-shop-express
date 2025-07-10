require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
const cookieParser = require('cookie-parser');
const routes = require('./routes');
const jwt = require('jsonwebtoken');

const app = express();

// Kết nối MongoDB
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => console.log('MongoDB connected')).catch(err => console.error('MongoDB error:', err));

// Middleware
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(cookieParser());

// Flash message custom middleware (không dùng session)
app.use((req, res, next) => {
  res.locals.success = req.cookies.success || '';
  res.locals.error = req.cookies.error || '';
  res.clearCookie('success');
  res.clearCookie('error');
  next();
});

// Middleware decode JWT từ cookie, gán userId vào res.locals.userId cho mọi request.
app.use((req, res, next) => {
  const token = req.cookies.token;
  if (token) {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      res.locals.userId = decoded.userId;
    } catch (err) {
      res.locals.userId = null;
    }
  } else {
    res.locals.userId = null;
  }
  next();
});

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// EJS
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Routes
app.use(routes);

// Health check endpoint for Docker
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).render('404', { title: '404' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
}); 