const jwt = require('jsonwebtoken');

function requireLogin(req, res, next) {
  const token = req.cookies.token;
  if (!token) {
    res.cookie('error', 'Bạn cần đăng nhập');
    return res.redirect('/auth/login');
  }
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (err) {
    res.clearCookie('token');
    res.cookie('error', 'Phiên đăng nhập hết hạn, vui lòng đăng nhập lại');
    return res.redirect('/auth/login');
  }
}

module.exports = requireLogin; 