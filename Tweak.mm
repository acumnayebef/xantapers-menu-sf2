// Xantapers menu v0.6 — UIKit only, no Substrate/Theos/Dobby required.
// Build as dylib with ARC; frameworks: UIKit, Foundation, CoreGraphics, QuartzCore.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include "Icon.h"   // kXantapersIconB64 (cat avatar, 160x160 JPEG, base64)
#include "SF2Cheats.h"

// ───────────────────────── CONFIG ─────────────────────────
static NSString *const kChannelHandle = @"xantapers";
static NSString *const kMenuTitle     = @"Xantapers";
static NSString *const kMenuVersion   = @"v0.6";
static const CGFloat kFabSize     = 58.0;
static const CGFloat kSidebarW    = 108.0;
static const CGFloat kHeaderH     = 52.0;
static NSString *const kOpacityKey = @"xp_menu_opacity";
static NSString *const kAccentKey  = @"xp_menu_accent";
static NSString *const kEffectKey  = @"xp_menu_effect";
static NSString *const kLangKey    = @"xp_menu_lang";
static const CGFloat kOpacityMin  = 0.20;   // menu never becomes fully invisible
// ──────────────────────────────────────────────────────────

static UIColor *XPHex(uint32_t h) {
    return [UIColor colorWithRed:((h >> 16) & 0xFF) / 255.0
                           green:((h >> 8) & 0xFF) / 255.0
                            blue:(h & 0xFF) / 255.0 alpha:1.0];
}
static UIColor *gAccent;
#define XP_BG      XPHex(0x14121C)
#define XP_SIDE    XPHex(0x0E0C14)
#define XP_CARD    XPHex(0x1F1B2B)
#define XP_ACCENT  (gAccent ?: XPHex(0xE0408F))
#define XP_ACCENT2 XPHex(0x4FC8F0)
#define XP_TEXT    XPHex(0xF4F2FA)
#define XP_MUTED   XPHex(0x9A94B0)

// ───────────────────────── Localization (RU / EN / AR) ─────────────────────────
typedef NS_ENUM(NSInteger, XPLang) { XPLangRU = 0, XPLangEN = 1, XPLangAR = 2 };

static XPLang gLang = XPLangRU;

static XPLang XPDefaultLang(void) {
    NSString *pref = [NSLocale.preferredLanguages firstObject] ?: @"ru";
    if ([pref hasPrefix:@"ar"]) return XPLangAR;
    if ([pref hasPrefix:@"ru"]) return XPLangRU;
    return XPLangEN;
}

static NSDictionary<NSString *, NSArray<NSString *> *> *XPStrings(void) {
    static NSDictionary *d;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // Each entry: @[ru, en, ar]
        d = @{
            @"tab.money":    @[@"Money", @"Money", @"الأموال"],
            @"tab.player":   @[@"Player", @"Player", @"اللاعب"],
            @"tab.creators": @[@"Creators", @"Creators", @"المنشئون"],
            @"settings.title": @[@"Настройки", @"Settings", @"الإعدادات"],

            @"money.infCoins.title": @[@"Бесконечные монеты", @"Infinite coins", @"عملات لا نهائية"],
            @"money.infCoins.hint":  @[@"Каждую секунду выставляет баланс монет на максимум, перекрывая любую трату или начисление в игре.",
                                        @"Pins the coin balance to the maximum every second, overriding any in-game spend or reward.",
                                        @"يضبط رصيد العملات إلى الحد الأقصى كل ثانية، متجاوزًا أي إنفاق أو مكافأة داخل اللعبة."],
            @"money.infGems.title": @[@"Бесконечные гемы", @"Infinite gems", @"جواهر لا نهائية"],
            @"money.infGems.hint":  @[@"То же самое, но для второй валюты (гемы/рубины).",
                                        @"Same idea, for the second currency (gems/rubies).",
                                        @"نفس الفكرة، للعملة الثانية (الجواهر/الياقوت)."],
            @"money.freezeCoins.title": @[@"Заморозить монеты", @"Freeze coins", @"تجميد العملات"],
            @"money.freezeCoins.hint":  @[@"Запоминает текущий баланс монет при включении и держит его неизменным.",
                                        @"Remembers the current coin balance when enabled and keeps it pinned there.",
                                        @"يحفظ رصيد العملات الحالي عند التفعيل ويبقيه ثابتًا."],
            @"money.freezeGems.title": @[@"Заморозить гемы", @"Freeze gems", @"تجميد الجواهر"],
            @"money.freezeGems.hint":  @[@"То же самое для второй валюты.",
                                        @"Same idea for the second currency.",
                                        @"نفس الفكرة للعملة الثانية."],

            @"player.god.title": @[@"Режим бога", @"God mode", @"وضع الإله"],
            @"player.god.hint":  @[@"Каждую секунду держит здоровье твоего бойца на максимуме.",
                                        @"Pins your fighter's health to the maximum every second.",
                                        @"يبقي صحة مقاتلك عند الحد الأقصى كل ثانية."],
            @"player.magic.title": @[@"Нет КД на магию", @"No magic cooldown", @"بدون تهدئة للسحر"],
            @"player.magic.hint":  @[@"Пока отключено: поле заряда магии не опознано в дампе достаточно уверенно.",
                                        @"Disabled for now: the magic-charge field wasn't identified confidently enough in the dump.",
                                        @"معطّل حاليًا: لم يتم التعرف على حقل شحن السحر بثقة كافية في البيانات."],
            @"player.ohk.title": @[@"Убийство с одного удара", @"One-hit kill", @"قتل بضربة واحدة"],
            @"player.ohk.hint":  @[@"Каждую секунду обнуляет здоровье противника, пока бой идёт.",
                                        @"Zeroes the opponent's health every second while the fight is active.",
                                        @"يصفّر صحة الخصم كل ثانية أثناء استمرار القتال."],

            @"settings.opacity.title": @[@"Прозрачность меню", @"Menu opacity", @"شفافية القائمة"],
            @"settings.opacity.hint":  @[@"Меняется прозрачность фона меню. Текст и кнопки остаются читаемыми.",
                                        @"Changes the menu background's transparency. Text and buttons stay readable.",
                                        @"يغيّر شفافية خلفية القائمة. يبقى النص والأزرار واضحين للقراءة."],
            @"settings.accent.title": @[@"Акцентный цвет", @"Accent color", @"اللون المميز"],
            @"settings.effect.title": @[@"Эффект меню", @"Menu effect", @"تأثير القائمة"],
            @"settings.effect.hint":  @[@"Эффект работает, пока меню открыто.",
                                        @"The effect runs only while the menu is open.",
                                        @"يعمل التأثير فقط أثناء فتح القائمة."],
            @"settings.lang.title": @[@"Язык", @"Language", @"اللغة"],
            @"settings.diag.title": @[@"Диагностика (для подтверждения полей)", @"Diagnostics (to confirm fields)", @"التشخيص (لتأكيد الحقول)"],
            @"settings.diag.placeholder": @[@"Диагностика обновится через секунду...", @"Diagnostics will update in a second...", @"سيتم تحديث التشخيص خلال ثانية..."],
            @"settings.diag.copy": @[@"Скопировать лог", @"Copy log", @"نسخ السجل"],

            @"copied": @[@"Скопировано ✓", @"Copied ✓", @"تم النسخ ✓"],
            @"creators.blurb": @[@"Моды для iOS-игр. Новые версии меню, обновления и новости — в Telegram-канале.",
                                        @"iOS game mods. New menu versions, updates and news live on the Telegram channel.",
                                        @"تعديلات لألعاب iOS. الإصدارات الجديدة للقائمة والتحديثات والأخبار على قناة تيليجرام."],
            @"creators.openTelegram": @[@"Открыть Telegram", @"Open Telegram", @"فتح تيليجرام"],
            @"creators.copyHandle": @[@"Копировать @%@", @"Copy @%@", @"نسخ @%@"],

            @"effect.none":    @[@"Нет", @"None", @"بدون"],
            @"effect.neon":    @[@"Неон", @"Neon", @"نيون"],
            @"effect.wave":    @[@"Волна", @"Wave", @"موجة"],
            @"effect.sparks":  @[@"Искры", @"Sparks", @"شرر"],
            @"effect.scanner": @[@"Сканер", @"Scanner", @"ماسح"],
            @"effect.corners": @[@"Уголки", @"Corners", @"زوايا"],
        };
    });
    return d;
}

static NSString *L(NSString *key) {
    NSArray<NSString *> *v = XPStrings()[key];
    if (!v) return key;
    NSInteger i = gLang;
    if (i < 0 || i >= (NSInteger)v.count) i = 0;
    return v[i];
}

// SF Rounded where available; iOS substitutes the right system face for
// Arabic script runs automatically, so this stays legible in all 3 languages
// without bundling custom font files.
static UIFont *XPFont(CGFloat size, UIFontWeight weight) {
    UIFontDescriptor *base = [UIFont systemFontOfSize:size weight:weight].fontDescriptor;
    UIFontDescriptor *rounded = [base fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    return [UIFont fontWithDescriptor:(rounded ?: base) size:size];
}

static UIImage *XPIcon(void) {
    static UIImage *img;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSData *d = [[NSData alloc] initWithBase64EncodedString:@(kXantapersIconB64)
                                                        options:NSDataBase64DecodingIgnoreUnknownCharacters];
        if (d) img = [UIImage imageWithData:d scale:2.0];
    });
    return img;
}

// Passes touches through everywhere except our own subviews.
@interface XPWindow : UIWindow @end
@implementation XPWindow
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    UIView *v = [super hitTest:p withEvent:e];
    if (v == self || v == self.rootViewController.view) return nil;
    return v;
}
@end

typedef void (^XPTabBuilder)(UIView *host);

@interface XPMenuVC : UIViewController
@property (nonatomic, strong) UIButton *fab;
@property (nonatomic, strong) UIView *dim;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIView *sidebar;
@property (nonatomic, strong) UIView *content;
@property (nonatomic, strong) UILabel *headerTitle;
@property (nonatomic, strong) UIButton *gearButton;
@property (nonatomic, strong) NSArray<NSDictionary *> *tabs;
@property (nonatomic, strong) NSMutableArray<UIButton *> *tabButtons;
@property (nonatomic, assign) NSInteger selected;
@property (nonatomic, assign) BOOL open;
@property (nonatomic, assign) BOOL fabPlaced;
@property (nonatomic, assign) BOOL inSettings;
@property (nonatomic, strong) UILabel *diagLabel;
@property (nonatomic, strong) NSTimer *diagTimer;
@property (nonatomic, assign) CGFloat menuOpacity;
@property (nonatomic, assign) NSInteger accentIndex;
@property (nonatomic, assign) NSInteger effectIndex;
@property (nonatomic, strong) UILabel *opacityLabel;
@property (nonatomic, strong) UIScrollView *settingsScroll;
@property (nonatomic, strong) CAGradientLayer *fxGradient;
@property (nonatomic, strong) CAShapeLayer *fxNeon;
@property (nonatomic, strong) CAEmitterLayer *fxEmitter;
@property (nonatomic, strong) CALayer *fxScanner;
@property (nonatomic, strong) NSArray<CALayer *> *fxCorners;
@end

@implementation XPMenuVC

#pragma mark - Accent presets

static NSArray<UIColor *> *XPPresets(void) {
    return @[ XPHex(0xE0408F), XPHex(0x4FC8F0), XPHex(0x57D68D),
              XPHex(0xFFB454), XPHex(0xA070FF), XPHex(0xFF5A5A) ];
}

static UIImage *XPDot(void) {
    static UIImage *img;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(16, 16)];
        img = [r imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
            [UIColor.whiteColor setFill];
            [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(1, 1, 14, 14)] fill];
        }];
    });
    return img;
}

#pragma mark - Tabs (Money / Player / Creators)

- (void)buildTabs {
    __weak __typeof(self) ws = self;
    self.tabs = @[
        @{ @"title": L(@"tab.money"),
           @"build": (XPTabBuilder)^(UIView *host) { [ws buildMoneyInto:host]; } },
        @{ @"title": L(@"tab.player"),
           @"build": (XPTabBuilder)^(UIView *host) { [ws buildPlayerInto:host]; } },
        @{ @"title": L(@"tab.creators"),
           @"build": (XPTabBuilder)^(UIView *host) { [ws buildCreatorsInto:host]; } },
    ];
}

#pragma mark - Lifecycle

- (void)loadView {
    UIView *v = [UIView new];
    v.backgroundColor = UIColor.clearColor;
    self.view = v;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    NSNumber *langPref = [ud objectForKey:kLangKey];
    gLang = langPref ? (XPLang)langPref.integerValue : XPDefaultLang();

    [self buildTabs];
    NSNumber *saved = [ud objectForKey:kOpacityKey];
    self.menuOpacity = saved ? MAX(kOpacityMin, MIN(1.0, saved.doubleValue)) : 1.0;
    NSInteger ai = [ud integerForKey:kAccentKey];
    self.accentIndex = (ai >= 0 && ai < (NSInteger)XPPresets().count) ? ai : 0;
    gAccent = XPPresets()[self.accentIndex];
    NSInteger ei = [ud integerForKey:kEffectKey];
    self.effectIndex = (ei >= 0 && ei <= 5) ? ei : 0;

    // dim (tap outside to close)
    self.dim = [[UIView alloc] init];
    self.dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    self.dim.hidden = YES;
    self.dim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.dim addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMenu)]];
    [self.view addSubview:self.dim];

    // panel
    self.panel = [[UIView alloc] init];
    self.panel.backgroundColor = XP_BG;
    self.panel.layer.cornerRadius = 22;
    self.panel.layer.borderWidth = 1;
    self.panel.layer.borderColor = [XP_ACCENT colorWithAlphaComponent:0.45].CGColor;
    self.panel.clipsToBounds = YES;
    self.panel.hidden = YES;
    [self.view addSubview:self.panel];

    // sidebar
    self.sidebar = [[UIView alloc] init];
    self.sidebar.backgroundColor = XP_SIDE;
    self.sidebar.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self.panel addSubview:self.sidebar];
    [self applyOpacity];

    UIImageView *logo = [[UIImageView alloc] initWithImage:XPIcon()];
    logo.frame = CGRectMake((kSidebarW - 48) / 2, 14, 48, 48);
    logo.layer.cornerRadius = 24;
    logo.clipsToBounds = YES;
    logo.contentMode = UIViewContentModeScaleAspectFill;
    [self.sidebar addSubview:logo];

    self.tabButtons = [NSMutableArray array];
    CGFloat y = 78;
    for (NSInteger i = 0; i < (NSInteger)self.tabs.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(8, y, kSidebarW - 16, 38);
        b.layer.cornerRadius = 11;
        b.tag = i;
        b.titleLabel.font = XPFont(13, UIFontWeightBold);
        [b setTitle:[self.tabs[i][@"title"] uppercaseString] forState:UIControlStateNormal];
        [b addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.sidebar addSubview:b];
        [self.tabButtons addObject:b];
        y += 44;
    }

    // header
    self.headerTitle = [[UILabel alloc] init];
    self.headerTitle.font = XPFont(20, UIFontWeightBold);
    self.headerTitle.textColor = XP_TEXT;
    [self.panel addSubview:self.headerTitle];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.tag = 9001;
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [close setTitleColor:XP_TEXT forState:UIControlStateNormal];
    close.backgroundColor = XP_CARD;
    close.layer.cornerRadius = 15;
    close.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [close addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.panel addSubview:close];

    UIButton *gear = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *gi = [UIImage systemImageNamed:@"gearshape.fill"
                          withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15
                                                                                            weight:UIImageSymbolWeightSemibold]];
    if (gi) [gear setImage:gi forState:UIControlStateNormal];
    else { [gear setTitle:@"\u2699" forState:UIControlStateNormal]; gear.titleLabel.font = [UIFont systemFontOfSize:16]; }
    gear.tintColor = XP_TEXT;
    [gear setTitleColor:XP_TEXT forState:UIControlStateNormal];
    gear.backgroundColor = XP_CARD;
    gear.layer.cornerRadius = 15;
    gear.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [gear addTarget:self action:@selector(toggleSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.panel addSubview:gear];
    self.gearButton = gear;

    // content host
    self.content = [[UIView alloc] init];
    self.content.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.panel addSubview:self.content];

    // floating button
    self.fab = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fab.frame = CGRectMake(0, 0, kFabSize, kFabSize);
    [self.fab setBackgroundImage:XPIcon() forState:UIControlStateNormal];
    self.fab.layer.cornerRadius = kFabSize / 2;
    self.fab.clipsToBounds = YES;
    self.fab.layer.borderWidth = 2.5;
    self.fab.layer.borderColor = XP_ACCENT.CGColor;
    [self.fab addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.fab addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panFab:)]];
    [self.view addSubview:self.fab];

    [self selectTab:0];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect b = self.view.bounds;
    UIEdgeInsets sa = self.view.safeAreaInsets;

    self.dim.frame = b;

    CGFloat w = MIN(b.size.width - 24, 560);
    CGFloat h = MIN(b.size.height - sa.top - sa.bottom - 24, 380);
    CGAffineTransform t = self.panel.transform;
    self.panel.transform = CGAffineTransformIdentity;
    self.panel.frame = CGRectMake((b.size.width - w) / 2, (b.size.height - h) / 2, w, h);
    self.panel.transform = t;

    self.sidebar.frame = CGRectMake(0, 0, kSidebarW, h);
    self.headerTitle.frame = CGRectMake(kSidebarW + 18, 0, w - kSidebarW - 18 - 96, kHeaderH);
    [self.panel viewWithTag:9001].frame = CGRectMake(w - 44, (kHeaderH - 30) / 2, 30, 30);
    self.gearButton.frame = CGRectMake(w - 44 - 38, (kHeaderH - 30) / 2, 30, 30);
    self.content.frame = CGRectMake(kSidebarW, kHeaderH, w - kSidebarW, h - kHeaderH);
    [self layoutEffects];

    if (!self.fabPlaced && b.size.width > 0) {
        self.fab.center = CGPointMake(sa.left + 16 + kFabSize / 2, sa.top + 120);
        self.fabPlaced = YES;
    }
    [self clampFab];
}

#pragma mark - Floating button

- (void)clampFab {
    CGRect b = self.view.bounds;
    UIEdgeInsets sa = self.view.safeAreaInsets;
    CGFloat r = kFabSize / 2;
    CGPoint c = self.fab.center;
    c.x = MAX(sa.left + r, MIN(b.size.width - sa.right - r, c.x));
    c.y = MAX(sa.top + r, MIN(b.size.height - sa.bottom - r, c.y));
    self.fab.center = c;
}

- (void)panFab:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.view];
    self.fab.center = CGPointMake(self.fab.center.x + t.x, self.fab.center.y + t.y);
    [g setTranslation:CGPointZero inView:self.view];
    if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled) {
        [UIView animateWithDuration:0.2 animations:^{ [self clampFab]; }];
    }
}

#pragma mark - Open / close

- (void)toggleMenu { self.open ? [self closeMenu] : [self openMenu]; }

- (void)openMenu {
    if (self.open) return;
    self.open = YES;
    self.dim.hidden = NO;
    self.dim.alpha = 0;
    self.panel.hidden = NO;
    self.panel.alpha = 0;
    self.panel.transform = CGAffineTransformMakeScale(0.92, 0.92);
    [self.view bringSubviewToFront:self.fab];
    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.dim.alpha = 1;
        self.panel.alpha = 1;
        self.panel.transform = CGAffineTransformIdentity;
    } completion:nil];
    [self applyEffect];
}

- (void)closeMenu {
    if (!self.open) return;
    self.open = NO;
    [UIView animateWithDuration:0.18 animations:^{
        self.dim.alpha = 0;
        self.panel.alpha = 0;
        self.panel.transform = CGAffineTransformMakeScale(0.94, 0.94);
    } completion:^(BOOL f) {
        if (self.open) return;
        self.dim.hidden = YES;
        self.panel.hidden = YES;
        self.panel.transform = CGAffineTransformIdentity;
        [self removeEffects];
        [self.diagTimer invalidate];
        self.diagTimer = nil;
    }];
}

#pragma mark - Tabs

- (void)tabTapped:(UIButton *)b { [self selectTab:b.tag]; }

- (void)selectTab:(NSInteger)i {
    if (i < 0 || i >= (NSInteger)self.tabs.count) return;
    self.selected = i;
    self.inSettings = NO;
    [self updateGearState];
    [self.diagTimer invalidate];
    self.diagTimer = nil;
    for (UIButton *b in self.tabButtons) {
        BOOL on = (b.tag == i);
        b.backgroundColor = on ? [XP_ACCENT colorWithAlphaComponent:0.9] : UIColor.clearColor;
        [b setTitleColor:on ? UIColor.whiteColor : XP_MUTED forState:UIControlStateNormal];
    }
    self.headerTitle.text = self.tabs[i][@"title"];
    for (UIView *v in self.content.subviews) [v removeFromSuperview];
    XPTabBuilder build = self.tabs[i][@"build"];
    build(self.content);
}

#pragma mark - Switch row helper

- (UIView *)switchRowTitle:(NSString *)title
                       hint:(NSString *)hint
                   initialOn:(BOOL)on
                     enabled:(BOOL)enabled
                      action:(SEL)sel {
    UILabel *t = [[UILabel alloc] init];
    t.text = title;
    t.font = XPFont(15, UIFontWeightSemibold);
    t.textColor = enabled ? XP_TEXT : XP_MUTED;
    t.translatesAutoresizingMaskIntoConstraints = NO;
    [t setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    UISwitch *sw = [[UISwitch alloc] init];
    sw.onTintColor = XP_ACCENT;
    sw.on = on;
    sw.enabled = enabled;
    sw.translatesAutoresizingMaskIntoConstraints = NO;
    if (enabled) [sw addTarget:self action:sel forControlEvents:UIControlEventValueChanged];
    [sw setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    UIView *row = [[UIView alloc] init];
    [row addSubview:t]; [row addSubview:sw];
    [NSLayoutConstraint activateConstraints:@[
        [t.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [t.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [sw.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
        [sw.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [sw.leadingAnchor constraintGreaterThanOrEqualToAnchor:t.trailingAnchor constant:8],
        [row.topAnchor constraintEqualToAnchor:t.topAnchor],
        [row.bottomAnchor constraintEqualToAnchor:t.bottomAnchor],
    ]];

    if (hint.length == 0) return row;
    UILabel *h = [self hintLabel:hint];
    h.translatesAutoresizingMaskIntoConstraints = NO;
    UIStackView *v = [[UIStackView alloc] initWithArrangedSubviews:@[row, h]];
    v.axis = UILayoutConstraintAxisVertical;
    v.spacing = 4;
    return v;
}

- (UIScrollView *)makeTabScrollInto:(UIView *)host stack:(UIStackView **)outStack {
    UIScrollView *sv = [[UIScrollView alloc] init];
    sv.translatesAutoresizingMaskIntoConstraints = NO;
    sv.alwaysBounceVertical = YES;
    sv.showsVerticalScrollIndicator = NO;
    [host addSubview:sv];
    [NSLayoutConstraint activateConstraints:@[
        [sv.topAnchor constraintEqualToAnchor:host.topAnchor],
        [sv.bottomAnchor constraintEqualToAnchor:host.bottomAnchor],
        [sv.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
        [sv.trailingAnchor constraintEqualToAnchor:host.trailingAnchor],
    ]];
    UIStackView *st = [[UIStackView alloc] init];
    st.axis = UILayoutConstraintAxisVertical;
    st.spacing = 12;
    st.translatesAutoresizingMaskIntoConstraints = NO;
    [sv addSubview:st];
    [NSLayoutConstraint activateConstraints:@[
        [st.topAnchor constraintEqualToAnchor:sv.contentLayoutGuide.topAnchor constant:4],
        [st.bottomAnchor constraintEqualToAnchor:sv.contentLayoutGuide.bottomAnchor constant:-16],
        [st.leadingAnchor constraintEqualToAnchor:sv.contentLayoutGuide.leadingAnchor constant:18],
        [st.trailingAnchor constraintEqualToAnchor:sv.contentLayoutGuide.trailingAnchor constant:-18],
        [st.widthAnchor constraintEqualToAnchor:sv.frameLayoutGuide.widthAnchor constant:-36],
    ]];
    *outStack = st;
    return sv;
}

#pragma mark - Money tab

- (void)infiniteCoinsChanged:(UISwitch *)sw { sf2::SetInfiniteCoins(sw.on); }
- (void)infiniteGemsChanged:(UISwitch *)sw { sf2::SetInfiniteGems(sw.on); }
- (void)freezeCoinsChanged:(UISwitch *)sw  { sf2::SetFreezeCoins(sw.on); }
- (void)freezeGemsChanged:(UISwitch *)sw   { sf2::SetFreezeGems(sw.on); }

- (void)buildMoneyInto:(UIView *)host {
    UIStackView *st; [self makeTabScrollInto:host stack:&st];
    sf2::State &s = sf2::state();
    [st addArrangedSubview:[self cardWithViews:@[
        [self switchRowTitle:L(@"money.infCoins.title") hint:L(@"money.infCoins.hint") initialOn:s.infiniteCoins enabled:YES action:@selector(infiniteCoinsChanged:)],
        [self switchRowTitle:L(@"money.infGems.title") hint:L(@"money.infGems.hint") initialOn:s.infiniteGems enabled:YES action:@selector(infiniteGemsChanged:)],
        [self switchRowTitle:L(@"money.freezeCoins.title") hint:L(@"money.freezeCoins.hint") initialOn:s.freezeCoins enabled:YES action:@selector(freezeCoinsChanged:)],
        [self switchRowTitle:L(@"money.freezeGems.title") hint:L(@"money.freezeGems.hint") initialOn:s.freezeGems enabled:YES action:@selector(freezeGemsChanged:)],
    ]]];
}

#pragma mark - Player tab

- (void)godModeChanged:(UISwitch *)sw { sf2::SetGodMode(sw.on); }
- (void)oneHitKillChanged:(UISwitch *)sw { sf2::SetOneHitKill(sw.on); }

- (void)buildPlayerInto:(UIView *)host {
    UIStackView *st; [self makeTabScrollInto:host stack:&st];
    sf2::State &s = sf2::state();
    [st addArrangedSubview:[self cardWithViews:@[
        [self switchRowTitle:L(@"player.god.title") hint:L(@"player.god.hint") initialOn:s.godMode enabled:YES action:@selector(godModeChanged:)],
        [self switchRowTitle:L(@"player.magic.title") hint:L(@"player.magic.hint") initialOn:NO enabled:NO action:nil],
        [self switchRowTitle:L(@"player.ohk.title") hint:L(@"player.ohk.hint") initialOn:s.oneHitKill enabled:YES action:@selector(oneHitKillChanged:)],
    ]]];
}

#pragma mark - Accent

- (void)swatchTapped:(UIButton *)b {
    self.accentIndex = b.tag;
    gAccent = XPPresets()[self.accentIndex];
    [NSUserDefaults.standardUserDefaults setInteger:b.tag forKey:kAccentKey];
    [self applyAccent];
}

- (void)applyAccent {
    self.panel.layer.borderColor = [XP_ACCENT colorWithAlphaComponent:0.45].CGColor;
    self.fab.layer.borderColor = XP_ACCENT.CGColor;
    if (self.inSettings) {
        CGPoint off = self.settingsScroll.contentOffset;
        [self showSettings];
        [self.content layoutIfNeeded];
        self.settingsScroll.contentOffset = off;
    } else {
        [self selectTab:self.selected];
    }
    [self applyEffect];
}

#pragma mark - Effects (0 none, 1 Neon, 2 Wave, 3 Sparks, 4 Scanner, 5 Corners)

- (void)removeEffects {
    [self.fxGradient removeFromSuperlayer]; self.fxGradient = nil;
    [self.fxNeon removeFromSuperlayer];     self.fxNeon = nil;
    [self.fxEmitter removeFromSuperlayer];  self.fxEmitter = nil;
    [self.fxScanner removeFromSuperlayer];  self.fxScanner = nil;
    for (CALayer *l in self.fxCorners) [l removeFromSuperlayer];
    self.fxCorners = nil;
}

- (void)applyEffect {
    [self removeEffects];
    if (!self.open || self.effectIndex == 0) return;
    CALayer *host = self.panel.layer;

    if (self.effectIndex == 1) {            // Neon: pulsing inner glow on the border
        CAShapeLayer *n = [CAShapeLayer layer];
        n.fillColor = nil;
        n.strokeColor = XP_ACCENT.CGColor;
        n.lineWidth = 3;
        n.shadowColor = XP_ACCENT.CGColor;
        n.shadowOffset = CGSizeZero;
        n.shadowRadius = 10;
        n.shadowOpacity = 1;
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"opacity"];
        a.fromValue = @0.45; a.toValue = @1.0; a.duration = 1.3;
        a.autoreverses = YES; a.repeatCount = HUGE_VALF;
        a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [n addAnimation:a forKey:@"pulse"];
        [host addSublayer:n];
        self.fxNeon = n;
    } else if (self.effectIndex == 2) {     // Wave: diagonal light sweep
        CAGradientLayer *g = [CAGradientLayer layer];
        g.colors = @[ (id)[XP_ACCENT colorWithAlphaComponent:0.0].CGColor,
                      (id)[XP_ACCENT colorWithAlphaComponent:0.32].CGColor,
                      (id)[XP_ACCENT colorWithAlphaComponent:0.0].CGColor ];
        g.startPoint = CGPointMake(0, 0);
        g.endPoint = CGPointMake(1, 1);
        g.locations = @[ @-1.0, @-0.5, @0.0 ];
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"locations"];
        a.fromValue = @[ @-1.0, @-0.5, @0.0 ];
        a.toValue   = @[ @1.0, @1.5, @2.0 ];
        a.duration = 3.2; a.repeatCount = HUGE_VALF;
        [g addAnimation:a forKey:@"sweep"];
        [host addSublayer:g];
        self.fxGradient = g;
    } else if (self.effectIndex == 3) {     // Sparks: glowing dots drifting upward
        CAEmitterCell *c = [CAEmitterCell emitterCell];
        c.contents = (id)XPDot().CGImage;
        c.birthRate = 7;
        c.lifetime = 7;
        c.velocity = 10;
        c.velocityRange = 8;
        c.emissionRange = (CGFloat)(2 * M_PI);
        c.yAcceleration = -14;
        c.scale = 0.30;
        c.scaleRange = 0.22;
        c.alphaSpeed = -0.11;
        c.color = [XP_ACCENT colorWithAlphaComponent:0.85].CGColor;
        CAEmitterLayer *e = [CAEmitterLayer layer];
        e.emitterCells = @[c];
        e.emitterShape = kCAEmitterLayerLine;
        e.renderMode = kCAEmitterLayerAdditive;
        [host addSublayer:e];
        self.fxEmitter = e;
    } else if (self.effectIndex == 4) {     // Scanner: thin bright line sweeping top-to-bottom
        CALayer *line = [CALayer layer];
        line.backgroundColor = [XP_ACCENT colorWithAlphaComponent:0.9].CGColor;
        line.shadowColor = XP_ACCENT.CGColor;
        line.shadowOpacity = 0.9;
        line.shadowRadius = 6;
        line.shadowOffset = CGSizeZero;
        [host addSublayer:line];
        self.fxScanner = line;
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"position.y"];
        a.fromValue = @(-4);
        a.toValue = @(self.panel.bounds.size.height + 4);
        a.duration = 2.4;
        a.repeatCount = HUGE_VALF;
        a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [line addAnimation:a forKey:@"scan"];
    } else {                                // Corners: four glowing dots pulsing in sequence
        NSMutableArray<CALayer *> *corners = [NSMutableArray array];
        for (int i = 0; i < 4; i++) {
            CALayer *dot = [CALayer layer];
            dot.backgroundColor = XP_ACCENT.CGColor;
            dot.cornerRadius = 4;
            dot.shadowColor = XP_ACCENT.CGColor;
            dot.shadowOpacity = 1;
            dot.shadowRadius = 8;
            dot.shadowOffset = CGSizeZero;
            dot.bounds = CGRectMake(0, 0, 8, 8);
            [host addSublayer:dot];
            CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"opacity"];
            a.fromValue = @0.25; a.toValue = @1.0; a.duration = 1.0;
            a.autoreverses = YES; a.repeatCount = HUGE_VALF;
            a.beginTime = CACurrentMediaTime() + i * 0.22;
            a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            [dot addAnimation:a forKey:@"pulse"];
            [corners addObject:dot];
        }
        self.fxCorners = corners;
    }
    [self layoutEffects];
}

- (void)layoutEffects {
    CGRect b = self.panel.bounds;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (self.fxGradient) self.fxGradient.frame = b;
    if (self.fxNeon) {
        self.fxNeon.frame = b;
        self.fxNeon.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(b, 1.5, 1.5) cornerRadius:20.5].CGPath;
    }
    if (self.fxEmitter) {
        self.fxEmitter.frame = b;
        self.fxEmitter.emitterPosition = CGPointMake(b.size.width / 2, b.size.height + 4);
        self.fxEmitter.emitterSize = CGSizeMake(b.size.width, 1);
    }
    if (self.fxScanner) {
        self.fxScanner.bounds = CGRectMake(0, 0, b.size.width, 2);
        self.fxScanner.position = CGPointMake(b.size.width / 2, self.fxScanner.position.y);
        self.fxScanner.anchorPoint = CGPointMake(0.5, 0.5);
    }
    if (self.fxCorners.count == 4) {
        CGFloat m = 10;
        CGPoint pts[4] = {
            CGPointMake(m, m), CGPointMake(b.size.width - m, m),
            CGPointMake(m, b.size.height - m), CGPointMake(b.size.width - m, b.size.height - m)
        };
        for (int i = 0; i < 4; i++) self.fxCorners[i].position = pts[i];
    }
    [CATransaction commit];
}

- (void)effectChanged:(UISegmentedControl *)seg {
    self.effectIndex = seg.selectedSegmentIndex;
    [NSUserDefaults.standardUserDefaults setInteger:self.effectIndex forKey:kEffectKey];
    [self applyEffect];
}

#pragma mark - Language

- (void)languageChanged:(UISegmentedControl *)seg {
    gLang = (XPLang)seg.selectedSegmentIndex;
    [NSUserDefaults.standardUserDefaults setInteger:gLang forKey:kLangKey];
    [self applyLanguage];
}

- (void)applyLanguage {
    [self buildTabs]; // refreshes self.tabs[i][@"title"] with the new language
    for (NSInteger i = 0; i < (NSInteger)self.tabButtons.count && i < (NSInteger)self.tabs.count; i++) {
        [self.tabButtons[i] setTitle:[self.tabs[i][@"title"] uppercaseString] forState:UIControlStateNormal];
    }
    if (self.inSettings) {
        self.headerTitle.text = L(@"settings.title");
        [self showSettings];
    } else {
        self.headerTitle.text = self.tabs[self.selected][@"title"];
        [self selectTab:self.selected];
    }
}

#pragma mark - Settings

- (UILabel *)cardTitle:(NSString *)t {
    UILabel *l = [[UILabel alloc] init];
    l.text = t;
    l.font = XPFont(15, UIFontWeightSemibold);
    l.textColor = XP_TEXT;
    l.numberOfLines = 0;
    return l;
}

- (UILabel *)hintLabel:(NSString *)t {
    UILabel *l = [[UILabel alloc] init];
    l.text = t;
    l.font = [UIFont systemFontOfSize:12];
    l.textColor = XP_MUTED;
    l.numberOfLines = 0;
    return l;
}

- (UIView *)cardWithViews:(NSArray<UIView *> *)views {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = XP_CARD;
    card.layer.cornerRadius = 16;
    UIStackView *s = [[UIStackView alloc] initWithArrangedSubviews:views];
    s.axis = UILayoutConstraintAxisVertical;
    s.spacing = 12;
    s.layoutMarginsRelativeArrangement = YES;
    s.layoutMargins = UIEdgeInsetsMake(14, 14, 14, 14);
    s.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:s];
    [NSLayoutConstraint activateConstraints:@[
        [s.topAnchor constraintEqualToAnchor:card.topAnchor],
        [s.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],
        [s.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [s.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
    ]];
    return card;
}

- (void)toggleSettings {
    if (self.inSettings) [self selectTab:self.selected];
    else [self showSettings];
}

- (void)updateGearState {
    self.gearButton.backgroundColor = self.inSettings ? XP_ACCENT : XP_CARD;
    self.gearButton.tintColor = self.inSettings ? UIColor.whiteColor : XP_TEXT;
}

- (void)showSettings {
    self.inSettings = YES;
    [self updateGearState];
    for (UIButton *b in self.tabButtons) {
        b.backgroundColor = UIColor.clearColor;
        [b setTitleColor:XP_MUTED forState:UIControlStateNormal];
    }
    self.headerTitle.text = L(@"settings.title");
    for (UIView *v in self.content.subviews) [v removeFromSuperview];
    [self buildSettingsInto:self.content];
}

- (void)applyOpacity {
    self.panel.backgroundColor   = [XP_BG   colorWithAlphaComponent:self.menuOpacity];
    self.sidebar.backgroundColor = [XP_SIDE colorWithAlphaComponent:self.menuOpacity];
}

- (void)opacityChanged:(UISlider *)s {
    self.menuOpacity = s.value;
    [self applyOpacity];
    self.opacityLabel.text = [NSString stringWithFormat:@"%d%%", (int)lround(s.value * 100)];
    [NSUserDefaults.standardUserDefaults setDouble:s.value forKey:kOpacityKey];
}

- (void)refreshDiagnostics {
    if (!self.diagLabel) return;
    self.diagLabel.text = sf2::DiagnosticsText();
}

- (void)copyDiagnostics:(UIButton *)b {
    UIPasteboard.generalPasteboard.string = self.diagLabel.text ?: @"";
    NSString *old = [b titleForState:UIControlStateNormal];
    [b setTitle:L(@"copied") forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [b setTitle:old forState:UIControlStateNormal];
    });
}

- (void)buildSettingsInto:(UIView *)host {
    UIScrollView *sv = [[UIScrollView alloc] init];
    sv.translatesAutoresizingMaskIntoConstraints = NO;
    sv.alwaysBounceVertical = YES;
    sv.showsVerticalScrollIndicator = NO;
    [host addSubview:sv];
    self.settingsScroll = sv;
    [NSLayoutConstraint activateConstraints:@[
        [sv.topAnchor constraintEqualToAnchor:host.topAnchor],
        [sv.bottomAnchor constraintEqualToAnchor:host.bottomAnchor],
        [sv.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
        [sv.trailingAnchor constraintEqualToAnchor:host.trailingAnchor],
    ]];

    UIStackView *st = [[UIStackView alloc] init];
    st.axis = UILayoutConstraintAxisVertical;
    st.spacing = 12;
    st.translatesAutoresizingMaskIntoConstraints = NO;
    [sv addSubview:st];
    [NSLayoutConstraint activateConstraints:@[
        [st.topAnchor constraintEqualToAnchor:sv.contentLayoutGuide.topAnchor constant:4],
        [st.bottomAnchor constraintEqualToAnchor:sv.contentLayoutGuide.bottomAnchor constant:-16],
        [st.leadingAnchor constraintEqualToAnchor:sv.contentLayoutGuide.leadingAnchor constant:18],
        [st.trailingAnchor constraintEqualToAnchor:sv.contentLayoutGuide.trailingAnchor constant:-18],
        [st.widthAnchor constraintEqualToAnchor:sv.frameLayoutGuide.widthAnchor constant:-36],
    ]];

    // ── language
    UISegmentedControl *langSeg = [[UISegmentedControl alloc] initWithItems:@[@"RU", @"EN", @"AR"]];
    langSeg.selectedSegmentIndex = gLang;
    langSeg.selectedSegmentTintColor = XP_ACCENT;
    langSeg.backgroundColor = XP_SIDE;
    UIFont *lf = XPFont(12, UIFontWeightSemibold);
    [langSeg setTitleTextAttributes:@{ NSForegroundColorAttributeName: XP_MUTED, NSFontAttributeName: lf } forState:UIControlStateNormal];
    [langSeg setTitleTextAttributes:@{ NSForegroundColorAttributeName: UIColor.whiteColor, NSFontAttributeName: lf } forState:UIControlStateSelected];
    [langSeg addTarget:self action:@selector(languageChanged:) forControlEvents:UIControlEventValueChanged];
    [st addArrangedSubview:[self cardWithViews:@[[self cardTitle:L(@"settings.lang.title")], langSeg]]];

    // ── opacity
    UILabel *oTitle = [self cardTitle:L(@"settings.opacity.title")];
    self.opacityLabel = [[UILabel alloc] init];
    self.opacityLabel.text = [NSString stringWithFormat:@"%d%%", (int)lround(self.menuOpacity * 100)];
    self.opacityLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightSemibold];
    self.opacityLabel.textColor = XP_ACCENT2;
    self.opacityLabel.textAlignment = NSTextAlignmentRight;
    [self.opacityLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [oTitle setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    UIStackView *oRow = [[UIStackView alloc] initWithArrangedSubviews:@[oTitle, self.opacityLabel]];
    oRow.axis = UILayoutConstraintAxisHorizontal;
    oRow.alignment = UIStackViewAlignmentCenter;

    UISlider *sl = [[UISlider alloc] init];
    sl.minimumValue = kOpacityMin;
    sl.maximumValue = 1.0;
    sl.value = self.menuOpacity;
    sl.minimumTrackTintColor = XP_ACCENT;
    sl.maximumTrackTintColor = [XP_MUTED colorWithAlphaComponent:0.35];
    sl.thumbTintColor = UIColor.whiteColor;
    [sl addTarget:self action:@selector(opacityChanged:) forControlEvents:UIControlEventValueChanged];

    [st addArrangedSubview:[self cardWithViews:@[oRow, sl, [self hintLabel:L(@"settings.opacity.hint")]]]];

    // ── accent color
    NSArray<UIColor *> *presets = XPPresets();
    NSMutableArray<UIView *> *sw = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)presets.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.tag = i;
        b.backgroundColor = presets[i];
        b.layer.cornerRadius = 15;
        b.layer.borderWidth = (i == self.accentIndex) ? 3 : 0;
        b.layer.borderColor = UIColor.whiteColor.CGColor;
        [b.widthAnchor constraintEqualToConstant:30].active = YES;
        [b.heightAnchor constraintEqualToConstant:30].active = YES;
        [b addTarget:self action:@selector(swatchTapped:) forControlEvents:UIControlEventTouchUpInside];
        [sw addObject:b];
    }
    UIStackView *swRow = [[UIStackView alloc] initWithArrangedSubviews:sw];
    swRow.axis = UILayoutConstraintAxisHorizontal;
    swRow.distribution = UIStackViewDistributionEqualSpacing;
    swRow.alignment = UIStackViewAlignmentCenter;
    [st addArrangedSubview:[self cardWithViews:@[[self cardTitle:L(@"settings.accent.title")], swRow]]];

    // ── effects
    NSArray<NSString *> *effNames = @[L(@"effect.none"), L(@"effect.neon"), L(@"effect.wave"),
                                       L(@"effect.sparks"), L(@"effect.scanner"), L(@"effect.corners")];
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:effNames];
    seg.selectedSegmentIndex = self.effectIndex;
    seg.selectedSegmentTintColor = XP_ACCENT;
    seg.backgroundColor = XP_SIDE;
    UIFont *sf = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    [seg setTitleTextAttributes:@{ NSForegroundColorAttributeName: XP_MUTED, NSFontAttributeName: sf }
                       forState:UIControlStateNormal];
    [seg setTitleTextAttributes:@{ NSForegroundColorAttributeName: UIColor.whiteColor, NSFontAttributeName: sf }
                       forState:UIControlStateSelected];
    [seg addTarget:self action:@selector(effectChanged:) forControlEvents:UIControlEventValueChanged];
    [st addArrangedSubview:[self cardWithViews:@[[self cardTitle:L(@"settings.effect.title")], seg, [self hintLabel:L(@"settings.effect.hint")]]]];

    // ── diagnostics (moved here from the old Game tab)
    self.diagLabel = [[UILabel alloc] init];
    self.diagLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    self.diagLabel.textColor = XP_MUTED;
    self.diagLabel.numberOfLines = 0;
    self.diagLabel.text = L(@"settings.diag.placeholder");
    UIButton *copy = [self buttonTitle:L(@"settings.diag.copy") primary:NO action:@selector(copyDiagnostics:)];
    [st addArrangedSubview:[self cardWithViews:@[[self cardTitle:L(@"settings.diag.title")], self.diagLabel, copy]]];

    [self.diagTimer invalidate];
    self.diagTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshDiagnostics) userInfo:nil repeats:YES];
    [self refreshDiagnostics];
}

#pragma mark - Buttons

- (UIButton *)buttonTitle:(NSString *)title primary:(BOOL)primary action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.titleLabel.font = XPFont(15, UIFontWeightSemibold);
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:primary ? UIColor.whiteColor : XP_TEXT forState:UIControlStateNormal];
    b.backgroundColor = primary ? XP_ACCENT : XP_CARD;
    b.layer.cornerRadius = 13;
    [b.heightAnchor constraintEqualToConstant:46].active = YES;
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

#pragma mark - Creators tab

- (void)buildCreatorsInto:(UIView *)host {
    UIScrollView *sv = [[UIScrollView alloc] init];
    sv.translatesAutoresizingMaskIntoConstraints = NO;
    sv.alwaysBounceVertical = YES;
    sv.showsVerticalScrollIndicator = NO;
    [host addSubview:sv];
    [NSLayoutConstraint activateConstraints:@[
        [sv.topAnchor constraintEqualToAnchor:host.topAnchor],
        [sv.bottomAnchor constraintEqualToAnchor:host.bottomAnchor],
        [sv.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
        [sv.trailingAnchor constraintEqualToAnchor:host.trailingAnchor],
    ]];

    UIStackView *st = [[UIStackView alloc] init];
    st.axis = UILayoutConstraintAxisVertical;
    st.spacing = 12;
    st.translatesAutoresizingMaskIntoConstraints = NO;
    [sv addSubview:st];
    [NSLayoutConstraint activateConstraints:@[
        [st.topAnchor constraintEqualToAnchor:sv.contentLayoutGuide.topAnchor constant:4],
        [st.bottomAnchor constraintEqualToAnchor:sv.contentLayoutGuide.bottomAnchor constant:-16],
        [st.leadingAnchor constraintEqualToAnchor:sv.contentLayoutGuide.leadingAnchor constant:18],
        [st.trailingAnchor constraintEqualToAnchor:sv.contentLayoutGuide.trailingAnchor constant:-18],
        [st.widthAnchor constraintEqualToAnchor:sv.frameLayoutGuide.widthAnchor constant:-36],
    ]];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = XP_CARD;
    card.layer.cornerRadius = 16;

    UIImageView *av = [[UIImageView alloc] initWithImage:XPIcon()];
    av.translatesAutoresizingMaskIntoConstraints = NO;
    av.layer.cornerRadius = 32;
    av.clipsToBounds = YES;
    av.contentMode = UIViewContentModeScaleAspectFill;
    av.layer.borderWidth = 2;
    av.layer.borderColor = XP_ACCENT2.CGColor;

    UILabel *name = [[UILabel alloc] init];
    name.text = kMenuTitle;
    name.font = XPFont(19, UIFontWeightBold);
    name.textColor = XP_TEXT;

    UILabel *handle = [[UILabel alloc] init];
    handle.text = [@"@" stringByAppendingString:kChannelHandle];
    handle.font = XPFont(15, UIFontWeightSemibold);
    handle.textColor = XP_ACCENT2;

    UILabel *blurb = [[UILabel alloc] init];
    blurb.text = L(@"creators.blurb");
    blurb.font = [UIFont systemFontOfSize:13];
    blurb.textColor = XP_MUTED;
    blurb.numberOfLines = 0;

    UIStackView *names = [[UIStackView alloc] initWithArrangedSubviews:@[name, handle]];
    names.axis = UILayoutConstraintAxisVertical;
    names.spacing = 2;
    names.translatesAutoresizingMaskIntoConstraints = NO;
    blurb.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:av]; [card addSubview:names]; [card addSubview:blurb];
    [NSLayoutConstraint activateConstraints:@[
        [av.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [av.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [av.widthAnchor constraintEqualToConstant:64],
        [av.heightAnchor constraintEqualToConstant:64],
        [names.leadingAnchor constraintEqualToAnchor:av.trailingAnchor constant:14],
        [names.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [names.centerYAnchor constraintEqualToAnchor:av.centerYAnchor],
        [blurb.topAnchor constraintEqualToAnchor:av.bottomAnchor constant:12],
        [blurb.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [blurb.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [blurb.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],
    ]];
    [st addArrangedSubview:card];

    [st addArrangedSubview:[self buttonTitle:L(@"creators.openTelegram") primary:YES action:@selector(openTelegram)]];
    [st addArrangedSubview:[self buttonTitle:[NSString stringWithFormat:L(@"creators.copyHandle"), kChannelHandle]
                                     primary:NO action:@selector(copyHandle:)]];

    UILabel *ver = [[UILabel alloc] init];
    ver.text = [NSString stringWithFormat:@"%@ %@", kMenuTitle, kMenuVersion];
    ver.font = [UIFont systemFontOfSize:11];
    ver.textColor = XP_MUTED;
    ver.textAlignment = NSTextAlignmentCenter;
    [st addArrangedSubview:ver];
}

- (void)openTelegram {
    UIApplication *app = UIApplication.sharedApplication;
    NSURL *tg  = [NSURL URLWithString:[@"tg://resolve?domain=" stringByAppendingString:kChannelHandle]];
    NSURL *web = [NSURL URLWithString:[@"https://t.me/" stringByAppendingString:kChannelHandle]];
    [app openURL:tg options:@{} completionHandler:^(BOOL ok) {
        if (!ok) [app openURL:web options:@{} completionHandler:nil];
    }];
}

- (void)copyHandle:(UIButton *)b {
    UIPasteboard.generalPasteboard.string = [@"@" stringByAppendingString:kChannelHandle];
    NSString *old = [b titleForState:UIControlStateNormal];
    [b setTitle:L(@"copied") forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [b setTitle:old forState:UIControlStateNormal];
    });
}

@end

#pragma mark - Install

static XPWindow *gWindow;

static void XPTryInstall(int attempt) {
    if (gWindow) return;
    UIWindowScene *scene = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (![s isKindOfClass:UIWindowScene.class]) continue;
        if (s.activationState == UISceneActivationStateForegroundActive) { scene = (UIWindowScene *)s; break; }
        if (!scene) scene = (UIWindowScene *)s;
    }
    if (!scene) {
        if (attempt < 20) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                XPTryInstall(attempt + 1);
            });
        }
        return;
    }
    gWindow = [[XPWindow alloc] initWithWindowScene:scene];
    gWindow.frame = scene.coordinateSpace.bounds;
    gWindow.windowLevel = UIWindowLevelAlert + 100;
    gWindow.backgroundColor = UIColor.clearColor;
    gWindow.rootViewController = [XPMenuVC new];
    gWindow.hidden = NO;   // not makeKeyAndVisible: keep the game's key window
}

__attribute__((constructor))
static void XPInit(void) {
    [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification
                                                    object:nil queue:NSOperationQueue.mainQueue
                                                usingBlock:^(NSNotification *n) { XPTryInstall(0); }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XPTryInstall(0);
    });
}
