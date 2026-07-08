import Quickshell.Io
import QtQuick
import "../common"

// Manages the wallpaper list, thumbnail generation, and wallpaper application
// by shelling out to Python scripts for the scan/thumbnail/query work.
Item {
    id: root

    required property string directory
    required property string cacheDir

    signal wallpaperApplied()

    // Emitted once both the directory scan and the current-wallpaper query
    // (kicked off together by startScan) have settled. index is the
    // currently-applied wallpaper's position in `wallpapers`, or -1 if it
    // couldn't be determined (e.g. not in this directory).
    signal readyForSelection(int index)

    property ListModel wallpapers: ListModel {}

    // Maps wallpaper path -> ListModel index, so thumbnail results can be
    // written directly instead of scanning the list for a match.
    property var pathToIndex: ({})

    property string currentWallpaperPath: ""
    property bool _scanSettled: false
    property bool _querySettled: false

    // Resolves to the absolute filesystem path of the scripts/ directory
    readonly property string scriptDir: decodeURIComponent(Qt.resolvedUrl("scripts/").toString().replace("file://", ""))

    function startScan() {
        // A rescan can be triggered by a rapid close/reopen while the
        // previous scan or thumbnail pass is still running. Skip re-entry
        // rather than racing two Process runs against the same ListModel.
        if (scanProcess.running || thumbProcess.running || queryProcess.running)
            return;
        root._scanSettled = false;
        root._querySettled = false;
        scanProcess.running = true;
        queryProcess.running = true;
    }

    function _settle(kind) {
        // Idempotent per kind: queryProcess can settle from both its stdout
        // stream finishing and its exit (needed when `awww` fails to spawn
        // at all, which may never emit a stream-finished event). Only the
        // first call for a given kind should count.
        if (kind === "scan") {
            if (root._scanSettled)
                return;
            root._scanSettled = true;
        } else {
            if (root._querySettled)
                return;
            root._querySettled = true;
        }
        if (!root._scanSettled || !root._querySettled)
            return;
        const idx = root.pathToIndex[root.currentWallpaperPath];
        root.readyForSelection(idx !== undefined ? idx : -1);
    }

    function applyWallpaper(index) {
        if (index < 0 || index >= root.wallpapers.count)
            return;
        const wp = root.wallpapers.get(index);
        applyProcess.command = ["awww", "img", wp.path];
        applyProcess.running = true;
    }

    Process {
        id: scanProcess

        command: ["python3", root.scriptDir + "scan_wallpapers.py", root.directory]

        stdout: StdioCollector {
            id: scanCollector

            onStreamFinished: {
                let results;
                try {
                    results = JSON.parse(scanCollector.text);
                } catch (e) {
                    console.warn("WallpaperModel: failed to parse scan output:", e, scanCollector.text);
                    root._settle("scan");
                    return;
                }

                root.wallpapers.clear();

                const indexMap = {};
                for (let i = 0; i < results.length; i++) {
                    root.wallpapers.append({
                        path: results[i].path,
                        fileName: results[i].fileName,
                        thumbnailPath: "",
                        animatedThumbnailPath: ""
                    });
                    indexMap[results[i].path] = i;
                }
                root.pathToIndex = indexMap;
                root._settle("scan");

                if (results.length === 0)
                    return;

                thumbProcess.command = ["python3", root.scriptDir + "generate_thumbnails.py", root.cacheDir, String(Appearance.sizing.wallpaper.itemWidth), String(Appearance.sizing.wallpaper.itemHeight)].concat(results.map(r => r.path));
                thumbProcess.running = true;
            }
        }
    }

    // Asks awww which wallpaper is currently displayed, so the picker can
    // open with that item pre-selected instead of always defaulting to the
    // first one.
    Process {
        id: queryProcess

        command: ["awww", "query", "-j"]

        // Settling on the running->false transition (rather than onExited)
        // covers the case where `awww` fails to spawn at all (e.g. not
        // installed): that path never emits `exited` or a stream-finished
        // event, but running still flips to false, so this is the only
        // signal guaranteed to fire and unstick readyForSelection.
        onRunningChanged: if (!running)
            root._settle("query")

        stdout: StdioCollector {
            id: queryCollector

            onStreamFinished: {
                root.currentWallpaperPath = "";
                try {
                    const data = JSON.parse(queryCollector.text);
                    const outputs = Object.values(data)[0] || [];
                    if (outputs.length > 0 && outputs[0].displaying && outputs[0].displaying.image) {
                        root.currentWallpaperPath = outputs[0].displaying.image;
                    }
                } catch (e) {
                    console.warn("WallpaperModel: failed to parse awww query output:", e, queryCollector.text);
                }
                root._settle("query");
            }
        }
    }

    // Reads thumbnail results as they stream in, one JSON line per
    // completed image, rather than waiting for the whole batch to finish.
    Process {
        id: thumbProcess

        stdout: SplitParser {
            onRead: function (line) {
                if (!line.trim())
                    return;
                try {
                    const result = JSON.parse(line);
                    if (!result.thumbnailPath)
                        return;
                    const idx = root.pathToIndex[result.path];
                    if (idx === undefined)
                        return;
                    root.wallpapers.setProperty(idx, "thumbnailPath", "file://" + result.thumbnailPath);
                    if (result.animatedThumbnailPath) {
                        root.wallpapers.setProperty(idx, "animatedThumbnailPath", "file://" + result.animatedThumbnailPath);
                    }
                } catch (_) {}
            }
        }
    }

    // command is set per-call in applyWallpaper() above.
    Process {
        id: applyProcess

        onExited: function (exitCode, exitStatus) {
            if (exitCode === 0)
                root.wallpaperApplied();
        }
    }
}
