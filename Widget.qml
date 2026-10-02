import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "darkosxl.printer"
  ipcTarget: "darkosxl.printer"

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string binDir: Qt.resolvedUrl("bin/").toString().replace("file://", "")

  property var printers: []        // [{name, state, isDefault}]
  property var recentFiles: []     // [path]
  property string selectedPrinter: ""
  property string selectedFile: ""
  property string status: ""
  property bool statusError: false
  property bool cursorActive: false

  readonly property bool canPrint: selectedPrinter !== "" && selectedFile !== "" && !printProc.running

  function pretty(name) { return String(name).replace(/_/g, " ") }
  function baseName(path) { return String(path).split("/").pop() }

  function refresh() {
    if (!listProc.running) listProc.running = true
    if (!recentProc.running) recentProc.running = true
  }

  function applyPrinters(text) {
    var out = []
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      if (lines[i] === "") continue
      var f = lines[i].split("\t")
      out.push({ name: f[0], state: f[1] || "unknown", isDefault: f[2] === "1" })
    }
    printers = out
    var known = false
    for (var j = 0; j < out.length; j++) if (out[j].name === selectedPrinter) known = true
    if (!known) {
      selectedPrinter = ""
      for (var k = 0; k < out.length; k++) if (out[k].isDefault) selectedPrinter = out[k].name
    }
  }

  function applyRecent(text) {
    var out = String(text || "").split("\n").filter(function(l) { return l !== "" })
    recentFiles = out
    if (selectedFile === "" && out.length > 0) selectedFile = out[0]
  }

  function printNow() {
    if (!canPrint) return
    status = "Sending…"
    statusError = false
    printProc.command = ["lp", "-d", selectedPrinter, "-t", baseName(selectedFile), "--", selectedFile]
    printProc.running = true
  }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    cursorActive = false
    status = ""
    refresh()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  Timer {
    interval: 15000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: listProc
    command: [root.binDir + "omarchy-printer-list"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyPrinters(text) }
  }

  Process {
    id: recentProc
    command: [root.binDir + "omarchy-printer-recent"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyRecent(text) }
  }

  Process {
    id: browseProc
    command: [root.binDir + "omarchy-printer-browse"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var p = String(text || "").trim()
        if (p !== "") root.selectedFile = p
      }
    }
  }

  Process {
    id: printProc
    stdout: StdioCollector { id: printOut; waitForEnd: true }
    stderr: StdioCollector { id: printErr; waitForEnd: true }
    onExited: function(exitCode) {
      root.statusError = exitCode !== 0
      root.status = exitCode === 0
        ? "Sent to " + root.pretty(root.selectedPrinter)
        : (String(printErr.text).trim() || "Print failed")
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "" // nf-fa-print
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: "Print a PDF"
    onPressed: root.toggle()
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(640))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: root.printNow()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) { if (t === "r" || t === "R") root.refresh() }

      Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: flick.width
          spacing: Style.space(12)

          PanelHero {
            width: parent.width
            title: "Print"
            meta: root.printers.length + (root.printers.length === 1 ? " printer" : " printers")
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconComponent: Component {
              Text {
                text: ""
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }
          }

          PanelSeparator { foreground: root.foreground }

          // ---------- Printers ----------
          Column {
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              width: parent.width
              text: "PRINTERS"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Text {
              visible: root.printers.length === 0
              width: parent.width
              text: "No printers found.\nCheck that cups and avahi-daemon are running."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Repeater {
              model: root.printers

              Button {
                required property var modelData
                width: parent.width
                text: root.pretty(modelData.name) + (modelData.isDefault ? "  ★" : "")
                leftAlign: true
                bordered: true
                selected: modelData.name === root.selectedPrinter
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                verticalPadding: Style.spacing.controlPaddingY
                onClicked: root.selectedPrinter = modelData.name

                Text {
                  anchors.right: parent.right
                  anchors.rightMargin: Style.space(10)
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.state
                  color: modelData.state === "disabled" ? root.urgent : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }

          PanelSeparator { foreground: root.foreground }

          // ---------- Document ----------
          Column {
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              width: parent.width
              text: "DOCUMENT"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.recentFiles

              Button {
                required property string modelData
                width: parent.width
                text: root.baseName(modelData)
                leftAlign: true
                bordered: true
                selected: modelData === root.selectedFile
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                verticalPadding: Style.spacing.controlPaddingY
                onClicked: root.selectedFile = modelData
              }
            }

            // A file picked via Browse that isn't in the recent list.
            Button {
              visible: root.selectedFile !== "" && root.recentFiles.indexOf(root.selectedFile) < 0
              width: parent.width
              text: root.baseName(root.selectedFile)
              leftAlign: true
              bordered: true
              selected: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.spacing.controlPaddingY
            }

            Button {
              width: parent.width
              text: "Browse…"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.spacing.controlPaddingY
              onClicked: if (!browseProc.running) browseProc.running = true
            }
          }

          PanelSeparator { foreground: root.foreground }

          Button {
            width: parent.width
            text: printProc.running ? "Sending…" : "Print"
            bordered: true
            selected: root.canPrint
            enabled: root.canPrint
            opacity: root.canPrint ? 1 : 0.5
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.body
            verticalPadding: Style.spacing.controlPaddingY
            onClicked: root.printNow()
          }

          Text {
            visible: text !== ""
            width: parent.width
            text: root.status
            color: root.statusError ? root.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }
}
