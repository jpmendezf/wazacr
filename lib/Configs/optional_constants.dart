//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'package:flutter/material.dart';

const Color colorCallbuttons = Color(0xff448AFF);
// applied to call buttons in Video Call & Audio Call .dart pages

const bool deleteMessaqgeForEveryoneDeleteFromServer = true;
//in group chat if delete message for everyone is tapped, It will be the message tile will be deleted from server (if this switch is true) OR if this switch is false, it will show the deleted messase as "Message is deleted"

const int ImageQualityCompress = 50;
// This is compress the chat image size in percent while uploading to firesbase storage

const int DpImageQualityCompress = 34;
// This is compress the user display picture  size in percent while uploading to firesbase storage

const bool IsVideoQualityCompress = true;
// This is compress the video size  to medium qulaity while uploading to firesbase storage

int maxChatMessageDocsLoadAtOnceForGroupChatAndBroadcastLazyLoading = 25;
//Minimum Value should be 15.

int maxAdFailedLoadAttempts = 3;
//Minimum Value should be 3.

const int timeOutSeconds = 50;
// Default phone Auth Code auto retrival timeout

const IsShowNativeTimDate = true;
// Show Date Time in the user selected langauge

const IsShowDeleteChatOption = true;
// Show Delete Chat Button in the All Chats Screens.

const IsRemovePhoneNumberFromCallingPageWhenOnCall = false;
//## under development yet

const OnlyPeerWhoAreSavedInmyContactCanMessageOrCallMe = false;
//If this is true, then only contacts saved in my device can send a message or call me.

const DEFAULT_LANGUAGE_FILE_CODE = 'en';
//default language code if file is present is localization folder example-> en.json

const IsShowLanguageNameInNativeLanguage = false;
// if "true", users can see the language name in respective language

const IsAdaptiveWidthTab = false;
//Automatically adapt the Tab size in tab bar homepage as per the content length. Set it to "true" if your default language code is any of these ["pt", "nl", "vi", "tr", "id", "fr", "es", "ka"]

const IsShowLastMessageInChatTileWithTime = true;
//If true, The "CHATS" screen will show lastmessage time, last message content, unread count in each chat Tile in All Chats page.

const IsShowUserFullNameAsSavedInYourContacts = false;
//Warning: UNDER DEVELOPMENT //If true,All the users /peer name will be show as you have saved in contact. If "false", then the name will be the one which user has saved in his profile.

const IsShowGIFsenderButtonByGIPHY = true;
//If true, GIF sending button will be shown to users in the text input area in chatrooms.

const IsShowSearchTab = true;
//If true, search chat tile name will be shown in homepage. it will search only personal chats name.

final textInSendButton = "";
// If any text is placed here, it will be visible in the send button of text messsages in the Chat room , by default paper_plane icon is theyremoveduasadmin.

const AgoraVideoResultionWIDTH = 1920;
//Agora Video Call Resolution, see details - https://docs.agora.io/en/video-calling/develop/ensure-channel-quality?platform=web

const AgoraVideoResultionHEIGHT = 1080;

const IsHIDELightDarkModeSwitchInApp = false;
//If 'true', the app will not have dark or light mode switch

const IsShowLightDarkModeSwitchInLoginScreen = true;
//If 'true', show change dark mode/light mode switch in login page. It is also visible in settings page.

const IsShowAppLogoInHomepage = false;
//If 'true', show applogo_light.png/applogo_dark.png in the homepage top appbar, and if 'false' shows only the AppLabel text in homepage appbar. If 'true' it is recommended to set the app logo with transparent background.

const IsShowTextLabelsInPhotoVideoEditorPage = true;
//If 'true', text labels like 'trim', 'cover', 'rotate' etc. will be shown at PhotoEditor.dart & VideoEditor.dart

const int MaxTextlettersInStatus = 200;
// maximum characters length while creating text status Status

const int ContactsSearchCountBatchSize = 150;
//while app search for contacts the total number contacts it searches at one batch while looping through all contacts

const IsShowLanguageChangeButtonInLoginAndHome = true;
//If 'true', language change button will be visible at LOGINPAGE & HOMERPAGE

const IsShowLanguageChangeButtonInSettings = true;
//If 'true', shows change language button in settings page, and if 'false' show on homepage appbar.
