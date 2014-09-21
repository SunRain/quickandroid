// Android style Text Input
import QtQuick 2.0
import QuickAndroid 0.1

Item {
    id: component

    property alias text : textInputItem.text

    property alias textInput : textInputItem
    property alias flickable : flickableItem

    // The background of the text input
    property var background
    property alias gravity: gravityBehaviour.gravity
    property var style : ({})

    property alias textSelectHandle: textSelectHandleItem
    property alias _style : styleItem


    Item {
        id : styleItem
        property string background
        property var textStyle
    }

    StateListDrawable {
        id : backgroundItem
        anchors.fill: parent

        source: component.background ? component.background : _style.background

        DrawableGravityBehaviour {
            id : gravityBehaviour
            gravity: "down"
        }

        fillArea.clip : true

        content: Flickable {
            id: flickableItem
            anchors.fill: parent
            implicitWidth: textInputItem.contentWidth
            implicitHeight: textInputItem.contentHeight
            contentWidth: textInputItem.contentWidth
            contentHeight: textInputItem.contentHeight
            flickableDirection : Flickable.HorizontalFlick

            TextInput {
                id : textInputItem
                font.pixelSize: _style.textStyle.textSize * A.dp
                color: _style.textStyle.textColor.color
            }
        }
    }

    Item { // The cursor rectangle
        id : cursorRectangle
        property var rect : component.mapFromItem(textInputItem,
                                                        textInput.cursorRectangle.x,textInput.cursorRectangle.y,
                                                        textInput.cursorRectangle.width,textInput.cursorRectangle.height);
        x: rect.x;y : rect.y; width: rect.width;height: rect.height
    }

    Drawable {
        id: textSelectHandleItem
        parent: component
        width: 100
        height: 100
        source : "#000000"
        opacity: 0.0

        anchors.top: cursorRectangle.bottom
        anchors.horizontalCenter: cursorRectangle.horizontalCenter

        MouseArea {
           anchors.fill: parent
           id : textSelectHandleMouseArea
           drag.target: textSelectHandleItem
           drag.axis: Drag.XAxis
           drag.minimumX: backgroundItem.fillArea.x - textSelectHandleItem.width / 2 - 8 * A.dp
           drag.maximumX: backgroundItem.fillArea.x + backgroundItem.fillArea.width - textSelectHandleItem.width / 2 + 8 * A.dp
        }

        states : [
           State {
               when: textSelectHandleMouseArea.drag.active

               AnchorChanges {
                   target: textSelectHandleItem
                   anchors.top : undefined
                   anchors.horizontalCenter: undefined
               }
           }
        ]
    }

    // Move cursorPosition on dragging
    /*
    Binding { target: textInputItem; property: "cursorPosition"; when: true;
        value: textInputItem.positionAt(textInputItem.mapFromItem(component,
                                        textSelectHandleItem.x + textSelectHandleItem.width / 2,
                                        textSelectHandleItem.y).x ,0); }
    */
    Item { // It don't use Binding as Binding will restore the value
        enabled : !stepBack.running && !stepForward.running && textSelectHandleMouseArea.drag.active
        property int value :  textInputItem.positionAt(textInputItem.mapFromItem(component,
                                                                                 textSelectHandleItem.x + textSelectHandleItem.width / 2,
                                                                                 textSelectHandleItem.y).x ,0);
        onValueChanged: {
            if (!enabled)
                return;
            textInputItem.cursorPosition = value;
        }
    }

    Binding { target: textSelectHandleEntryAnim.item; property : "target" ; value: textSelectHandleItem ; when: true }
    Binding { target: textSelectHandleEntryAnim.item; property : "running" ; value: true ; when: textInput.activeFocus }
    Binding { target: textSelectHandleEntryAnim.item; property : "running" ; value: false ; when: !textInput.activeFocus }

    Binding { target: textSelectHandleExitAnim.item;  property : "target" ; value: textSelectHandleItem ; when: true }
    Binding { target: textSelectHandleExitAnim.item;  property : "running" ; value: true; when: !textInput.activeFocus }
    Binding { target: textSelectHandleExitAnim.item;  property : "running" ; value: false; when: textInput.activeFocus }

    Timer {
        id: stepBack
        repeat: true
        interval : 100
        running: textSelectHandle.x === textSelectHandleMouseArea.drag.minimumX
        onTriggered: {
            if (textInput.cursorPosition !== 0)
                textInput.cursorPosition = textInput.cursorPosition - 1
        }
    }

    Timer {
        id: stepForward
        repeat: true
        interval : 100
        running: textSelectHandle.x === textSelectHandleMouseArea.drag.maximumX
        onTriggered: {
            if (textInput.cursorPosition !== textInput.length - 1)
                textInput.cursorPosition = textInput.cursorPosition + 1
        }
    }

    PropertyAnimation {
        id : cursorVisibleAnimation
        target: flickableItem
        property: "contentX"
        duration: 300
        from: flickableItem.contentX
        to: textInput.cursorRectangle.x < flickableItem.contentX ?
            textInput.cursorRectangle.x :
            textInput.cursorRectangle.x + textInput.cursorRectangle.width

        running: textInput.cursorRectangle.x <  flickableItem.contentX ||
                 textInput.cursorRectangle.x >= flickableItem.contentX + backgroundItem.fillArea.width
    }

    Loader {
        id : textSelectHandleEntryAnim
        asynchronous: true
        source : Res.Style.Animation.TextInput.textSelectHandleEnter
    }

    Loader {
        id : textSelectHandleExitAnim
        asynchronous: true
        source : Res.Style.Animation.TextInput.textSelectHandleExit
    }

    function _updateStyle() {
        Res.copy(_style,Res.Style.Widget.TextInput);
        Res.copy(_style,style);
        _styleChanged();
    }

    Component.onCompleted: _updateStyle();
    onStyleChanged: _updateStyle();
}