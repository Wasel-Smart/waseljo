/**
 * Wasel Mobile App Entry Point
 * @format
 */

import { AppRegistry, I18nManager } from 'react-native';
import { MMKV } from 'react-native-mmkv';

// Apply RTL direction synchronously before the first render so Android lays
// out correctly from the start.  AsyncStorage is async and cannot be read
// here; MMKV is synchronous and is therefore the authoritative store for the
// language preference at startup.  LanguageContext keeps both stores in sync.
const _startupStorage = new MMKV({ id: 'wasel-startup' });
const _startupLang = _startupStorage.getString('wasel-language') ?? 'ar';
const _needsRTL = _startupLang === 'ar';
I18nManager.allowRTL(true);
// Only call forceRTL when the native-side value actually differs; unnecessary
// calls on Android trigger an activity restart loop on some RN versions.
if (I18nManager.isRTL !== _needsRTL) {
  I18nManager.forceRTL(_needsRTL);
}

// Must stay first: wraps StyleSheet.create so every text style uses the brand font.
import './src/styles/installFonts';
import App from './src/App';
import appConfig from './app.json';

AppRegistry.registerComponent(appConfig.expo.name, () => App);
