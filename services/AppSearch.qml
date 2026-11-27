pragma Singleton

import qs.modules.common.functions
import Quickshell

/**
 * - Eases fuzzy searching for applications by name
 * - Guesses icon name for window class name
 */
Singleton {
    id: root
    property bool sloppySearch: false
    property real scoreThreshold: 0.2
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
    })
    property var regexSubstitutions: [
        {
            "regex": /^steam_app_(\d+)$/,
            "replace": "steam_icon_$1"
        },
        {
            "regex": /Minecraft.*/,
            "replace": "minecraft"
        },
        {
            "regex": /.*polkit.*/,
            "replace": "system-lock-screen"
        },
        {
            "regex": /gcr.prompter/,
            "replace": "system-lock-screen"
        }
    ]

    // Deduped list to fix double icons (first entry per id wins)
    readonly property list<DesktopEntry> list: {
        const seen = new Set();
        const out = [];
        for (const app of DesktopEntries.applications.values) {
            if (seen.has(app.id)) continue;
            seen.add(app.id);
            out.push(app);
        }
        return out;
    }

    // Fuzzy indexes are built lazily on first use and dropped when `list` changes.
    // Lazy fuzzy-index cache. Kept as fields of a plain JS object rather than
    // as properties: guessIcon() runs inside property bindings (the dock's icon
    // `source`), and writing a property from within a binding that also reads
    // it is reported as a binding loop.
    readonly property var _cache: ({
            names: null,
            icons: null,
            startupClasses: null
        })
    onListChanged: {
        _cache.names = null;
        _cache.icons = null;
        _cache.startupClasses = null;
    }

    function getPreppedNames() {
        if (_cache.names === null)
            _cache.names = list.map(a => ({
                name: Fuzzy.prepare(`${a.name} `),
                entry: a
            }));
        return _cache.names;
    }

    function getPreppedIcons() {
        if (_cache.icons === null)
            _cache.icons = list.map(a => ({
                name: Fuzzy.prepare(`${a.icon} `),
                entry: a
            }));
        return _cache.icons;
    }

    function fuzzyQuery(search: string): var { // Idk why list<DesktopEntry> doesn't work
        if (root.sloppySearch) {
            const results = list.map(obj => ({
                entry: obj,
                score: Levendist.computeScore(obj.name.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, getPreppedNames(), {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }

    function iconExists(iconName) {
        if (!iconName || iconName.length == 0) return false;
        return (Quickshell.iconPath(iconName, true).length > 0) 
            && !iconName.includes("image-missing");
    }

    function getReverseDomainNameAppName(str) {
        return str.split('.').slice(-1)[0]
    }

    function getKebabNormalizedAppName(str) {
        return str.toLowerCase().replace(/\s+/g, "-");
    }

    function getUndescoreToKebabAppName(str) {
        return str.toLowerCase().replace(/_/g, "-");
    }

    // Index of desktop entries by StartupWMClass (lowercased), rebuilt when `list` changes.
    // Window classes don't always match the desktop entry id (e.g. class "orca"
    // belongs to "orca-ide.desktop"), and must win over same-named theme icons.
    function getStartupClassIndex() {
        if (_cache.startupClasses === null) {
            const index = {};
            for (const app of list) {
                const cls = (app.startupClass ?? "").toLowerCase();
                if (cls.length > 0 && !(cls in index)) index[cls] = app;
            }
            _cache.startupClasses = index;
        }
        return _cache.startupClasses;
    }

    // Icon declared by the desktop entry matching a window class, or "" if none.
    function entryIconForClass(str) {
        const entry = DesktopEntries.byId(str) ?? getStartupClassIndex()[str.toLowerCase()];
        return entry && entry.icon ? entry.icon : "";
    }

    function guessIcon(str) {
        if (!str || str.length == 0) return "image-missing";

        // Desktop entry (by id or StartupWMClass) -> use the icon it declares
        const declared = entryIconForClass(str);
        if (declared.length > 0) return declared;

        // Normal substitutions
        if (substitutions[str]) return substitutions[str];
        if (substitutions[str.toLowerCase()]) return substitutions[str.toLowerCase()];

        // Regex substitutions
        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(
                substitution.regex,
                substitution.replace,
            );
            if (replacedName != str) return replacedName;
        }

        // Icon exists -> return as is
        if (iconExists(str)) return str;


        // Simple guesses
        const lowercased = str.toLowerCase();
        if (iconExists(lowercased)) return lowercased;

        const reverseDomainNameAppName = getReverseDomainNameAppName(str);
        if (iconExists(reverseDomainNameAppName)) return reverseDomainNameAppName;

        const lowercasedDomainNameAppName = reverseDomainNameAppName.toLowerCase();
        if (iconExists(lowercasedDomainNameAppName)) return lowercasedDomainNameAppName;

        const kebabNormalizedGuess = getKebabNormalizedAppName(str);
        if (iconExists(kebabNormalizedGuess)) return kebabNormalizedGuess;

        const undescoreToKebabGuess = getUndescoreToKebabAppName(str);
        if (iconExists(undescoreToKebabGuess)) return undescoreToKebabGuess;

        // Search in desktop entries
        const iconSearchResults = Fuzzy.go(str, getPreppedIcons(), {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
        if (iconSearchResults.length > 0) {
            const guess = iconSearchResults[0].icon
            if (iconExists(guess)) return guess;
        }

        const nameSearchResults = root.fuzzyQuery(str);
        if (nameSearchResults.length > 0) {
            const guess = nameSearchResults[0].icon
            if (iconExists(guess)) return guess;
        }

        // Quickshell's desktop entry lookup
        const heuristicEntry = DesktopEntries.heuristicLookup(str);
        if (heuristicEntry) return heuristicEntry.icon;

        // Give up
        return "application-x-executable";
    }
}
