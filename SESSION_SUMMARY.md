# ملخص الجلسة: تطوير `all_player` وطبقات الكاش

> تاريخ الجلسة: 2026-11-17 — المشروع: `C:\Users\Lenovo\StudioProjects\packages\all_player`
> الحزم المرتبطة: `m_cubit`، `m_cache`، `video_partial_cache` (كلها داخل `packages\`).

---

## 1. ما هي المكتبة (قبل التعديلات)

`all_player` حزمة Flutter (الإصدار 1.0.0) توفّر **مشغّل فيديو موحّد** بإدارة حالة **Cubit** (`flutter_bloc` + `m_cubit`).

**المصادر المدعومة** (عبر `PlayVideoFrom`):

| المصدر | طريقة التشغيل |
|---|---|
| `network` | رابط مباشر (mp4 / m3u8) |
| `networkQualityUrls` | قائمة روابط بجودات تحددها أنت |
| `asset` / `file` | فيديو من assets أو ملف محلي (الملف لا يعمل على الويب) |
| `youtube` / `youtubePlayer` | استخراج الروابط عبر `youtube_explode_dart` وتشغيل بـ `video_player` |
| `youtubeIframe` | مشغّل YouTube الرسمي عبر WebView |
| `vimeo` / `vimeoPrivateVideos` | جلب روابط الجودات من Vimeo (الخاص عبر headers) |
| `dailymotion` | عبر token أو عبر روابط m3u8 |
| `PlayVideoFrom.auto(...)` | يكتشف المنصة من الرابط أو الـ ID |

**الملفات الرئيسية:**

- `AllPlayerController` (يمتد من `Cubit<AllPlayerState>`): التشغيل، الجودة، السرعة، الصوت، الإيماءات (نقر مزدوج)، الـ overlay، ملء الشاشة، اختصارات لوحة المفاتيح على الويب، wakelock، `changeVideo`.
- `AllPlayer` (widget): يعرض المشغّل، thumbnail، مؤشر تحميل، widget خطأ، `overlayBuilder` للتخصيص.
- `widgets/`: overlay للموبايل (bottom sheet) وللويب (dropdown)، `AllProgressBar`، أيقونات متحركة.
- `models/`: `AllPlayerConfig`، `AllPlayerLabels`، `OverLayOptions`، نماذج Vimeo.
- `utils/video_apis.dart`: جلب روابط الجودات من YouTube وVimeo وDailymotion.

**ملاحظات لوحظت في البداية:** README فارغ؛ الكاش مستعمل فقط لحفظ thumbnail Dailymotion ولا يقرؤه أحد؛ تكرار حقول (`videoState`/`playerStatus`)؛ `forcedVideoFocus` غير مستعمل؛ `_videoListener` يعمل `emit` على كل tick للموضع؛ `changeVideoQuality` كان يُسقط `httpHeaders` و`formatHint`؛ في Vimeo العام كان رابط HLS نفسه يُكرَّر لكل جودة.

---

## 2. الطلبات والقرارات

1. **قراءة المكتبة وشرحها.**
2. **تبسيط الكود والتضمين + دراسة ما يمكن تخزينه بالكاش بالـ videoId.**
   - قرار المستخدم: البدء بـ **كاش البيانات الوصفية** عبر `m_cubit`، ومع **كسر التوافق → الإصدار 2.0.0**.
3. **إضافة `video_partial_cache`** (كاش بايتات الفيديو) للمصادر الداعمة.
4. **التحقق من أن Vimeo = m3u8، ودعم m3u8 في `video_partial_cache`.**
   - قرار المستخدم: تنفيذ الثلاث (إصلاح Vimeo progressive، `HlsHandler`، تفعيله في `all_player`).
5. أسئلة توضيحية: طريقة الاستخدام الجديدة، معنى "الروابط الموقّعة"، وما هي مفاتيح التخزين لكل نوع.

---

## 3. التعديلات في `all_player`

### 3.1 كاش البيانات الوصفية (m_cubit)

**ملف جديد:** `lib/src/cache/all_player_cache.dart` — `AllPlayerCache` فوق `CachingService` (Hive)، bucket اسمه `all_player_cache`. كل العمليات داخل `try/catch` (إذا لم تُهيَّأ Hive يتصرف كأنه فارغ ولا يكسر التشغيل)، والكتابة مرتّبة عبر طابور لمنع التضارب.

| المخزَّن | التفاصيل |
|---|---|
| **روابط الجودات** | تُستعمل حتى انتهاء صلاحيتها: من `expire`/`exp` في الرابط ناقص 10 دقائق، وإلا 30 دقيقة |
| **thumbnail** | رابط الصورة يظهر خلف مؤشر التحميل عبر `state.thumbnailUrl`. YouTube يُشتق من الـ id (`img.youtube.com/vi/<id>/hqdefault.jpg`)، وVimeo وDailymotion يُحفظ رابطهما. **يُخزَّن الرابط فقط وليس بايتات الصورة** |
| **موضع المتابعة** | يُحفظ كل 5 ثوانٍ وعند الإيقاف والإغلاق؛ يُصفَّر إذا بقي أقل من 5 ثوانٍ للنهاية |
| **تفضيلات المستخدم** (`AllPlayerPrefs`) | آخر جودة وسرعة وصوت، مفتاح واحد `__prefs` |

**إعدادات جديدة في `AllPlayerConfig`:**

| الإعداد | الافتراضي | المعنى |
|---|---|---|
| `cacheEnabled` | `true` | تفعيل كاش البيانات الوصفية |
| `cacheVideo` | `true` | استعمال كاش البايتات (يعمل فقط بعد `AllPlayerVideoCache.init()`) |
| `resumePlayback` | `false` | المتابعة من آخر موضع (opt-in لأنه سلوك قد يفاجئ المستخدم) |
| `rememberPreferences` | `true` | تذكّر الجودة والسرعة والصوت |

**في `PlayVideoFrom`:** حقل `cacheId` (في `network` و`networkQualityUrls` و`auto`)، وخاصية `cacheKey`.

**في `VideoApis`:** معاملات `onThumbnail` (Vimeo وDailymotion)، و`vimeoThumbnail` يقرأ `video.thumbs`.

**في الـ controller:** `_cachedStreams` (يستعمل الروابط المخزّنة أو يجلبها)، `_loadCachedExtras`، `_restoreFromCache`، `_savePosition` (throttled)، `_savePrefs`، وأضفتُ `thumbnailUrl` إلى `AllPlayerState`، و`AllPlayer` يعرضه خلف الـ loader.

### 3.2 كاش بايتات الفيديو (`video_partial_cache`)

**ملف جديد:** `lib/src/cache/all_player_video_cache.dart` — `AllPlayerVideoCache`:

- `init({maxCacheSizeBytes, chunkSizeBytes, evictionStrategy, upstreamHeaders})` — يُستدعى مرة واحدة؛ بدونه تعمل المكتبة كالسابق. لا يعمل على الويب.
- `instance` للوصول لكل واجهة الحزمة (`getStats`، `setPinned`، `clearVideo`، ...).
- `playableUrl(url, {videoId})` و`isHls(url)` و`dispose()`.

**في الـ controller:**
- `_createNetworkController(url, {quality, useCache})` دالة موحّدة تُنشئ الـ controller (ومررت `httpHeaders` و`formatHint` والترجمة أيضاً في `changeVideoQuality`، وكان هذا خللاً).
- `_initializeWithFallback`: إذا فشل البروكسي المحلي (مثلاً cleartext محجوب) يعيد المحاولة بالرابط المباشر تلقائياً.
- `_canCacheBytes`: يشترط `cacheVideo` و`AllPlayerVideoCache.isEnabled` وأن `httpHeaders` فارغ (لا يمكن تمريرها للخادم الأصلي عبر البروكسي)، وأن المصدر `network` أو `networkQualityUrls` أو `youtube` أو `vimeo` أو `dailymotion`.

**التبعيات:** أُضيفت `video_partial_cache: path: ../video_partial_cache`، ورُفع حد SDK إلى `^3.12.2` (تطلبه الحزمة).

### 3.3 إصلاح Vimeo

`parseVimeoStreams` الآن:
1. يقرأ `files.progressive` أولاً (mp4 بجودات حقيقية، قابل للكاش بالـ byte-range).
2. وإلا يعرض رابط HLS **كعنصر واحد** (الجودة = أفضل جودة dash، لا تقل عن 360) بدل تكرار نفس الرابط لكل جودة.

> **التحقق:** طلبتُ `player.vimeo.com/video/76979871/config` فعلياً: `progressive` فارغ، وفيه `hls` و`dash`. أي أن Vimeo العام غالباً HLS، لكنه يقدم mp4 أحياناً (progressive أو الـ API الخاص). وسُجّل أن الفيديو الذي جربتُه كان محمياً بـ FairPlay (`skd://drm`).

### 3.4 التنظيف وكسر التوافق (2.0.0)

حُذف: `AllVideoPlayer` و`AllVideoState` و`AllVideoPlayerType` (typedefs)، و`videoState` (في الـ state والـ controller)، و`AllPlayerConfig.forcedVideoFocus`، وثابت `videoThumpBuketName`. واستُبدل `AllVideoPlayerType.` بـ `AllPlayerType.` في `play_video_from.dart`. حُدّث الاختبار المرتبط. رُفع الإصدار في `pubspec.yaml` وأُضيف سجل في `CHANGELOG.md`. وأُعيد تصدير `CacheStats` و`EvictionStrategy` و`VideoPartialCache` من `all_player.dart`.

---

## 4. التعديلات في `video_partial_cache` (دعم HLS)

| الملف | الوظيفة |
|---|---|
| `lib/src/proxy/hls_playlist.dart` (جديد) | دالة نقية `rewriteHlsPlaylist`: تعيد كتابة كل الروابط (variants، `EXT-X-MEDIA`، `EXT-X-MAP`، segments) لتمر عبر البروكسي وتعطي كل مورد **مفتاحاً ثابتاً** |
| `lib/src/proxy/hls_handler.dart` (جديد) | `HlsHandler` على المسار `/hls/<videoId>/<key><ext>?src=<url>` |
| `lib/src/video_partial_cache_api.dart` | توجيه `/hls/...` للـ handler الجديد، `getPlayableUrl(..., hls:)`، `VideoPartialCache.isHlsUrl`، وانتظار الكتابات في `debugWaitForIdle` و`dispose` |
| `test/hls_test.dart` (جديد) | اختبارات المُعيد كتابة + اختبارات تكاملية بـ `MockClient` وكاش حقيقي |
| `README.md` | قسم HLS جديد وتحديث نطاق الحزمة والقيود |

**قرارات التصميم:**

- **مفتاح الـ segment = موقعه داخل الـ playlist وليس رابطه.** السبب أن استجابة Vimeo الحقيقية أظهرت أن كل الـ segments لها **نفس المسار** (`segment.m4s`) وتختلف بـ `?sid=N`، والتواقيع (`exp`/`pathsig`) تتغير كل جلسة.
- **الـ playlists تُجلب من الشبكة أولاً** ثم تُخزَّن؛ عند انقطاع الاتصال تُخدَم النسخة المخزّنة، فيعمل الفيديو المشغَّل كاملاً **أوفلاين** (مغطّى باختبار).
- **لا يُخزَّن (يمر مباشرة):** البث المباشر (بدون `ENDLIST`)، `EXT-X-BYTERANGE`، مفاتيح التشفير (لا تُكتب على القرص). روابط `skd://` تبقى كما هي (DRM غير مدعوم).
- الـ segment يُجلب كاملاً قبل إرساله (حد أقصى 128MB)، مع إزالة التكرار للطلبات المتزامنة.
- يعيد استعمال `CacheStore` (الإخلاء، التثبيت، الإحصائيات) و`CacheCounters` نفسه.
- مفتاح الـ entry إلى رقم: 48 بت من SHA-1 (لتفادي التصادم).

**قواعد المفاتيح الداخلية:** `m` (الجذر) · `<parent>_p<n><fp>` (playlist ابن) · `<parent>_s<n>` (segment) · `<parent>_i<n>` (init) · `x<n>` (لا يُخزَّن).

---

## 5. طريقة الاستخدام الجديدة

```dart
// مرة واحدة عند بدء التطبيق
await CachingService.initial();            // m_cubit (Hive)
await AllPlayerVideoCache.init(            // اختياري: كاش بايتات الفيديو
  maxCacheSizeBytes: 1024 * 1024 * 1024,
);

// التشغيل
final ctrl = AllPlayerController(
  playVideoFrom: PlayVideoFrom.auto('https://youtu.be/xxxx'),
  playerConfig: const AllPlayerConfig(resumePlayback: true),
)..initialise();

AllPlayer(controller: ctrl);               // ctrl.close() في dispose

// روابط موقّعة (تتغير كل مرة): أعطِ هوية ثابتة
PlayVideoFrom.network(url, cacheId: 'lesson-42');
```

- **Android:** `android:usesCleartextTraffic="true"` — **iOS:** `NSAllowsLocalNetworking`.
- إدارة الكاش: `AllPlayerVideoCache.instance` و`AllPlayerCache.clear()`.

**ما هي "الروابط الموقّعة"؟** روابط فيها توكن أو توقيع مؤقت (`?token=...&expires=...`) يتغير في كل طلب. الكاش يستعمل الرابط هوية للفيديو، فيظنه فيديو جديداً كل مرة؛ لذلك نعطيه `cacheId` ثابتاً. ولا حاجة له لروابط ثابتة ولا لـ YouTube/Vimeo/Dailymotion (تُستعمل الـ id تلقائياً).

---

## 6. مفاتيح التخزين لكل نوع

**أ) البيانات الوصفية** (bucket `all_player_cache`):

| المصدر | المفتاح |
|---|---|
| `youtube` / `youtubeIframe` | `youtube:<id>` |
| `vimeo` / `vimeoPrivateVideos` | `vimeo:<id>` |
| `dailymotion` | `dailymotion:<id>` |
| `network` | `url:<cacheId أو الرابط كاملاً>` |
| `networkQualityUrls` | `urls:<cacheId>` (بدونه لا يُخزَّن شيء) |
| `asset` | `asset:<المسار>` |
| `file` | `file:<مسار الملف>` |
| التفضيلات | `__prefs` |

**ب) بايتات الفيديو** (`videoId` للبروكسي):

| المصدر | المعرّف |
|---|---|
| `network` | `cacheId`، وإلا SHA-1 للرابط |
| `networkQualityUrls` | `urls:<cacheId>@<جودة>`، وبدون `cacheId` SHA-1 للرابط |
| `youtube` (mp4) | `youtube:<id>@<جودة>` |
| `vimeo` mp4 | `vimeo:<id>@<جودة>` |
| `vimeo` HLS | `vimeo:<id>` (معرّف واحد لكل الجودات) |
| `dailymotion` | `dailymotion:<id>` (HLS) أو `dailymotion:<id>@<جودة>` (mp4) |
| `asset` / `file` / `youtubeIframe` / DASH | لا يُخزَّن |

على القرص: `chunks/<videoId>/<n>.chunk` (والمعرّفات غير الآمنة لأسماء المجلدات يُشفَّر اسم مجلدها).

---

## 7. حالة التحقق

| العنصر | النتيجة |
|---|---|
| `flutter analyze` (`all_player`) | بلا أخطاء؛ فقط تحذيرات `material.dart` المتقادمة (SDK جديد) وتحذير `publish_to` بسبب تبعيات `git` و`path` |
| `flutter test` (`all_player`) | 23 اختباراً ناجحاً |
| `flutter test` (`video_partial_cache`) | 89 اختباراً ناجحاً (بينها اختبارات HLS: التخزين، التشغيل أوفلاين، الإحصائيات، المسارات الخاطئة) |
| بعد حذف `import 'dart:async'` الزائد من `hls_test.dart` | لم أعد تشغيل الاختبارات بعده |
| تشغيل على جهاز أو محاكي، ExoPlayer/AVPlayer حقيقي، CDN فعلي | **لم يُجرَّب** |

عند آخر فحص لـ git كان `all_player` نظيفاً والـ commit الأحدث `169ad75 feat: implement caching for video metadata and playback preferences` (ارتكبه المستخدم، لا أنا). وأما `video_partial_cache` فليس مستودع git.

---

## 8. تحذيرات وقيود معروفة

1. **قبل الاعتماد على HLS جرّب على جهاز حقيقي** (امتداد `.m3u8` في مسار البروكسي، و`Content-Type`، وcleartext).
2. **اليوتيوب هو الأقل ضماناً:** روابط googlevideo تدعم `Range` عادةً لكن قد ترفض أو تخنق الطلبات بدون الـ headers المتوقعة. عند الفشل يعود تلقائياً للرابط المباشر.
3. **التبعية `path: ../video_partial_cache`** تعمل على جهازك فقط؛ يجب رفعها إلى git وتحويلها إلى `git:` مثل `m_cubit` قبل أن يستعملها غيرك.
4. **حد SDK صار `^3.12.2`**؛ أي مستخدم بإصدار أقدم لن يستطيع استعمال المكتبة.
5. **الـ thumbnail يخزّن الرابط فقط.** لتخزين الصورة نفسها أوفلاين نحتاج `cached_network_image` أو حفظ البايتات (مع حد أقصى للحجم).
6. **مشغّل YouTube iframe** يستفيد من الـ thumbnail والتفضيلات فقط؛ استئناف الموضع غير مدعوم له.
7. أول مشاهدة لـ HLS أبطأ قليلاً (الـ segment يُجلب كاملاً قبل إرساله).
8. إذا استبدل صاحب الفيديو الملف على نفس `videoId` تبقى القديمة حتى `clearVideo(videoId)`.
9. DRM (`skd://`) و DASH (`.mpd`) والبث المباشر غير مدعومة بالكاش؛ وفيديوهات `httpHeaders` لا تُخزَّن بايتاتها.

---

## 9. أفكار لم تُنفَّذ (للمراحل القادمة)

- `AllPlayer.url(...)` الذي يدير الـ controller بنفسه (تبسيط التضمين أكثر).
- دمج `config` و`labels` و`progressBarConfig` في كائن واحد `AllPlayerOptions`.
- فصل الموضع عن الـ state لتقليل إعادة بناء الـ `BlocBuilder` (الـ listener يعمل `emit` على كل tick).
- `copyWith` لا يستطيع تصفير `errorMessage` و`currentQuality`.
- رسم المناطق المخزّنة على شريط التقدم (`getCachedRanges` يوفّر بياناتها).
- تمرير `title` للفيديو ليظهر في `getStats`.
- تخزين المدة ونسبة العرض للارتفاع لتفادي "قفزة" الواجهة قبل التحميل.
- Prefetch للروابط والـ thumbnail عند ظهور الفيديو في القوائم.
- كتابة README لـ `all_player` (الحالي فارغ).
- معالجة تحذير `publish_to: none` في `pubspec.yaml`.
