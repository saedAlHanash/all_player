import 'package:video_partial_cache/video_partial_cache.dart';

/// Every text shown by [AllPlayerCacheManager]. Use the default (English),
/// [AllPlayerCacheLabels.arabic], or your own translations.
class AllPlayerCacheLabels {
  const AllPlayerCacheLabels({
    this.title = 'Video cache',
    this.used = 'Used',
    this.free = 'Free',
    this.limit = 'Limit',
    this.videos = 'Videos',
    this.hitRatio = 'Served from cache',
    this.settings = 'Settings',
    this.cacheLimit = 'Cache size limit',
    this.strategy = 'When full, remove',
    this.strategyLru = 'Least recent',
    this.strategyLfu = 'Least used',
    this.strategyFifo = 'Oldest',
    this.strategyLruVideo = 'Least recent whole video',
    this.clearOld = 'Remove videos not watched for 30 days',
    this.clearAll = 'Clear all cached videos',
    this.clearAllConfirm = 'All cached videos will be deleted. Pinned videos too.',
    this.deleteVideo = 'Delete',
    this.deleteVideoConfirm = 'Delete the cached data of this video?',
    this.pin = 'Keep (never remove automatically)',
    this.unpin = 'Stop keeping',
    this.pinned = 'Kept',
    this.cancel = 'Cancel',
    this.confirm = 'Delete',
    this.empty = 'No cached videos yet.\nVideos are cached while they play.',
    this.disabled = 'The video cache is not enabled.\nCall AllPlayerVideoCache.init() at start-up.',
    this.error = 'Could not read the cache',
    this.retry = 'Retry',
    this.cached = 'cached',
    this.unknownProgress = 'size unknown',
    this.sortBy = 'Sort',
    this.sortSize = 'Size',
    this.sortRecent = 'Recently watched',
    this.sortName = 'Name',
    this.freed = 'Freed',
  });

  /// Arabic labels.
  const AllPlayerCacheLabels.arabic()
      : title = 'ذاكرة الفيديو المؤقتة',
        used = 'المستخدم',
        free = 'المتبقي',
        limit = 'الحد الأقصى',
        videos = 'الفيديوهات',
        hitRatio = 'نسبة التشغيل من الكاش',
        settings = 'الإعدادات',
        cacheLimit = 'الحد الأقصى لحجم الكاش',
        strategy = 'عند الامتلاء احذف',
        strategyLru = 'الأقدم مشاهدة',
        strategyLfu = 'الأقل استخداماً',
        strategyFifo = 'الأقدم تخزيناً',
        strategyLruVideo = 'الفيديو الأقدم مشاهدة بالكامل',
        clearOld = 'حذف الفيديوهات غير المشاهدة منذ 30 يوماً',
        clearAll = 'مسح كل الفيديوهات المخزّنة',
        clearAllConfirm = 'سيتم حذف كل الفيديوهات المخزّنة، بما فيها المثبّتة.',
        deleteVideo = 'حذف',
        deleteVideoConfirm = 'حذف البيانات المخزّنة لهذا الفيديو؟',
        pin = 'تثبيت (لا يُحذف تلقائياً)',
        unpin = 'إلغاء التثبيت',
        pinned = 'مثبّت',
        cancel = 'إلغاء',
        confirm = 'حذف',
        empty = 'لا توجد فيديوهات مخزّنة بعد.\nيتم التخزين أثناء التشغيل.',
        disabled = 'كاش الفيديو غير مفعّل.\nاستدعِ AllPlayerVideoCache.init() عند بدء التطبيق.',
        error = 'تعذّرت قراءة الكاش',
        retry = 'إعادة المحاولة',
        cached = 'مخزّن',
        unknownProgress = 'الحجم غير معروف',
        sortBy = 'ترتيب',
        sortSize = 'الحجم',
        sortRecent = 'آخر مشاهدة',
        sortName = 'الاسم',
        freed = 'تم تحرير';

  final String title;
  final String used;
  final String free;
  final String limit;
  final String videos;
  final String hitRatio;
  final String settings;
  final String cacheLimit;
  final String strategy;
  final String strategyLru;
  final String strategyLfu;
  final String strategyFifo;
  final String strategyLruVideo;
  final String clearOld;
  final String clearAll;
  final String clearAllConfirm;
  final String deleteVideo;
  final String deleteVideoConfirm;
  final String pin;
  final String unpin;
  final String pinned;
  final String cancel;
  final String confirm;
  final String empty;
  final String disabled;
  final String error;
  final String retry;
  final String cached;
  final String unknownProgress;
  final String sortBy;
  final String sortSize;
  final String sortRecent;
  final String sortName;
  final String freed;

  String strategyName(EvictionStrategy s) => switch (s) {
        EvictionStrategy.lru => strategyLru,
        EvictionStrategy.lfu => strategyLfu,
        EvictionStrategy.fifo => strategyFifo,
        EvictionStrategy.lruVideo => strategyLruVideo,
      };
}
