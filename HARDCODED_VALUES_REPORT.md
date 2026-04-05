# Hardcoded Numeric Values - Conversion Report
## ScreenUtil Migration (15% Reduction Factor Applied)

### Legend
- `.h` = height extension
- `.w` = width extension  
- `.sp` = font size extension
- `.r` = border radius extension
- Conversion factor: **Original value × 0.85**

---

## 1. home_screen.dart

| Line | Numeric Value | Context | Current Code | Recommended Conversion |
|------|---------------|---------|--------------|------------------------|
| 127 | `80` | FloatingActionButton padding (bottom) | `EdgeInsets.only(bottom: 80)` | `EdgeInsets.only(bottom: 68.h)` (80 × 0.85 = 68) |
| 154 | `24.0` | SingleChildScrollView horizontal padding | `EdgeInsets.symmetric(horizontal: 24.0,` | `EdgeInsets.symmetric(horizontal: 20.4.w,` (24.0 × 0.85 = 20.4) |
| 154 | `16.0` | SingleChildScrollView vertical padding | `vertical: 16.0)` | `vertical: 13.6.h)` (16.0 × 0.85 = 13.6) |

---

## 2. task_detail_screen.dart

| Line | Numeric Value | Context | Current Code | Recommended Conversion |
|------|---------------|---------|--------------|------------------------|
| 105 | `32` | AppBar leading icon size | `Icon(Icons.chevron_left, color: Colors.white, size: 32)` | `size: 27.2.sp` (32 × 0.85 = 27.2, round to 27.sp) |
| 144 | `12` | Tag container horizontal padding | `padding: EdgeInsets.symmetric(horizontal: 12,` | `padding: EdgeInsets.symmetric(horizontal: 10.2.w,` (12 × 0.85 = 10.2) |
| 144 | `6` | Tag container vertical padding | `vertical: 6)` | `vertical: 5.1.h)` (6 × 0.85 = 5.1) |
| 238 | `8.0` | Attachment item container margin (bottom) | `margin: EdgeInsets.only(bottom: 8.0)` | `margin: EdgeInsets.only(bottom: 6.8.h)` (8.0 × 0.85 = 6.8) |
| 240 | `12` | Attachment item horizontal padding | `padding: EdgeInsets.symmetric(horizontal: 12,` | `padding: EdgeInsets.symmetric(horizontal: 10.2.w,` (12 × 0.85 = 10.2) |
| 240 | `12` | Attachment item vertical padding | `vertical: 12,)` | `vertical: 10.2.h,)` (12 × 0.85 = 10.2) |
| 260 | `16` | Share to AI button vertical padding | `padding: EdgeInsets.symmetric(vertical: 16)` | `padding: EdgeInsets.symmetric(vertical: 13.6.h)` (16 × 0.85 = 13.6) |

---

## 3. history_screen.dart

| Line | Numeric Value | Context | Current Code | Recommended Conversion |
|------|---------------|---------|--------------|------------------------|
| 90 | `20` | Tabs horizontal padding | `padding: EdgeInsets.symmetric(horizontal: 20)` | `padding: EdgeInsets.symmetric(horizontal: 17.w)` (20 × 0.85 = 17) |
| 137 | `20` | Stats row horizontal padding | `padding: EdgeInsets.symmetric(horizontal: 20)` | `padding: EdgeInsets.symmetric(horizontal: 17.w)` (20 × 0.85 = 17) |
| 159 | `20` | Archive list horizontal padding | `padding: EdgeInsets.symmetric(horizontal: 20)` | `padding: EdgeInsets.symmetric(horizontal: 17.w)` (20 × 0.85 = 17) |
| 192 | `14` | Archive date text fontSize | `style: TextStyle(color: Colors.grey, fontSize: 14)` | `style: TextStyle(color: Colors.grey, fontSize: 11.9.sp)` (14 × 0.85 = 11.9, round to 12.sp) |
| 281 | `10` | Status badge horizontal padding | `padding: EdgeInsets.symmetric(horizontal: 10,` | `padding: EdgeInsets.symmetric(horizontal: 8.5.w,` (10 × 0.85 = 8.5) |
| 281 | `6` | Status badge vertical padding | `vertical: 6)` | `vertical: 5.1.h)` (6 × 0.85 = 5.1) |

---

## 4. task_widgets.dart

| Line | Numeric Value | Context | Current Code | Recommended Conversion |
|------|---------------|---------|--------------|------------------------|
| 20 | `16.0` | TodaysFocusCard bottom margin | `margin: EdgeInsets.only(bottom: 16.0)` | `margin: EdgeInsets.only(bottom: 13.6.h)` (16.0 × 0.85 = 13.6) |
| 31 | `10` | Task type tag horizontal padding | `padding: EdgeInsets.symmetric(horizontal: 10,` | `padding: EdgeInsets.symmetric(horizontal: 8.5.w,` (10 × 0.85 = 8.5) |
| 31 | `4` | Task type tag vertical padding | `vertical: 4)` | `vertical: 3.4.h)` (4 × 0.85 = 3.4) |
| 108 | `16.0` | UpcomingTaskTile vertical padding | `padding: EdgeInsets.symmetric(vertical: 16.0)` | `padding: EdgeInsets.symmetric(vertical: 13.6.h)` (16.0 × 0.85 = 13.6) |

---

## Summary Statistics

- **Total Hardcoded Values Found:** 18
- **Files Affected:** 4
  - home_screen.dart: 3 values
  - task_detail_screen.dart: 7 values
  - history_screen.dart: 6 values
  - task_widgets.dart: 4 values

- **Value Categories:**
  - Padding/Margin: 16 values
  - Font Size: 1 value
  - Icon Size: 1 value

---

## Batch Replacement Strategy

### Priority: HIGH
Apply these conversions in this order to avoid conflicts:
1. **task_detail_screen.dart** - 7 values (most complex file)
2. **history_screen.dart** - 6 values
3. **task_widgets.dart** - 4 values
4. **home_screen.dart** - 3 values (simplest changes)
