const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkey123';

// Mock Database
const users = []; // { id, username, email, passwordHash, highScore, coins, unlockedSkins }

// Middleware: Authenticate Token
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Access token required' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: 'Invalid or expired token' });
    req.user = user;
    next();
  });
}

// Auth Routes
app.post('/api/auth/register', async (req, res) => {
  const { username, email, password } = req.body;
  if (!username || !email || !password) {
    return res.status(400).json({ message: 'All fields are required' });
  }

  const existing = users.find(u => u.email === email || u.username === username);
  if (existing) {
    return res.status(400).json({ message: 'Username or email already exists' });
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const newUser = {
    id: users.length + 1,
    username,
    email,
    passwordHash,
    highScore: 0,
    coins: 0,
    unlockedSkins: ['blue']
  };

  users.push(newUser);
  const token = jwt.sign({ id: newUser.id, username: newUser.username }, JWT_SECRET, { expiresIn: '7d' });

  res.status(201).json({
    message: 'User registered successfully',
    token,
    user: { id: newUser.id, username: newUser.username, email: newUser.email, highScore: newUser.highScore, coins: newUser.coins }
  });
});

app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;
  const user = users.find(u => u.username === username || u.email === username);
  if (!user) return res.status(400).json({ message: 'Invalid credentials' });

  const validPassword = await bcrypt.compare(password, user.passwordHash);
  if (!validPassword) return res.status(400).json({ message: 'Invalid credentials' });

  const token = jwt.sign({ id: user.id, username: user.username }, JWT_SECRET, { expiresIn: '7d' });

  res.json({
    message: 'Login successful',
    token,
    user: { id: user.id, username: user.username, email: user.email, highScore: user.highScore, coins: user.coins }
  });
});

// Game Routes
app.post('/api/game/score', authenticateToken, (req, res) => {
  const { score, coins } = req.body;
  const user = users.find(u => u.id === req.user.id);
  if (!user) return res.status(404).json({ message: 'User not found' });

  if (score > user.highScore) {
    user.highScore = score;
  }
  user.coins += (coins || 0);

  res.json({
    message: 'Score updated',
    highScore: user.highScore,
    coins: user.coins
  });
});

app.get('/api/game/leaderboard', (req, res) => {
  const leaderboard = users
    .map(u => ({ username: u.username, highScore: u.highScore }))
    .sort((a, b) => b.highScore - a.highScore)
    .slice(0, 10);
  res.json(leaderboard);
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
