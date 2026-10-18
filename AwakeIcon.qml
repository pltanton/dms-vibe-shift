import QtQuick
import QtQuick.Shapes

// Drawn as vector shapes: DankSVGIcon rasterizes and recolors through an effect layer, which blurs at bar size.
Item {
    id: icon

    property string style: "eyes"
    property bool awake: false
    property color color: "white"
    property real size: 24

    implicitWidth: size
    implicitHeight: size

    function circle(x, y, r) {
        return `M${x - r} ${y} a${r} ${r} 0 1 0 ${2 * r} 0 a${r} ${r} 0 1 0 ${-2 * r} 0`;
    }

    readonly property var glyphs: {
        const brows = "M3.5 8 Q7 5.6 11 8.3 M20.5 8 Q17 5.6 13 8.3 M11 17 L12 18.6 L13 17";
        const laptop = "M5.8 4.5 H18.2 Q20 4.5 20 6.3 V14.2 Q20 16 18.2 16 H5.8 Q4 16 4 14.2 V6.3 Q4 4.5 5.8 4.5 Z M2 19.5 H22";
        return {
            "eyes": {
                "on": [brows + " " + circle(7.5, 12.6, 3.8) + " " + circle(16.5, 12.6, 3.8), circle(7.5, 12.6, 1.5) + " " + circle(16.5, 12.6, 1.5)],
                "off": [brows + " M4.6 13.6 Q7.5 16.2 10.4 13.6 M13.6 13.6 Q16.5 16.2 19.4 13.6", ""]
            },
            "eye": {
                "on": ["M2 12 Q12 3.6 22 12 Q12 20.4 2 12 Z " + circle(12, 12, 3.2), circle(12, 12, 1.2)],
                "off": ["M2.5 10.5 Q12 18.4 21.5 10.5 M6 14.2 L4.6 16.6 M12 15.9 V18.6 M18 14.2 L19.4 16.6", ""]
            },
            "laptop": {
                "on": [laptop + " M7.4 10.2 Q12 6.2 16.6 10.2 Q12 14.2 7.4 10.2 Z", circle(12, 10.2, 1.4)],
                "off": [laptop + " M7.8 9.4 Q12 13.2 16.2 9.4", ""]
            }
        };
    }
    readonly property var glyph: (glyphs[style] ?? glyphs["eyes"])[awake ? "on" : "off"]

    Shape {
        width: 24
        height: 24
        scale: icon.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: icon.color
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: icon.glyph[0]
            }
        }

        ShapePath {
            strokeColor: "transparent"
            fillColor: icon.color

            PathSvg {
                path: icon.glyph[1]
            }
        }
    }
}
