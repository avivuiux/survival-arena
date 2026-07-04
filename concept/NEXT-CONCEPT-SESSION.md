# Next session - continuation prompt (CONCEPT / art lane)

Paste this to start warm:

---

בוא נמשיך את Survival Arena / OVERTHRONE (מסלול-הקונספט/אמנות). קרא קודם `ROSTER.md` +
`concept/STYLE-GUIDE.md` (§chibi-plus look + §3D pipeline) + `concept/CHARACTER-METHOD.md` +
`CONCEPT.md`. הרפו = מקור-האמת.

**איפה עצרנו (2026-07-03, "ארוז", נדחף HEAD=d661a9b):** הרוסטר הבסיסי הושלם בתלת.
- **לוק נעול = "צ'יבי-פלוס טוי-תלת"** (~3.5 ראשים, ברק-צעצוע, זירה ציורית). עוגנים:
  FANG=`concept/rework/fang_styledial_A_attack.jpg`, ZERO=`concept/rework/zero_chibiplus_cold_2.jpg`,
  ATLAS=`concept/rework/atlas_noble_1.jpg`.
- **שלוש דמויות game-ready (צ'יבי / on-style / רוגדות / קלות):**
  - FANG (rusher) = `concept/characters/fang/FANG_chibi_3d_v1.glb` (רוגד, ~1.4MB, אושר-חי בזירה).
  - ZERO (balanced) = `concept/characters/zero/ZERO_chibi_3d_v2_rigged.glb` (רוגד, ~1MB, א-סימטריה שלמה).
  - ATLAS (tank) = `concept/characters/atlas/ATLAS_chibi_3d_v1_rigged.glb` (רוגד, ~1.15MB, מלך-ירקן).
- **צינור-המודלים המנצח (STYLE-GUIDE §3D):** Magnific = look-probes; **Tripo API הישיר** =
  game-ready (`image_to_model` face_limit ~18000 → `animate_prerigcheck` → `animate_rig`).
  מפתח Tripo ב-`.env.local` (gitignored; אביב אמר להחליף אחרי).
  כלל: סימטרי→tripo; א-סימטרי→רמזים-בולטים-בצ'יבי מחזיקים גם ב-tripo (אודיט-12-זוויות תמיד).
- **כלי-אודיט זרוק (concept-owned, שמור):** `concept/_tmp_asym_check.gd/.tscn` (רנדר 12 זוויות),
  `concept/_tmp_arena_view.gd/.tscn` (מודל על רצפת-זירה + מצלמת-משחק, חלון-חי).

**הכדור אצל המכניקה:** להטמיע את שלוש הדמויות ב-`game3d` (tank slot = ATLAS, כרגע קפסולות) →
להוכיח משחק-רוסטר-מלא בפועל. זה השער הבא, והוא בליין שלהם.

**שער נעול - אנימציה נדחית:** אנימציית-שלד = ליטוש-אחרון, לא הצעד-הבא. רק אחרי שהמשחק
רוסטר-מלא ומוכח-בפועל. Tripo כן יודע ליישם אנימציות-מוכנות על מודל-רוגד (`animate_retarget`),
מה שמוזיל את זה מאוד - אבל עדיין מחכה לפסק-דין רוסטר-מלא. אל תקפוץ לשם בלי אישור.

**מועמדים לליין-קונספט (לתעדף אחד, לא לפני שהמכניקה מטמיעה):** נכסי-בחירה/פורטרטים בסגנון
הנעול · דמות #4 (deep-dive זהות חדש) · ליטוש-פוזות/מצבי-פעולה למודלים · או להמתין למכניקה.

**שיטה:** show-before-spend, פתח בביקורת, המלצה-אחת לא תפריט, SPEC לפני מימוש, אל תשנה-כיוון
בלי אישור, כל צ'אט מקמט רק את קבציו (concept/ + assets; לא `scripts/`/game3d). "ארוז" =
עדכון state+זיכרון + פרומפט-המשך + git push.
