/*!
 * Copyright (c) 2012, 2013 Research In Motion Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import bb.cascades 1.2
import bb.system 1.0

NavigationPane {
    id: navPane

    Page {
        Container {
            // The label that is shown if no pushes are available
            Label {
                horizontalAlignment: HorizontalAlignment.Center

                text: qsTr("There are currently no pushes.")
                textStyle {
                    base: SystemDefaults.TextStyles.BodyText
                    fontWeight: FontWeight.Bold
                }

                visible: _pushAPIHandler.modelIsEmpty
            }

            // The list view that displays all available pushes
            ListView {
                dataModel: _pushAPIHandler.model

                listItemComponents: [
                    // The template for header items
                    ListItemComponent {
                        type: "header"

                        CustomHeaderItem {
                            text: Qt.formatDate(ListItemData, "ddd, MMM d, yyyy")
                        }
                    },

                    // The template for normal items
                    ListItemComponent {
                        type: "item"

                        CustomPushItem {
                            type: ListItemData.type
                            extension: ListItemData.extension
                            content: ListItem.view.convertToUtf8String(ListItemData.content);
                            unread: ListItemData.unread
                            pushTime: ListItemData.pushtime
                            selected: ListItem.selected

                            onDeleteClicked: ListItem.view.deletePush(ListItemData);
                        }
                    }
                ]

                function deletePush(pushItem) {
                    _pushAPIHandler.deletePush(pushItem);
                }

                function convertToUtf8String(pushContent){
                    return _pushAPIHandler.convertToUtf8String(pushContent);
                }

                onTriggered: {
                    if (dataModel.itemType(indexPath) == "item") {
                        clearSelection();
                        select(indexPath);

                        // Prepare the controller to display the content of a push
                        _pushAPIHandler.selectPush(indexPath);
                    }
                }
            }
        }

        attachedObjects: [
            // The sheet which contains the configuration controls
            Sheet {
                id: configurationSheet
                objectName: "configurationSheet"
                SheetConfig {
                    id: config
                    onCancel: {
                        // Hide the Sheet.
                        configurationSheet.close();

                        // Refresh the configuration with their last saved values
                        refresh();
                    }
                    onSave: {
                        if (_pushAPIHandler.validateConfiguration()) {
                            // Save the configuration settings
                            _pushAPIHandler.saveConfiguration();

                            // Hide the sheet.
                            configurationSheet.close();

                            // Refresh the configuration with their last saved values
                            refresh();
                        }
                    }
                }
            },

            // The dialog which is shown to notify the user about the status of an operation
            SystemDialog {
                id: notificationDialog

                confirmButton.label: qsTr("OK")

                // Hide the cancel button by assigning a QString::null object
                cancelButton.label: objectName

                title: _pushAPIHandler.notificationTitle
                body: _pushAPIHandler.notificationBody
            },
            
            // The dialog which is shown to notify the user about the status of an operation
            SystemToast {
                id: notificationToast
                body: _pushAPIHandler.notificationToastBody
            },
            
             // The dialog which is shown during a time consuming operation
            SystemProgressDialog {
                id: progressDialog

                confirmButton.enabled: false

                // Hide the cancel button by assigning a QString::null object
                cancelButton.label: objectName
                
                title: _pushAPIHandler.progressDialogTitle
                body: _pushAPIHandler.progressDialogBody
            }
        ]

        function displayContent() {
            // Push the PushContentPage on the navigation pane
            navPane.push(pushContentPage);
        }

        onCreationCompleted: {
            _pushAPIHandler.notificationChanged.connect(notificationDialog.exec)
            _pushAPIHandler.notificationToastChanged.connect(notificationToast.show)
            _pushAPIHandler.openProgressDialog.connect(progressDialog.show)
            _pushAPIHandler.closeProgressDialog.connect(progressDialog.cancel)      

            // The pushContentChanged signal is only emitted when a push is selected from the list,
            // or a notification is selected in the BlackBerry Hub. Connecting this signal to the
            // displayContent method causes the push contents to be displayed whenever this signal is emitted.
            _pushAPIHandler.currentPushContent.pushContentChanged.connect(displayContent)
        }

        // The action objects to trigger various operations
        actions: [
            ActionItem {
                title: qsTr("Config")
                ActionBar.placement: ActionBarPlacement.OnBar
                imageSource: "asset:///images/actionbar/configicon.png"
                onTriggered: {
                    configurationSheet.open();
                }
            },
            ActionItem {
                title: qsTr("Register")
                ActionBar.placement: ActionBarPlacement.OnBar
                imageSource: "asset:///images/actionbar/registericon.png"
                onTriggered: {
                    _pushAPIHandler.createChannel();
                }
            },
            ActionItem {
                title: qsTr("Unregister")
                ActionBar.placement: ActionBarPlacement.OnBar
                imageSource: "asset:///images/actionbar/unregistericon.png"
                onTriggered: {
                    _pushAPIHandler.destroyChannel();
                }
            },
            ActionItem {
                title: qsTr("Mark All Read")
                imageSource: "asset:///images/actionbar/markallicon.png"
                enabled: !_pushAPIHandler.modelIsEmpty
                onTriggered: {
                    _pushAPIHandler.markAllPushesAsRead();
                }
            },
            ActionItem {
                title: qsTr("Delete All")
                ActionBar.placement: ActionBarPlacement.OnBar
                imageSource: "asset:///images/actionbar/deleteallicon.png"
                enabled: !_pushAPIHandler.modelIsEmpty
                onTriggered: {
                    _pushAPIHandler.deleteAllPushes();
                }
            }
        ]
    }

    attachedObjects: [
        // The page to show the content of a push object
        Page {
            id: pushContentPage

            PushContent {
            }

            paneProperties: NavigationPaneProperties {
                backButton: ActionItem {
                    title: qsTr("Back")
                    onTriggered: {
                        navPane.pop();
                    }
                }
            }
        }
    ]
}
