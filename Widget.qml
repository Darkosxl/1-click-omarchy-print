import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "darkosxl.printer"

  // file:///.../bin/omarchy-printer -> plain path
  readonly property string script: Qt.resolvedUrl("bin/omarchy-printer").toString().replace("file://", "")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "" // nf-fa-print
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: "Print a PDF"
    onPressed: if (root.bar) root.bar.run("'" + root.script + "'")
  }
}
