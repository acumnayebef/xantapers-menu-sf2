// SF2Cheats.h — Shadow Fight 2 field access, derived from the user-supplied
// dump.cs (Beebyte-obfuscated Assembly-CSharp, il2cpp).
//
// IMPORTANT — READ BEFORE CHANGING OFFSETS:
// Every class/method NAME below is an exact 11-letter Beebyte-obfuscated
// identifier taken verbatim from dump.cs. These WILL change on the game's
// next build. Every "// CANDIDATE" field is a real, dump-confirmed memory
// offset of a real field — but its GAMEPLAY MEANING (is it health? coins?)
// was never confirmed, because the dump has no readable names and this
// environment has no running game / disassembler to check against. Use the
// in-menu Diagnostics panel to confirm each candidate before trusting it.
//
// Struct layout convention used throughout: il2cpp instance objects have a
// 0x10 header (klass ptr + monitor ptr); the dumper's "// 0xNN" comments for
// instance fields already include that header, so offsets below are used as
// raw byte offsets from the object pointer with no extra adjustment.
#pragma once
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <stdint.h>

// ───────────────────────── IL2CPP minimal shim ─────────────────────────
// All il2cpp_* symbols are exported by the statically-linked libil2cpp
// inside UnityFramework and are already loaded in-process once the app
// has started Unity; we just dlsym them from the global symbol table.
// This is Unity's own public native embedding API, not a defeat mechanism.
typedef void* (*il2cpp_domain_get_t)(void);
typedef void** (*il2cpp_domain_get_assemblies_t)(void* domain, size_t* size);
typedef void* (*il2cpp_assembly_get_image_t)(void* assembly);
typedef size_t (*il2cpp_image_get_class_count_t)(void* image);
typedef void* (*il2cpp_image_get_class_t)(void* image, size_t index);
typedef const char* (*il2cpp_class_get_name_t)(void* klass);
typedef void* (*il2cpp_class_get_method_from_name_t)(void* klass, const char* name, int argsCount);
typedef void* (*il2cpp_runtime_invoke_t)(void* method, void* obj, void** params, void** exc);
typedef void* (*il2cpp_thread_attach_t)(void* domain);

#define XSF_SYM(name) static name##_t name = (name##_t)dlsym(RTLD_DEFAULT, #name)

namespace sf2 {

struct IL2Cpp {
    il2cpp_domain_get_t domain_get;
    il2cpp_domain_get_assemblies_t domain_get_assemblies;
    il2cpp_assembly_get_image_t assembly_get_image;
    il2cpp_image_get_class_count_t image_get_class_count;
    il2cpp_image_get_class_t image_get_class;
    il2cpp_class_get_name_t class_get_name;
    il2cpp_class_get_method_from_name_t class_get_method_from_name;
    il2cpp_runtime_invoke_t runtime_invoke;
    il2cpp_thread_attach_t thread_attach;
    void* domain = nullptr;
    BOOL ready = NO;
};

inline IL2Cpp &rt() {
    static IL2Cpp r;
    return r;
}

// Resolves every symbol and attaches the calling thread to the il2cpp GC.
// Must succeed before any other function in this file is used. Safe to call
// repeatedly (cheap after the first success).
inline BOOL EnsureReady() {
    IL2Cpp &r = rt();
    if (r.ready) return YES;
    r.domain_get = (il2cpp_domain_get_t)dlsym(RTLD_DEFAULT, "il2cpp_domain_get");
    r.domain_get_assemblies = (il2cpp_domain_get_assemblies_t)dlsym(RTLD_DEFAULT, "il2cpp_domain_get_assemblies");
    r.assembly_get_image = (il2cpp_assembly_get_image_t)dlsym(RTLD_DEFAULT, "il2cpp_assembly_get_image");
    r.image_get_class_count = (il2cpp_image_get_class_count_t)dlsym(RTLD_DEFAULT, "il2cpp_image_get_class_count");
    r.image_get_class = (il2cpp_image_get_class_t)dlsym(RTLD_DEFAULT, "il2cpp_image_get_class");
    r.class_get_name = (il2cpp_class_get_name_t)dlsym(RTLD_DEFAULT, "il2cpp_class_get_name");
    r.class_get_method_from_name = (il2cpp_class_get_method_from_name_t)dlsym(RTLD_DEFAULT, "il2cpp_class_get_method_from_name");
    r.runtime_invoke = (il2cpp_runtime_invoke_t)dlsym(RTLD_DEFAULT, "il2cpp_runtime_invoke");
    r.thread_attach = (il2cpp_thread_attach_t)dlsym(RTLD_DEFAULT, "il2cpp_thread_attach");
    if (!r.domain_get || !r.domain_get_assemblies || !r.assembly_get_image ||
        !r.image_get_class_count || !r.image_get_class || !r.class_get_name ||
        !r.class_get_method_from_name || !r.runtime_invoke) {
        NSLog(@"[SF2Cheats] il2cpp symbols not found — not an il2cpp/Unity process, or UnityFramework not loaded yet.");
        return NO;
    }
    r.domain = r.domain_get();
    if (!r.domain) return NO;
    if (r.thread_attach) r.thread_attach(r.domain); // register this thread with the GC
    r.ready = YES;
    return YES;
}

// Finds a class by its exact (obfuscated) name across every loaded assembly.
// Namespace-agnostic: obfuscated 11-letter names are unique enough that
// matching on class name alone is safe here.
inline void *FindClass(const char *name) {
    IL2Cpp &r = rt();
    if (!EnsureReady()) return nullptr;
    size_t n = 0;
    void **asms = r.domain_get_assemblies(r.domain, &n);
    for (size_t i = 0; i < n; i++) {
        void *img = r.assembly_get_image(asms[i]);
        if (!img) continue;
        size_t cc = r.image_get_class_count(img);
        for (size_t c = 0; c < cc; c++) {
            void *klass = r.image_get_class(img, c);
            if (!klass) continue;
            const char *cn = r.class_get_name(klass);
            if (cn && strcmp(cn, name) == 0) return klass;
        }
    }
    return nullptr;
}

inline void *InvokeNoArg(void *klass, const char *method, void *obj) {
    if (!klass) return nullptr;
    IL2Cpp &r = rt();
    void *m = r.class_get_method_from_name(klass, method, 0);
    if (!m) return nullptr;
    void *exc = nullptr;
    void *ret = r.runtime_invoke(m, obj, nullptr, &exc);
    if (exc) { NSLog(@"[SF2Cheats] exception invoking %s", method); return nullptr; }
    return ret;
}

// ───────────────────────── CONFIG — build-specific names ─────────────────────────
// Everything in this block came from one dump.cs snapshot the user supplied.
// Re-run the class/offset search in dump.cs after every game update.
namespace cfg {
    // Readable, not renamed by Beebyte — comparatively stable across updates.
    static const char *kClsFightHolder   = "FightHolder";
    static const char *kMethodGetCurrent = "get_Current"; // static FightHolder -> FightHolder*
    static const char *kMethodGetFight   = "get_Fight";   // instance FightHolder -> GNEIHFDOCGK* (fight)

    // Obfuscated — WILL break on the next build; re-resolve from a fresh dump.
    static const char *kClsServiceLocator = "KLODPOJOFJC"; // holds static service singletons
    static const char *kMethodGetWallet   = "get_BHEBNPJGODA"; // static -> CKFPDLNKHPM* (wallet)

    // GNEIHFDOCGK (the active Fight object) — fighter slot offsets, dump-confirmed.
    // Semantics (which slot is the player vs the opponent) are UNCONFIRMED.
    static const uint32_t kFightSlotA = 0x98; // field GGLDKALDKDK, NEDPBNINOBB*
    static const uint32_t kFightSlotB = 0xA0; // field JCGCBEJACKL, NEDPBNINOBB*
    static const uint32_t kFightSlotC = 0xA8; // field KBMFPNNLHBH, NEDPBNINOBB*

    // NEDPBNINOBB (a fighter) — CANDIDATE fields. Types/offsets are exact;
    // which is "health" and which is "magic" is NOT confirmed.
    static const uint32_t kFtrBoolA   = 0x5C;  // ObscuredBool  MKPNMHLEHBA
    static const uint32_t kFtrBoolB   = 0x6C;  // ObscuredBool  DIGPIKNDDOA
    static const uint32_t kFtrFloatA  = 0xF4;  // ObscuredFloat OIDNHCJEEBM (get-only property backing — good health-ratio candidate)
    static const uint32_t kFtrIntA    = 0x1F8; // ObscuredInt   DCDNMDGNFGK (private)
    static const uint32_t kFtrFloatB  = 0x208; // ObscuredFloat JGCEMJKGOKA (private)

    // CKFPDLNKHPM (wallet) — four ObscuredLong candidates, in declaration order.
    // KLODPOJOFJC declares currency key strings "Coins","Ruby","RaidCurr","Materials"
    // in that same order, which is a plausible but UNCONFIRMED positional match.
    static const uint32_t kWalletCurrency[4] = { 0x178, 0x198, 0x1B8, 0x1D8 };
    static const char    *kWalletCurrencyLabel[4] = { "Coins?", "Ruby/Gems?", "RaidCurr?", "Materials?" };
    // Which indices the Money tab acts on — change once Diagnostics confirms them.
    static const int kCoinsIndex = 0;
    static const int kGemsIndex  = 1;
}

// ───────────────────────── ACTk Obscured* codec ─────────────────────────
// Struct layout + Decrypt/Encrypt(value,key) semantics read directly out of
// dump.cs's own ObscuredInt/Float/Bool/Long definitions (XOR cipher, key
// stored next to the value). Not guessed.
struct ObsInt   { int32_t key; int32_t hidden; int32_t fake; uint8_t fakeActive; uint8_t inited; };   // size 0x10
struct ObsFloat { int32_t key; int32_t hidden; int32_t oldByte4; float fake; uint8_t fakeActive; uint8_t inited; }; // size 0x14
struct ObsBool  { uint8_t key; int32_t hidden; uint8_t fake; uint8_t inited; uint8_t fakeActive; };    // size ~0xB (padded)
struct ObsLong  { int64_t key; int64_t hidden; int64_t fake; uint8_t fakeActive; uint8_t inited; };    // size 0x1A (padded)

inline int32_t ReadObsInt(void *obj, uint32_t off) {
    auto *o = (ObsInt *)((char *)obj + off);
    return o->hidden ^ o->key;
}
inline void WriteObsInt(void *obj, uint32_t off, int32_t value) {
    auto *o = (ObsInt *)((char *)obj + off);
    o->hidden = value ^ o->key;
}
inline float ReadObsFloat(void *obj, uint32_t off) {
    auto *o = (ObsFloat *)((char *)obj + off);
    int32_t bits = o->hidden ^ o->key;
    float f; memcpy(&f, &bits, 4);
    return f;
}
inline void WriteObsFloat(void *obj, uint32_t off, float value) {
    auto *o = (ObsFloat *)((char *)obj + off);
    int32_t bits; memcpy(&bits, &value, 4);
    o->hidden = bits ^ o->key;
}
inline bool ReadObsBool(void *obj, uint32_t off) {
    auto *o = (ObsBool *)((char *)obj + off);
    return (o->hidden ^ o->key) != 0;
}
inline void WriteObsBool(void *obj, uint32_t off, bool value) {
    auto *o = (ObsBool *)((char *)obj + off);
    o->hidden = (value ? 1 : 0) ^ o->key;
}
inline int64_t ReadObsLong(void *obj, uint32_t off) {
    auto *o = (ObsLong *)((char *)obj + off);
    return o->hidden ^ o->key;
}
inline void WriteObsLong(void *obj, uint32_t off, int64_t value) {
    auto *o = (ObsLong *)((char *)obj + off);
    o->hidden = value ^ o->key;
}

// ───────────────────────── Object resolution ─────────────────────────
inline void *GetWallet() {
    void *loc = FindClass(cfg::kClsServiceLocator);
    if (!loc) return nullptr;
    return InvokeNoArg(loc, cfg::kMethodGetWallet, nullptr); // static getter
}

inline void *GetCurrentFight() {
    void *fhClass = FindClass(cfg::kClsFightHolder);
    if (!fhClass) return nullptr;
    void *holder = InvokeNoArg(fhClass, cfg::kMethodGetCurrent, nullptr); // static -> FightHolder*
    if (!holder) return nullptr;
    return InvokeNoArg(fhClass, cfg::kMethodGetFight, holder); // instance -> GNEIHFDOCGK*
}

inline void *FightSlot(void *fight, uint32_t off) {
    if (!fight) return nullptr;
    return *(void **)((char *)fight + off);
}

// Startup / diagnostic check: which parts of the config actually resolve on
// THIS running build. Call before trusting any toggle; report failures
// precisely instead of silently acting on null pointers.
struct Status {
    BOOL il2cppReady = NO;
    BOOL fightHolderClass = NO;
    BOOL serviceLocatorClass = NO;
    BOOL walletResolved = NO;
    BOOL fightResolved = NO;
};

inline Status Diagnose() {
    Status s;
    s.il2cppReady = EnsureReady();
    if (!s.il2cppReady) return s;
    s.fightHolderClass = FindClass(cfg::kClsFightHolder) != nullptr;
    s.serviceLocatorClass = FindClass(cfg::kClsServiceLocator) != nullptr;
    s.walletResolved = GetWallet() != nullptr;
    s.fightResolved = GetCurrentFight() != nullptr;
    return s;
}

// Builds a human-readable (Russian) snapshot of every candidate value, for
// the in-menu Diagnostics panel. This never writes anything.
inline NSString *DiagnosticsText() {
    if (!EnsureReady())
        return @"il2cpp не найден. Меню не внутри работающего Unity-процесса или UnityFramework ещё не загрузился.";

    NSMutableString *out = [NSMutableString string];

    // Class-level resolution, independent of any getter call — pinpoints
    // whether this is a build/name mismatch (class itself missing) or a
    // method mismatch (class found, getter didn't return an instance).
    void *locClass = FindClass(cfg::kClsServiceLocator);
    void *fhClass   = FindClass(cfg::kClsFightHolder);
    [out appendFormat:@"Класс %s (локатор сервисов): %@\n", cfg::kClsServiceLocator, locClass ? @"найден" : @"НЕ найден"];
    [out appendFormat:@"Класс %s: %@\n", cfg::kClsFightHolder, fhClass ? @"найден" : @"НЕ найден"];
    if (locClass) {
        void *m = rt().class_get_method_from_name(locClass, cfg::kMethodGetWallet, 0);
        [out appendFormat:@"  метод %s: %@\n", cfg::kMethodGetWallet, m ? @"найден" : @"НЕ найден"];
    }
    if (!locClass || !fhClass) {
        [out appendString:@"\n⚠️ Класс не найден — скорее всего dump.cs снят не с этой сборки игры (имена и смещения перегенерируются при каждой обфускации). Нужен новый дамп с ТЕКУЩЕГО UnityFramework.\n\n"];
    }

    void *wallet = GetWallet();
    [out appendFormat:@"Кошелёк (инстанс): %@\n", wallet ? @"найден" : @"НЕ найден"];
    if (wallet) {
        for (int i = 0; i < 4; i++) {
            int64_t v = ReadObsLong(wallet, cfg::kWalletCurrency[i]);
            [out appendFormat:@"  [%d] %s = %lld\n", i, cfg::kWalletCurrencyLabel[i], (long long)v];
        }
    }

    void *fight = GetCurrentFight();
    [out appendFormat:@"Бой: %@\n", fight ? @"идёт" : @"не найден (не в бою?)"];
    if (fight) {
        uint32_t slots[3] = { cfg::kFightSlotA, cfg::kFightSlotB, cfg::kFightSlotC };
        const char *names[3] = { "Slot A (0x98)", "Slot B (0xA0)", "Slot C (0xA8)" };
        for (int i = 0; i < 3; i++) {
            void *f = FightSlot(fight, slots[i]);
            if (!f) { [out appendFormat:@"  %s: null\n", names[i]]; continue; }
            [out appendFormat:@"  %s: boolA=%d boolB=%d floatA=%.3f intA=%d floatB=%.3f\n",
                names[i],
                ReadObsBool(f, cfg::kFtrBoolA),
                ReadObsBool(f, cfg::kFtrBoolB),
                ReadObsFloat(f, cfg::kFtrFloatA),
                ReadObsInt(f, cfg::kFtrIntA),
                ReadObsFloat(f, cfg::kFtrFloatB)];
        }
    }
    return out;
}

// ───────────────────────── Cheat state (polled, no hooking) ─────────────────────────
// No inline hooking is used (no JIT). Every effect below is re-asserted on a
// repeating timer so it "sticks" against the game's own per-frame writes.
struct State {
    BOOL infiniteCoins = NO, infiniteGems = NO, freezeCoins = NO, freezeGems = NO;
    int64_t frozenCoinsValue = 0, frozenGemsValue = 0;
    BOOL godMode = NO, oneHitKill = NO;
    BOOL freezeEnemies = NO;
    dispatch_source_t timer = nil;
};
inline State &state() { static State s; return s; }

static const int64_t kInfiniteAmount = 999999999;

// Which fighter slot is treated as "self" vs "enemy" — best guess (slot A is
// typically populated first/last for the local player in SF2's internal
// fight setup order); NOT confirmed. Flip these two if God Mode instead
// freezes the enemy, based on what Diagnostics shows while you take damage.
inline void *SelfFighter(void *fight) { return FightSlot(fight, cfg::kFightSlotA); }
inline void *EnemyFighter(void *fight) { return FightSlot(fight, cfg::kFightSlotB); }

inline void Tick() {
    if (!EnsureReady()) return;
    State &s = state();

    if (s.infiniteCoins || s.freezeCoins || s.infiniteGems || s.freezeGems) {
        void *w = GetWallet();
        if (w) {
            if (s.infiniteCoins) WriteObsLong(w, cfg::kWalletCurrency[cfg::kCoinsIndex], kInfiniteAmount);
            else if (s.freezeCoins) WriteObsLong(w, cfg::kWalletCurrency[cfg::kCoinsIndex], s.frozenCoinsValue);
            if (s.infiniteGems) WriteObsLong(w, cfg::kWalletCurrency[cfg::kGemsIndex], kInfiniteAmount);
            else if (s.freezeGems) WriteObsLong(w, cfg::kWalletCurrency[cfg::kGemsIndex], s.frozenGemsValue);
        }
    }

    if (s.godMode || s.oneHitKill || s.freezeEnemies) {
        void *fight = GetCurrentFight();
        if (fight) {
            if (s.godMode) {
                void *self = SelfFighter(fight);
                if (self) {
                    WriteObsBool(self, cfg::kFtrBoolA, true);   // candidate "invulnerable" flag
                    WriteObsFloat(self, cfg::kFtrFloatA, 1.0f); // candidate health ratio, pinned to full
                }
            }
            if (s.oneHitKill || s.freezeEnemies) {
                void *enemy = EnemyFighter(fight);
                if (enemy) {
                    if (s.oneHitKill) WriteObsFloat(enemy, cfg::kFtrFloatA, 0.0f); // candidate health ratio -> 0
                    if (s.freezeEnemies) WriteObsBool(enemy, cfg::kFtrBoolB, true); // candidate "stunned/locked" flag
                }
            }
        }
    }
}

inline void EnsureTimer() {
    State &s = state();
    if (s.timer) return;
    dispatch_queue_t q = dispatch_queue_create("sf2.cheats.tick", DISPATCH_QUEUE_SERIAL);
    s.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, q);
    dispatch_source_set_timer(s.timer, dispatch_time(DISPATCH_TIME_NOW, 0), (uint64_t)(1.0 / 15.0 * NSEC_PER_SEC), (uint64_t)(0.01 * NSEC_PER_SEC));
    dispatch_source_set_event_handler(s.timer, ^{ Tick(); });
    dispatch_resume(s.timer);
}

inline void SetInfiniteCoins(BOOL on) { EnsureTimer(); state().infiniteCoins = on; if (on) state().freezeCoins = NO; }
inline void SetInfiniteGems(BOOL on)  { EnsureTimer(); state().infiniteGems = on; if (on) state().freezeGems = NO; }
inline void SetFreezeCoins(BOOL on) {
    EnsureTimer();
    State &s = state();
    if (on) { void *w = GetWallet(); if (w) s.frozenCoinsValue = ReadObsLong(w, cfg::kWalletCurrency[cfg::kCoinsIndex]); s.infiniteCoins = NO; }
    s.freezeCoins = on;
}
inline void SetFreezeGems(BOOL on) {
    EnsureTimer();
    State &s = state();
    if (on) { void *w = GetWallet(); if (w) s.frozenGemsValue = ReadObsLong(w, cfg::kWalletCurrency[cfg::kGemsIndex]); s.infiniteGems = NO; }
    s.freezeGems = on;
}
inline void SetGodMode(BOOL on)      { EnsureTimer(); state().godMode = on; }
inline void SetOneHitKill(BOOL on)   { EnsureTimer(); state().oneHitKill = on; }
inline void SetFreezeEnemies(BOOL on){ EnsureTimer(); state().freezeEnemies = on; }

} // namespace sf2
