import 'dart:ui';

// =======================================================
// 🎨 PRIMARY THEME (Blue Grey Base)
// =======================================================

const Color kPrimary = Color(0xFF455A64);       // Main brand
const Color kPrimaryDark = Color(0xFF263238);   // AppBar / headers
const Color kPrimaryLight = Color(0xFF607D8B);  // Secondary elements

// =======================================================
// 🌈 ACCENTS (For Actions)
// =======================================================

const Color kAccent = Color(0xFF6E7AC2);        // Buttons (Download / Share)
const Color kLike = Color(0xFFFF5252);          // Like / Favorite ❤️

// =======================================================
// 🧱 BACKGROUNDS
// =======================================================

const Color kScaffoldBg = Color(0xFFF5F7F8);    // Main background
const Color kCardBg = Color(0xFFFFFFFF);        // Cards / containers
const Color kSubtleBg = Color(0xFFECEFF1);      // Inputs / light sections
const Color kDivider = Color(0xFFCFD8DC);

// =======================================================
// ✍️ TEXT COLORS
// =======================================================

const Color kTextPrimary = Color(0xFF101214);
const Color kTextSecondary = Color(0xFF607D8B);
const Color kWhite = Color(0xFFFFFFFF);

// =======================================================
// 📂 CATEGORY COLORS (For Image Categories)
// =======================================================

const Color kNature = Color(0xFF4CAF50);     // Green
const Color kCars = Color(0xFF2196F3);       // Blue
const Color kAnimals = Color(0xFFFF9800);    // Orange
const Color kTechnology = Color(0xFF9C27B0); // Purple
const Color kAbstract = Color(0xFFE91E63);   // Pink

// Optional Map (easy to use dynamically)
const Map<String, Color> kCategoryColors = {
  "Nature": kNature,
  "Cars": kCars,
  "Animals": kAnimals,
  "Technology": kTechnology,
  "Abstract": kAbstract,
};

// =======================================================
// 📏 PADDING
// =======================================================

const double kPaddingS = 6.0;
const double kPaddingS2 = 2.0;
const double kPaddingM = 18.0;
const double kPaddingL = 24.0;
const double kPaddingT = 20.0;


// =======================================================
// 📐 SPACING
// =======================================================

const double kSpaceXS = 4.0;
const double kSpaceS = 8.0;
const double kSpaceM = 16.0;
const double kSpaceL = 24.0;